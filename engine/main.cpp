#include "Lexer.hpp"
#include "Parser.hpp"
#include "Evaluator.hpp"
#include <iostream>
#include <unordered_map>
#include <string>
#include <vector>
#include <algorithm>
#include <cctype>

// 가상 가계부 Context 구현체
class InteractiveContext : public Formula::IContext {
public:
    InteractiveContext() {
        // 식비 및 지출 데이터 기본 샘플
        data_["A1"] = 100.0; data_["A2"] = 200.0; data_["A3"] = 300.0; data_["A4"] = 400.0; data_["A5"] = 500.0;
        data_["B1"] = 10.55; data_["B2"] = 20.44; data_["B3"] = 30.33; data_["B4"] = 40.22; data_["B5"] = 50.11;
        data_["E1"] = Formula::ErrorType::DivisionByZero;
    }

    void set_cell_value(const std::string& name, double val) {
        std::string key = name;
        std::transform(key.begin(), key.end(), key.begin(), ::toupper);
        data_[key] = val;
    }

    Formula::Value get_cell_value(const std::string& cell_name) const override {
        std::string key = cell_name;
        std::transform(key.begin(), key.end(), key.begin(), ::toupper);

        auto it = data_.find(key);
        if (it != data_.end()) {
            return it->second;
        }
        return Formula::ErrorType::NullReference;
    }

    Formula::RangeValue get_range_values(const std::string& start_cell, const std::string& end_cell) const override {
        Formula::RangeValue result;
        std::string start_key = start_cell;
        std::string end_key = end_cell;
        std::transform(start_key.begin(), start_key.end(), start_key.begin(), ::toupper);
        std::transform(end_key.begin(), end_key.end(), end_key.begin(), ::toupper);

        if (start_key.length() >= 2 && end_key.length() >= 2) {
            char start_col = start_key[0];
            int start_row = std::stoi(start_key.substr(1));
            char end_col = end_key[0];
            int end_row = std::stoi(end_key.substr(1));

            for (int r = start_row; r <= end_row; ++r) {
                std::vector<Formula::Value> row;
                for (char c = start_col; c <= end_col; ++c) {
                    std::string cell_id = std::string(1, c) + std::to_string(r);
                    row.push_back(get_cell_value(cell_id));
                }
                result.push_back(row);
            }
        }
        return result;
    }

    void print_cells() const {
        std::cout << "--- 현재 기본 셀 데이터 ---\n";
        for (const auto& [key, val] : data_) {
            if (std::holds_alternative<double>(val)) {
                std::cout << "  " << key << " = " << std::get<double>(val) << "\n";
            }
        }
        std::cout << "---------------------------\n";
    }

private:
    std::unordered_map<std::string, Formula::Value> data_;
};

// Value 출력용 함수
void print_value(const Formula::Value& val) {
    std::visit([](auto&& arg) {
        using T = std::decay_t<decltype(arg)>;
        if constexpr (std::is_same_v<T, double>) {
            std::cout << "Number: " << arg;
        } else if constexpr (std::is_same_v<T, std::string>) {
            std::cout << "String: \"" << arg << "\"";
        } else if constexpr (std::is_same_v<T, bool>) {
            std::cout << "Boolean: " << (arg ? "TRUE" : "FALSE");
        } else if constexpr (std::is_same_v<T, Formula::ErrorType>) {
            std::cout << "Error: ";
            switch (arg) {
                case Formula::ErrorType::DivisionByZero: std::cout << "#DIV/0!"; break;
                case Formula::ErrorType::InvalidName:    std::cout << "#NAME?"; break;
                case Formula::ErrorType::ValueError:     std::cout << "#VALUE!"; break;
                case Formula::ErrorType::NullReference:  std::cout << "#REF!"; break;
            }
        }
    }, val);
}

void evaluate_expression(const InteractiveContext& context, const std::string& expression) {
    try {
        Formula::Lexer lexer(expression);
        Formula::Parser parser(lexer);
        std::unique_ptr<Formula::ASTNode> ast = parser.parse();
        Formula::Evaluator evaluator(context);
        Formula::Value result = evaluator.evaluate(ast.get());
        std::cout << "Result => ";
        print_value(result);
        std::cout << "\n";
    } catch (const std::exception& ex) {
        std::cout << "Error  => " << ex.what() << "\n";
    }
}

int main(int argc, char* argv[]) {
    InteractiveContext context;

    std::cout << "=========================================================\n";
    std::cout << "     가계부 수식 엔진 대화형 테스트 대시보드 (REPL)      \n";
    std::cout << "=========================================================\n";
    std::cout << " 사용법:\n";
    std::cout << "  - 임의 수식 입력: SUM(10, 20, 30), AVERAGE(A1:A5), IF(A1 > 50, \"합격\", \"불합격\")\n";
    std::cout << "  - 셀 값 변경: A1 = 500\n";
    std::cout << "  - 셀 상태 보기: cells\n";
    std::cout << "  - 종료: exit 또는 quit\n";
    std::cout << "=========================================================\n\n";

    context.print_cells();
    std::cout << "\n수식을 입력하세요.\n";

    std::string line;
    while (true) {
        std::cout << "Formula > ";
        if (!std::getline(std::cin, line)) break;

        // 공백 제거
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        line.erase(line.find_last_not_of(" \t\r\n") + 1);

        if (line.empty()) continue;
        if (line == "exit" || line == "quit") {
            std::cout << "테스트를 종료합니다.\n";
            break;
        }
        if (line == "cells") {
            context.print_cells();
            continue;
        }

        // 셀 할당 구문 처리 (예: A1 = 500)
        auto eq_pos = line.find('=');
        if (eq_pos != std::string::npos && line.find_first_of("()<>,") == std::string::npos) {
            std::string cell_name = line.substr(0, eq_pos);
            std::string val_str = line.substr(eq_pos + 1);
            cell_name.erase(0, cell_name.find_first_not_of(" \t"));
            cell_name.erase(cell_name.find_last_not_of(" \t") + 1);
            val_str.erase(0, val_str.find_first_not_of(" \t"));
            val_str.erase(val_str.find_last_not_of(" \t") + 1);

            try {
                double val = std::stod(val_str);
                context.set_cell_value(cell_name, val);
                std::cout << "셀 설정 완료: " << cell_name << " = " << val << "\n";
                continue;
            } catch (...) {
                // 단순 수식 비교 '=' 일 경우 통과
            }
        }

        evaluate_expression(context, line);
    }

    return 0;
}