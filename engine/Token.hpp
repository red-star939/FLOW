#pragma once
#include <string>
#include <string_view>

namespace Formula {

enum class TokenType {
    // 리터럴 및 식별자
    Number,         // 100, 45.67
    String,         // "식비", "월급"
    Identifier,     // A1, B2, SUM, AVERAGE

    // 산술 연산자
    Plus,           // +
    Minus,          // -
    Asterisk,       // *
    Slash,          // /
	Percent,		// %
    Caret,          // ^

    // 비교 연산자 (비활성화)
    /*
    Equal,          // =
    NotEqual,       // <> 또는 !=
    LessThan,       // <
    LessEqual,      // <=
    GreaterThan,    // >
    GreaterEqual,   // >=
    */

    // 구분자 및 특수 기호
    LParen,         // (
    RParen,         // )
    Comma,          // ,
    Colon,          // :

    // 제어 토큰
    Eof,            // 수식 끝
    Invalid         // 에러 토큰
};

struct Token {
    TokenType type{TokenType::Invalid};
    std::string_view lexeme{};
    size_t position{0};
	size_t line{1};
	size_t column{1};

    [[nodiscard]] constexpr bool is(TokenType expected_type) const noexcept {
        return type == expected_type;
    }
	[[nodiscard]]std::string to_string() const;
};

} // namespace Formula