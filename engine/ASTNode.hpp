#pragma once

#include "Token.hpp"
#include <memory>
#include <string>
#include <vector>

namespace Formula {

enum class ASTNodeType{
    NumberLiteral,
    StringLiteral,
    CellReference,
    RangeReference,
    UnaryOp,
    BinaryOp,
    FunctionCall
};

class ASTNode{
public:
    virtual ~ASTNode() = default;
    [[nodiscard]] virtual ASTNodeType type() const noexcept = 0;
};

// 리터럴 노드 (숫자 및 첵스트)
class NumberNode : public ASTNode {
public:
    double value;
    explicit NumberNode(double val) : value(val) {}
    ASTNodeType type() const noexcept override { return ASTNodeType::NumberLiteral; }
};

class StringNode : public ASTNode {
public:
    std::string value;
    explicit StringNode(std::string val) : value(std::move(val)) {}
    ASTNodeType type() const noexcept override { return ASTNodeType::StringLiteral; }
};

// 셀 및 범위 노드
class CellNode : public ASTNode {
public:
    std::string name;   // ex) A1
    explicit CellNode(std::string cell_name) : name(std::move(cell_name)) {}
    ASTNodeType type() const noexcept override { return ASTNodeType::CellReference; }
};

class RangeNode : public ASTNode {
public:
    std::string start_cell; // ex) A1
    std::string end_cell;   // ex) B5
    RangeNode(std::string start, std::string end)
        : start_cell(std::move(start)), end_cell(std::move(end)){}
    ASTNodeType type() const noexcept override { return ASTNodeType::RangeReference; }
};

// 연산자 노드
class UnaryOpNode : public ASTNode {
public:
    TokenType op;
    std::unique_ptr<ASTNode> operand;
    UnaryOpNode(TokenType op_type, std::unique_ptr<ASTNode> expr)
        : op(op_type), operand(std::move(expr)){}
    ASTNodeType type() const noexcept override { return ASTNodeType::UnaryOp; }
};

class BinaryOpNode : public ASTNode {
public:
    TokenType op;
    std::unique_ptr<ASTNode> left;
    std::unique_ptr<ASTNode> right;
    BinaryOpNode(TokenType op_type, std::unique_ptr<ASTNode> l, std::unique_ptr<ASTNode> r)
        : op(op_type), left(std::move(l)), right(std::move(r)){}
    ASTNodeType type() const noexcept override { return ASTNodeType::BinaryOp; }
};

// 함수 호출 노드
class FunctionCallNode : public ASTNode {
public:
    std::string name; // ex) SUM
    std::vector<std::unique_ptr<ASTNode>> arguments;
    FunctionCallNode(std::string func_name, std::vector<std::unique_ptr<ASTNode>> args)
        : name(std::move(func_name)), arguments(std::move(args)){}
    ASTNodeType type() const noexcept override { return ASTNodeType::FunctionCall;}
};

} // namespace Formula