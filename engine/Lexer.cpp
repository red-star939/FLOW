#include "Lexer.hpp"
#include <cctype>
#include <algorithm>

namespace {

bool is_digit(char c) {
    return std::isdigit(static_cast<unsigned char>(c));
}

bool is_alpha(char c) {
    unsigned char uc = static_cast<unsigned char>(c);
    return std::isalpha(uc) || uc >= 0x80;
}

bool is_alnum(char c) {
    unsigned char uc = static_cast<unsigned char>(c);
    return std::isalnum(uc) || uc >= 0x80;
}

} // namespace

namespace Formula {

Lexer::Lexer(std::string_view source) noexcept
    : source_(source), cursor_(0), line_(1), column_(1), token_start_line_(1), token_start_column_(1) {}

bool Lexer::is_at_end() const noexcept {
    return cursor_ >= source_.length();
}

bool Lexer::match(char expected) {
    if (is_at_end()) return false;
    if (peek() != expected) return false;
    advance();
    return true;
}

char Lexer::peek() const noexcept {
    if (is_at_end()) return '\0';
    return source_[cursor_];
}

char Lexer::peek_next() const noexcept {
    if (cursor_ + 1 >= source_.length()) return '\0';
    return source_[cursor_ + 1];
}

char Lexer::advance() noexcept {
    if (is_at_end()) return '\0';
    char c = source_[cursor_++];
    if (c == '\n') {
        ++line_;
        column_ = 1;
    } else {
        ++column_;
    }
    return c;
}

void Lexer::skip_whitespace() noexcept {
    while (!is_at_end() && std::isspace(static_cast<unsigned char>(peek()))) {
        advance();
    }
}

Token Lexer::make_token(TokenType type, size_t start_pos) const noexcept {
    std::string_view lexeme = source_.substr(start_pos, cursor_ - start_pos);
    return Token{type, lexeme, start_pos, token_start_line_, token_start_column_};
}

Token Lexer::make_error_token(size_t start_pos) const noexcept {
    std::string_view lexeme = source_.substr(start_pos, std::min<size_t>(1, source_.length() - start_pos));
    return Token{TokenType::Invalid, lexeme, start_pos, token_start_line_, token_start_column_};
}

Token Lexer::scan_number(size_t start_pos) {
    advance(); // 첫 번째 숫자 소비
    while (is_digit(peek())) {
        advance();
    }
    if (peek() == '.' && is_digit(peek_next())) {
        advance(); // 소수점('.') 소비
        while (is_digit(peek())) {
            advance();
        }
    }
    return make_token(TokenType::Number, start_pos);
}

Token Lexer::scan_identifier(size_t start_pos) {
    advance(); // 첫 식별자 문법 요소(알파벳/언더스코어) 소비
    while (is_alnum(peek()) || peek() == '_' ||
          (std::isspace(static_cast<unsigned char>(peek())) && (is_alnum(peek_next()) || peek_next() == '_'))) {
        advance();
    }
    size_t end_pos = cursor_;
    while (end_pos > start_pos && std::isspace(static_cast<unsigned char>(source_[end_pos - 1]))) {
        --end_pos;
    }
    return Token{TokenType::Identifier, source_.substr(start_pos, end_pos - start_pos), start_pos, token_start_line_, token_start_column_};
}

Token Lexer::scan_string(size_t start_pos) {
    advance(); // 시작 큰따옴표('"') 소비
    while (!is_at_end() && peek() != '"') {
        advance();
    }
    if (is_at_end()) {
        return make_error_token(start_pos);
    }
    advance(); // 닫는 큰따옴표('"') 소비
    return make_token(TokenType::String, start_pos);
}

Token Lexer::next_token() {
    skip_whitespace();

    if (is_at_end()) {
        return Token{TokenType::Eof, "", cursor_, line_, column_};
    }

    size_t start_pos = cursor_;
    token_start_line_ = line_;
    token_start_column_ = column_;

    char c = peek();

    if (is_digit(c)) {
        return scan_number(start_pos);
    }

    if (is_alpha(c) || c == '_') {
        return scan_identifier(start_pos);
    }

    if (c == '"') {
        return scan_string(start_pos);
    }

    switch (c) {
        case '+': advance(); return make_token(TokenType::Plus, start_pos);
        case '-': advance(); return make_token(TokenType::Minus, start_pos);
        case '*': advance(); return make_token(TokenType::Asterisk, start_pos);
        case '/': advance(); return make_token(TokenType::Slash, start_pos);
        case '%': advance(); return make_token(TokenType::Percent, start_pos);
        case '^': advance(); return make_token(TokenType::Caret, start_pos);
        case '(': advance(); return make_token(TokenType::LParen, start_pos);
        case ')': advance(); return make_token(TokenType::RParen, start_pos);
        case ',': advance(); return make_token(TokenType::Comma, start_pos);
        case ':': advance(); return make_token(TokenType::Colon, start_pos);
        case '=': advance(); return make_token(TokenType::Equal, start_pos);
        case '<':
            advance();
            if (match('>')) return make_token(TokenType::NotEqual, start_pos);
            if (match('=')) return make_token(TokenType::LessEqual, start_pos);
            return make_token(TokenType::LessThan, start_pos);
        case '>':
            advance();
            if (match('=')) return make_token(TokenType::GreaterEqual, start_pos);
            return make_token(TokenType::GreaterThan, start_pos);
        case '!':
            advance();
            if (match('=')) return make_token(TokenType::NotEqual, start_pos);
            return make_error_token(start_pos);
    }

    advance(); // 식별 불가능한 문자의 경우 1글자 소비 후 Invalid 처리
    return make_error_token(start_pos);
}

std::vector<Token> Lexer::tokenize_all() {
    std::vector<Token> tokens;
    while (true) {
        Token tok = next_token();
        tokens.push_back(tok);
        if (tok.type == TokenType::Eof || tok.type == TokenType::Invalid) {
            break;
        }
    }
    return tokens;
}

} // namespace Formula