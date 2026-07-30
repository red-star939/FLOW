#pragma once

#include <string>
#include <vector>
#include <map>
#include <memory>
#include <iostream>
#include "../engine/Evaluator.hpp"

namespace DB {

struct SubItem {
    std::string uuid;   // Secret Unique ID
    std::string sub_id; // SubID 명칭
    double value{0.0};  // SubID 값
};

struct ItemData {
    std::string uuid; // Secret Unique ID
    std::string id;   // ID 명칭
    double total_value{0.0}; // SubID들의 합계값
    std::vector<SubItem> sub_items; // SubID 항목들 (순서 보존)

    void recalculate_total() {
        total_value = 0.0;
        for (const auto& sub : sub_items) {
            total_value += sub.value;
        }
    }
};

struct MonthData {
    int month{0};
    std::vector<ItemData> items; // 월별 ID 항목 영역 (순서 보존)
};

struct MidMonthData {
    int month{0};
    std::string formula; // MID의 해당 월 수식 (예: "수입 - 지출")
    double formula_result{0.0}; // 수식 평가 결과값
};

struct MidData {
    std::string uuid; // Secret Unique ID
    std::string mid;  // MID 명칭 (예: "생활비용")
    std::map<int, MidMonthData> months; // month (1~12) -> MidMonthData
};

struct YearData {
    int year{0};
    std::string description;
    bool is_active{true}; // active 유무
    std::vector<MidData> mids;       // MID 항목 영역 (순서 보존)
    std::map<int, MonthData> months; // month (1~12) -> MonthData (월별 ID 항목 영역)
};

struct DBConfig {
    int start_year{0};
    int end_year{0};
};

class DBManager {
public:
    DBManager() = default;

    // 년도 범위 설정
    bool configure_year_range(int start_year, int end_year);

    // 단일 년도 데이터 설정/추가
    void set_year(int year, const std::string& description = "");

    // 년도별 MID 생성/추가
    bool add_mid(int year, const std::string& mid_name, const std::string& custom_uuid = "");

    // 년도별 MID 제거
    bool remove_mid(int year, const std::string& uuid_or_mid);

    // 년도별 MID 타이틀 변경
    bool update_mid_title(int year, const std::string& uuid_or_mid, const std::string& new_title);

    // 년도별 MID 드래그 재배치
    bool move_mid(int year, int from_index, int to_index);

    // 특정 년도/월에 ID 생성/추가
    bool add_id(int year, int month, const std::string& id_name, const std::string& custom_uuid = "");

    // 특정 년도/월에서 ID 제거
    bool remove_id(int year, int month, const std::string& id_or_uuid);

    // 특정 년도/월의 ID 블록 타이틀 변경
    bool update_id_title(int year, int month, const std::string& uuid_or_id, const std::string& new_title);

    // ID 블록 드래그 재배치
    bool move_id(int year, int month, int from_index, int to_index);

    // 특정 년도/월/ID에 SubID 추가/생성 (자동 합계 계산)
    bool add_subid(int year, int month, const std::string& item_uuid_or_id, const std::string& sub_id_name, double value = 0.0, const std::string& custom_sub_uuid = "");

    // 특정 년도/월/ID에서 SubID 제거 (자동 합계 차감 계산)
    bool remove_subid(int year, int month, const std::string& item_uuid_or_id, const std::string& sub_uuid_or_name);

    // SubID 타이틀 및 금액 수정
    bool update_subid(int year, int month, const std::string& item_uuid_or_id, const std::string& sub_uuid_or_name, const std::string& new_sub_name, double value);

    // SubID 드래그 재배치
    bool move_subid(int year, int month, const std::string& item_uuid_or_id, int from_index, int to_index);

    // MID의 특정 월에 ID 변수들을 참조하는 수식 정의 및 engine/ 수식 엔진 연동 평가 계산
    bool set_formula(int year, const std::string& uuid_or_mid, int month, const std::string& formula_expr);

    // MID의 특정 월 수식 제거
    bool remove_formula(int year, const std::string& uuid_or_mid, int month);

    // 임의 수식 구문을 지정 년도/월의 ID 값들로 engine/ 수식 엔진 연동 평가
    double evaluate_expression(int year, int month, const std::string& expr) const;
    void recalculate_all_formulas_for_month(YearData& ydata, int month);

    // 년도 데이터 반환
    const YearData* get_year(int year) const;
    YearData* get_year(int year);

    // 전체 DB 상태 CMD 출력
    void print_db_status(bool show_all = false) const;

    // JSON 파일 저장/로드
    bool save_to_file(const std::string& filepath = "db/database.json");
    bool load_from_file(const std::string& filepath = "db/database.json");

    // 저장된 모든 활성/전체 년도 목록 반환
    std::vector<int> get_year_list(bool include_inactive = false) const;

    // 설정 정보 반환
    DBConfig get_config() const { return config_; }

private:
    DBConfig config_;
    std::map<int, YearData> years_; // year -> YearData

    void ensure_months_initialized(YearData& ydata);

    // JSON 직렬화/파싱 헬퍼
    std::string serialize_json() const;
    bool deserialize_json(const std::string& json_str);
};

} // namespace DB
