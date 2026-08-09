#include "Parser.hpp"
#include <stdexcept>
#include <string>

namespace Formula {

Parser::Parser(Lexer& lexer) : lexer_(lexer) {
    advance(); // 첫 번째 토큰 읽기
}

Token Parser::advance() {
    Token previous = current_tok_;
    current_tok_ = lexer_.next_token();
    return previous;
}

bool Parser::match(TokenType expected) {
    if (current_tok_.is(expected)) {
        advance();
        return true;
    }
    return false;
}

Token Parser::consume(TokenType expected, const std::string& error_message) {
    if (current_tok_.is(expected)) {
        return advance();
    }
    throw std::runtime_error("Parser Error at pos " + std::to_string(current_tok_.position) + ": " + error_message);
}

std::unique_ptr<ASTNode> Parser::parse() {
    auto ast = parse_expression();
    if (!current_tok_.is(TokenType::Eof)) {
        throw std::runtime_error("Parser Error: Unexpected token at pos " + std::to_string(current_tok_.position));
    }
    return ast;
}

std::unique_ptr<ASTNode> Parser::parse_expression() {
    return parse_comparison();
}

std::unique_ptr<ASTNode> Parser::parse_comparison() {
    auto left = parse_additive();

    while (current_tok_.is(TokenType::Equal) ||
           current_tok_.is(TokenType::NotEqual) ||
           current_tok_.is(TokenType::LessThan) ||
           current_tok_.is(TokenType::LessEqual) ||
           current_tok_.is(TokenType::GreaterThan) ||
           current_tok_.is(TokenType::GreaterEqual)) {
        TokenType op = advance().type;
        auto right = parse_additive();
        left = std::make_unique<BinaryOpNode>(op, std::move(left), std::move(right));
    }

    return left;
}

std::unique_ptr<ASTNode> Parser::parse_additive() {
    auto left = parse_multiplicative();

    while (current_tok_.is(TokenType::Plus) || current_tok_.is(TokenType::Minus)) {
        TokenType op = advance().type;
        auto right = parse_multiplicative();
        left = std::make_unique<BinaryOpNode>(op, std::move(left), std::move(right));
    }

    return left;
}

std::unique_ptr<ASTNode> Parser::parse_multiplicative() {
    auto left = parse_power();

    while (current_tok_.is(TokenType::Asterisk) || current_tok_.is(TokenType::Slash)) {
        TokenType op = advance().type;
        auto right = parse_power();
        left = std::make_unique<BinaryOpNode>(op, std::move(left), std::move(right));
    }

    return left;
}

std::unique_ptr<ASTNode> Parser::parse_power() {
    auto left = parse_unary();

    if (current_tok_.is(TokenType::Caret)) {
        TokenType op = advance().type;
        auto right = parse_power(); // 우측 결합
        left = std::make_unique<BinaryOpNode>(op, std::move(left), std::move(right));
    }

    return left;
}

std::unique_ptr<ASTNode> Parser::parse_unary() {
    if (current_tok_.is(TokenType::Minus) || current_tok_.is(TokenType::Plus)) {
        TokenType op = advance().type;
        auto operand = parse_unary();
        return std::make_unique<UnaryOpNode>(op, std::move(operand));
    }

    return parse_primary();
}

std::unique_ptr<ASTNode> Parser::parse_primary() {
    std::unique_ptr<ASTNode> node;

    // 1. 숫자 리터럴
    if (current_tok_.is(TokenType::Number)) {
        Token tok = advance();
        double val = std::stod(std::string(tok.lexeme));
        node = std::make_unique<NumberNode>(val);
    }

    // 2. 문자열 리터럴
    else if (current_tok_.is(TokenType::String)) {
        Token tok = advance();
        std::string str(tok.lexeme);
        if (str.length() >= 2 && str.front() == '"' && str.back() == '"') {
            str = str.substr(1, str.length() - 2);
        }
        node = std::make_unique<StringNode>(str);
    }

    // 3. 식별자 (함수, 범위, 셀)
    else if (current_tok_.is(TokenType::Identifier)) {
        Token id_tok = advance();
        std::string name(id_tok.lexeme);
        for (char& c : name) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));

        // 함수 호출 처리: Identifier '('
        if (current_tok_.is(TokenType::LParen)) {
            advance();
            std::vector<std::unique_ptr<ASTNode>> args;

            if (!current_tok_.is(TokenType::RParen)) {
                do {
                    args.push_back(parse_expression());
                } while (match(TokenType::Comma));
            }

            consume(TokenType::RParen, "Expected ')' after function arguments.");
            node = std::make_unique<FunctionCallNode>(name, std::move(args));
        }
        // 범위 참조 처리: Cell ':' Cell
        else if (match(TokenType::Colon)) {
            Token end_tok = consume(TokenType::Identifier, "Expected cell identifier after ':' in range.");
            std::string end_name(end_tok.lexeme);
            for (char& c : end_name) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
            node = std::make_unique<RangeNode>(name, end_name);
        }
        else {
            // 단일 셀 참조
            node = std::make_unique<CellNode>(name);
        }
    }

    // 4. 괄호 수식
    else if (match(TokenType::LParen)) {
        auto expr = parse_expression();
        consume(TokenType::RParen, "Expected ')' after expression.");
        node = std::move(expr);
    }

    else {
        throw std::runtime_error("Parser Error at pos " + std::to_string(current_tok_.position) + 
                                 ": Unexpected token '" + std::string(current_tok_.lexeme) + "'");
    }

    // Postfix percent operator (%)
    while (match(TokenType::Percent)) {
        node = std::make_unique<UnaryOpNode>(TokenType::Percent, std::move(node));
    }

    return node;
}

} // namespace Formula