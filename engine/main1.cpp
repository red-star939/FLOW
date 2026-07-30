#include <iostream>
#include <iomanip>
#include "Lexer.hpp"

void print_tokens(const std::string& expression) {
    std::cout << "========================================================\n";
    std::cout << "Target Expression: " << expression << "\n";
    std::cout << "========================================================\n";

    Formula::Lexer lexer(expression);
    auto tokens = lexer.tokenize_all();

    for (const auto& tok : tokens) {
        std::cout << "Type: " << std::setw(2) << static_cast<int>(tok.type)
                  << " | Lexeme: " << std::setw(12) << (tok.lexeme.empty() ? "<EOF>" : tok.lexeme)
                  << " | Pos: " << std::setw(3) << tok.position
                  << " | Line: " << std::setw(2) << tok.line
                  << " | Col: " << std::setw(2) << tok.column << "\n";
    }
    std::cout << "\n";
}

int main() {
    // 1. 산술 연산자 및 퍼센트(%), 함수, 셀 범위 테스트
    print_tokens("SUM(A1:B5) + 120 * 0.15 % 2");

    // 2. 비교 연산자(<>, >=, !=) 및 문자열 리터럴 테스트
    print_tokens("IF(A1 >= 100, \"합격\", \"불합격\")");

    // 3. 다중 문장에서의 줄바꿈 및 위치(line, column) 스캔 테스트
    print_tokens("A1 + \n B2 <> 50");

    return 0;
}