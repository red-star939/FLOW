#pragma once

#include "ASTNode.hpp"
#include "Value.hpp"
#include <functional>
#include <unordered_map>
#include <string>

namespace Formula {

// 셀 데이터를 공급받기 위한 콜백 인터페이스
class IContext {
public:
    virtual ~IContext() = default;
    [[nodiscard]] virtual Value get_cell_value(const std::string& cell_name) const = 0;
    [[nodiscard]] virtual RangeValue get_range_values(const std::string& start_cell, const std::string& end_cell) const = 0;
};

class Evaluator {
public:
    explicit Evaluator(const IContext& context);

    // 트리 평가 실행 함수
    [[nodiscard]] Value evaluate(const ASTNode* node);

private:
    Value visit(const ASTNode* node);
    Value visit_number(const NumberNode* node);
    Value visit_string(const StringNode* node);
    Value visit_cell(const CellNode* node);
    Value visit_range(const RangeNode* node); // 범주는 주로 함수 내부에서 처리됨
    Value visit_unary(const UnaryOpNode* node);
    Value visit_binary(const BinaryOpNode* node);
    Value visit_function(const FunctionCallNode* node);

    // 수식/셀/범위로부터 숫자 수집 및 에러 확인 헬퍼
    Value collect_numeric_values(const std::vector<std::unique_ptr<ASTNode>>& args, std::vector<double>& out_numbers);

    const IContext& context_;
};

} // namespace Formula