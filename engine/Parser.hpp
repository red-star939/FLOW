#pragma once

#include "Lexer.hpp"
#include "ASTNode.hpp"
#include <memory>
#include <string>

namespace Formula{
class Parser{
public:
    explicit Parser(Lexer& lexer);
    
    // 최상위 추상 구문 트리(AST) 생성 Entry Point
    [[nodiscard]] std::unique_ptr<ASTNode> parse();

private:
    // 연산자 우선순위에 따른 재귀 강화 함수군
    std::unique_ptr<ASTNode> parse_expression();
    std::unique_ptr<ASTNode> parse_comparison();
    std::unique_ptr<ASTNode> parse_additive();
    std::unique_ptr<ASTNode> parse_multiplicative();
    std::unique_ptr<ASTNode> parse_power();
    std::unique_ptr<ASTNode> parse_unary();
    std::unique_ptr<ASTNode> parse_primary();

    // 토큰 매칭 및 커서 제어 헬퍼
    Token advance();
    bool match(TokenType expected);
    Token consume(TokenType expected, const std::string& error_message);

    Lexer& lexer_;
    Token current_tok_;
    };
} // namespace Formula