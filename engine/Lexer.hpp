#ifndef LEXER_HPP
#define LEXER_HPP

#include "Token.hpp"
#include <string_view>
#include <vector>

namespace Formula {

class Lexer {
public:
    explicit Lexer(std::string_view source) noexcept;

    [[nodiscard]]Token next_token();
    [[nodiscard]]std::vector<Token> tokenize_all();

private:
    bool is_at_end() const noexcept;
    char peek() const noexcept;
    char peek_next() const noexcept;
    char advance() noexcept;
    bool match(char expected);
    void skip_whitespace() noexcept;

    Token make_token(TokenType type, size_t start_pos) const noexcept;
    Token make_error_token(size_t start_pos) const noexcept;

    Token scan_number(size_t start_pos);
    Token scan_identifier(size_t start_pos);
    Token scan_string(size_t start_pos);

    std::string_view source_;
    size_t cursor_{0};
    size_t line_{1};
    size_t column_{1};
    size_t token_start_line_{1};
    size_t token_start_column_{1};
};

} // namespace Formula

#endif // LEXER_HPP