#include "Evaluator.hpp"
#include <stdexcept>
#include <cmath>
#include <algorithm>
#include <cctype>

namespace Formula {

Evaluator::Evaluator(const IContext& context) : context_(context) {}

Value Evaluator::evaluate(const ASTNode* node) {
    return visit(node);
}

Value Evaluator::visit(const ASTNode* node) {
    if (!node) return 0.0;

    switch (node->type()) {
        case ASTNodeType::NumberLiteral:
            return visit_number(static_cast<const NumberNode*>(node));
        case ASTNodeType::StringLiteral:
            return visit_string(static_cast<const StringNode*>(node));
        case ASTNodeType::CellReference:
            return visit_cell(static_cast<const CellNode*>(node));
        case ASTNodeType::RangeReference:
            return visit_range(static_cast<const RangeNode*>(node));
        case ASTNodeType::UnaryOp:
            return visit_unary(static_cast<const UnaryOpNode*>(node));
        case ASTNodeType::BinaryOp:
            return visit_binary(static_cast<const BinaryOpNode*>(node));
        case ASTNodeType::FunctionCall:
            return visit_function(static_cast<const FunctionCallNode*>(node));
        default:
            throw std::runtime_error("Evaluator Error: Unknown AST node type.");
    }
}

Value Evaluator::visit_number(const NumberNode* node) {
    return node->value;
}

Value Evaluator::visit_string(const StringNode* node) {
    return node->value;
}

Value Evaluator::visit_cell(const CellNode* node) {
    return context_.get_cell_value(node->name);
}

Value Evaluator::visit_range([[maybe_unused]] const RangeNode* node) {
    // 단독 범위 호출 시 스칼라 반환 불가 처리
    return ErrorType::ValueError;
}

Value Evaluator::visit_unary(const UnaryOpNode* node) {
    Value val = visit(node->operand.get());
    if (std::holds_alternative<ErrorType>(val)) {
        return val;
    }
    if (auto pVal = std::get_if<double>(&val)) {
        if (node->op == TokenType::Minus) return -(*pVal);
        if (node->op == TokenType::Plus) return *pVal;
        if (node->op == TokenType::Percent) return *pVal / 100.0;
    }
    return ErrorType::ValueError;
}

Value Evaluator::visit_binary(const BinaryOpNode* node) {
    Value left = visit(node->left.get());
    if (std::holds_alternative<ErrorType>(left)) {
        return left;
    }
    Value right = visit(node->right.get());
    if (std::holds_alternative<ErrorType>(right)) {
        return right;
    }

    if (auto pL = std::get_if<double>(&left)) {
        if (auto pR = std::get_if<double>(&right)) {
            switch (node->op) {
                case TokenType::Plus:         return *pL + *pR;
                case TokenType::Minus:        return *pL - *pR;
                case TokenType::Asterisk:     return *pL * *pR;
                case TokenType::Slash:
                    if (*pR == 0.0) return ErrorType::DivisionByZero;
                    return *pL / *pR;
                case TokenType::Caret:        return std::pow(*pL, *pR);
                case TokenType::Equal:        return *pL == *pR;
                case TokenType::NotEqual:     return *pL != *pR;
                case TokenType::LessThan:     return *pL < *pR;
                case TokenType::LessEqual:    return *pL <= *pR;
                case TokenType::GreaterThan:  return *pL > *pR;
                case TokenType::GreaterEqual: return *pL >= *pR;
                default: break;
            }
        }
    } else if (auto pSL = std::get_if<std::string>(&left)) {
        if (auto pSR = std::get_if<std::string>(&right)) {
            switch (node->op) {
                case TokenType::Equal:    return *pSL == *pSR;
                case TokenType::NotEqual: return *pSL != *pSR;
                default: break;
            }
        }
    } else if (auto pBL = std::get_if<bool>(&left)) {
        if (auto pBR = std::get_if<bool>(&right)) {
            switch (node->op) {
                case TokenType::Equal:    return *pBL == *pBR;
                case TokenType::NotEqual: return *pBL != *pBR;
                default: break;
            }
        }
    }
    return ErrorType::ValueError;
}

Value Evaluator::collect_numeric_values(const std::vector<std::unique_ptr<ASTNode>>& args, std::vector<double>& out_numbers) {
    for (const auto& arg : args) {
        if (arg->type() == ASTNodeType::RangeReference) {
            auto range_node = static_cast<const RangeNode*>(arg.get());
            RangeValue matrix = context_.get_range_values(range_node->start_cell, range_node->end_cell);
            for (const auto& row : matrix) {
                for (const auto& cell_val : row) {
                    if (std::holds_alternative<ErrorType>(cell_val)) {
                        return cell_val;
                    }
                    if (auto pVal = std::get_if<double>(&cell_val)) {
                        out_numbers.push_back(*pVal);
                    }
                }
            }
        } else {
            Value evaluated = visit(arg.get());
            if (std::holds_alternative<ErrorType>(evaluated)) {
                return evaluated;
            }
            if (auto pVal = std::get_if<double>(&evaluated)) {
                out_numbers.push_back(*pVal);
            }
        }
    }
    return 0.0;
}

Value Evaluator::visit_function(const FunctionCallNode* node) {
    std::string func_name = node->name;
    std::transform(func_name.begin(), func_name.end(), func_name.begin(), ::toupper);

    if (func_name == "SUM") {
        std::vector<double> numbers;
        Value err = collect_numeric_values(node->arguments, numbers);
        if (std::holds_alternative<ErrorType>(err)) return err;
        double total = 0.0;
        for (double n : numbers) total += n;
        return total;
    }

    if (func_name == "AVERAGE") {
        std::vector<double> numbers;
        Value err = collect_numeric_values(node->arguments, numbers);
        if (std::holds_alternative<ErrorType>(err)) return err;
        if (numbers.empty()) return ErrorType::DivisionByZero;
        double total = 0.0;
        for (double n : numbers) total += n;
        return total / static_cast<double>(numbers.size());
    }

    if (func_name == "MIN") {
        std::vector<double> numbers;
        Value err = collect_numeric_values(node->arguments, numbers);
        if (std::holds_alternative<ErrorType>(err)) return err;
        if (numbers.empty()) return ErrorType::ValueError;
        double min_val = numbers[0];
        for (size_t i = 1; i < numbers.size(); ++i) {
            if (numbers[i] < min_val) min_val = numbers[i];
        }
        return min_val;
    }

    if (func_name == "MAX") {
        std::vector<double> numbers;
        Value err = collect_numeric_values(node->arguments, numbers);
        if (std::holds_alternative<ErrorType>(err)) return err;
        if (numbers.empty()) return ErrorType::ValueError;
        double max_val = numbers[0];
        for (size_t i = 1; i < numbers.size(); ++i) {
            if (numbers[i] > max_val) max_val = numbers[i];
        }
        return max_val;
    }

    if (func_name == "COUNT") {
        std::vector<double> numbers;
        Value err = collect_numeric_values(node->arguments, numbers);
        if (std::holds_alternative<ErrorType>(err)) return err;
        return static_cast<double>(numbers.size());
    }

    if (func_name == "IF") {
        if (node->arguments.size() < 2 || node->arguments.size() > 3) {
            return ErrorType::ValueError;
        }
        Value cond = visit(node->arguments[0].get());
        if (std::holds_alternative<ErrorType>(cond)) return cond;

        bool is_true = false;
        if (auto pBool = std::get_if<bool>(&cond)) {
            is_true = *pBool;
        } else if (auto pNum = std::get_if<double>(&cond)) {
            is_true = (*pNum != 0.0);
        } else {
            return ErrorType::ValueError;
        }

        if (is_true) {
            return visit(node->arguments[1].get());
        } else {
            if (node->arguments.size() == 3) {
                return visit(node->arguments[2].get());
            }
            return false;
        }
    }

    if (func_name == "ROUND") {
        if (node->arguments.empty() || node->arguments.size() > 2) {
            return ErrorType::ValueError;
        }
        Value val = visit(node->arguments[0].get());
        if (std::holds_alternative<ErrorType>(val)) return val;
        auto pNum = std::get_if<double>(&val);
        if (!pNum) return ErrorType::ValueError;

        double digits = 0.0;
        if (node->arguments.size() == 2) {
            Value dVal = visit(node->arguments[1].get());
            if (std::holds_alternative<ErrorType>(dVal)) return dVal;
            auto pD = std::get_if<double>(&dVal);
            if (!pD) return ErrorType::ValueError;
            digits = *pD;
        }
        double factor = std::pow(10.0, digits);
        return std::round(*pNum * factor) / factor;
    }

    if (func_name == "ABS") {
        if (node->arguments.size() != 1) return ErrorType::ValueError;
        Value val = visit(node->arguments[0].get());
        if (std::holds_alternative<ErrorType>(val)) return val;
        if (auto pNum = std::get_if<double>(&val)) {
            return std::abs(*pNum);
        }
        return ErrorType::ValueError;
    }

    return ErrorType::InvalidName;
}

} // namespace Formula