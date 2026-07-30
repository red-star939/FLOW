#pragma once

#include <variant>
#include <string>
#include <vector>

namespace Formula {

enum class ErrorType{
    DivisionByZero,
    InvalidName,
    ValueError,
    NullReference
};

// 수식의 동적 평가 결과 타입
using Value = std::variant<double, std::string, bool, ErrorType>;

// 셀 범위 조회 결과 타입
using RangeValue = std::vector<std::vector<Value>>;

} // namespace Formula