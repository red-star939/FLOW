#include "DBManager.hpp"
#include "../engine/Lexer.hpp"
#include "../engine/Parser.hpp"
#include "../engine/Evaluator.hpp"
#include <fstream>
#include <sstream>
#include <iomanip>
#include <algorithm>
#include <filesystem>
#include <cctype>
#include <chrono>
#include <random>
#include <QSettings>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QString>

namespace DB {

namespace {
    std::string generate_uuid(const std::string& prefix) {
        auto now = std::chrono::high_resolution_clock::now().time_since_epoch().count();
        static std::mt19937 gen(1337);
        std::uniform_int_distribution<int> dis(1000, 9999);
        std::stringstream ss;
        ss << prefix << "_" << now << "_" << dis(gen);
        return ss.str();
    }

    std::string escape_json_string(const std::string& str) {
        std::ostringstream ss;
        for (char c : str) {
            switch (c) {
                case '"':  ss << "\\\""; break;
                case '\\': ss << "\\\\"; break;
                case '\b': ss << "\\b"; break;
                case '\f': ss << "\\f"; break;
                case '\n': ss << "\\n"; break;
                case '\r': ss << "\\r"; break;
                case '\t': ss << "\\t"; break;
                default:
                    if ('\x00' <= c && c <= '\x1f') {
                        ss << "\\u" << std::hex << std::setw(4) << std::setfill('0') << static_cast<int>(c);
                    } else {
                        ss << c;
                    }
            }
        }
        return ss.str();
    }

    std::string trim(const std::string& s) {
        auto start = s.find_first_not_of(" \t\r\n");
        if (start == std::string::npos) return "";
        auto end = s.find_last_not_of(" \t\r\n");
        return s.substr(start, end - start + 1);
    }

    std::string resolve_path(const std::string& filepath) {
        if (std::filesystem::exists(filepath)) return filepath;
        std::filesystem::path p(filepath);
        if (p.filename() == "database.json") {
            if (std::filesystem::exists("../db/database.json")) return "../db/database.json";
            if (std::filesystem::exists("db/database.json")) return "db/database.json";
            if (std::filesystem::exists("database.json")) return "database.json";
            if (std::filesystem::exists("../../db/database.json")) return "../../db/database.json";
            if (std::filesystem::exists("C:/Users/USER/Desktop/HONG_ST/Flow/db/database.json")) {
                return "C:/Users/USER/Desktop/HONG_ST/Flow/db/database.json";
            }
        }
        return filepath;
    }

    std::string strip_all_spaces_upper(const std::string& str) {
        std::string res;
        for (char c : str) {
            if (!std::isspace(static_cast<unsigned char>(c))) {
                res.push_back(std::toupper(static_cast<unsigned char>(c)));
            }
        }
        return res;
    }

    class DBMonthContext : public Formula::IContext {
    public:
        explicit DBMonthContext(const MonthData& mdata, const YearData* ydata = nullptr, int year = 2026, int month = 1)
            : mdata_(mdata), ydata_(ydata), year_(year), month_(month) {}

        Formula::Value get_cell_value(const std::string& cell_name) const override {
            std::string query_key = strip_all_spaces_upper(cell_name);

            // 1. ID Blocks (ID 블록)
            for (const auto& item : mdata_.items) {
                if (strip_all_spaces_upper(item.id) == query_key) {
                    return item.total_value;
                }
            }

            // 2. SubID Items (ID 블록 내 SubID)
            for (const auto& item : mdata_.items) {
                for (const auto& sub : item.sub_items) {
                    if (strip_all_spaces_upper(sub.sub_id) == query_key) {
                        return sub.value;
                    }
                }
            }

            // 3. MID Blocks (MID 블록: 개별 월 수식 계산 시 해당 월 금액, 전체 월/합계 연산 시 연 총합계)
            if (ydata_) {
                for (const auto& mid : ydata_->mids) {
                    if (strip_all_spaces_upper(mid.mid) == query_key) {
                        if (month_ >= 1 && month_ <= 12) {
                            auto mm_it = mid.months.find(month_);
                            if (mm_it != mid.months.end()) {
                                return mm_it->second.formula_result;
                            }
                            return 0.0;
                        } else {
                            double totalSum = 0.0;
                            for (int m = 1; m <= 12; ++m) {
                                auto mm_it = mid.months.find(m);
                                if (mm_it != mid.months.end()) {
                                    totalSum += mm_it->second.formula_result;
                                }
                            }
                            return totalSum;
                        }
                    }
                }
            }

            // 4. Daily Expenses (당일지출 / 당일 지출)
            if (query_key == strip_all_spaces_upper("당일지출") ||
                query_key == strip_all_spaces_upper("당일 지출") ||
                query_key == "DAILY" || query_key == "DAILYEXPENSES" || query_key == "DAILYEXPENSE") {
                QSettings settings("HONG_ST", "FlowUI");
                double dailyMonthlyTotal = 0.0;
                if (month_ >= 1 && month_ <= 12) {
                    for (int day = 1; day <= 31; ++day) {
                        QString key = QString("DailyExpenses/%1_%2_%3").arg(year_).arg(month_).arg(day);
                        QByteArray dayData = settings.value(key).toByteArray();
                        if (!dayData.isEmpty()) {
                            QJsonDocument doc = QJsonDocument::fromJson(dayData);
                            if (doc.isArray()) {
                                for (const auto& val : doc.array()) {
                                    dailyMonthlyTotal += val.toObject()["value"].toDouble();
                                }
                            }
                        }
                    }
                } else {
                    for (int m = 1; m <= 12; ++m) {
                        for (int day = 1; day <= 31; ++day) {
                            QString key = QString("DailyExpenses/%1_%2_%3").arg(year_).arg(m).arg(day);
                            QByteArray dayData = settings.value(key).toByteArray();
                            if (!dayData.isEmpty()) {
                                QJsonDocument doc = QJsonDocument::fromJson(dayData);
                                if (doc.isArray()) {
                                    for (const auto& val : doc.array()) {
                                        dailyMonthlyTotal += val.toObject()["value"].toDouble();
                                    }
                                }
                            }
                        }
                    }
                }
                return dailyMonthlyTotal;
            }

            return Formula::ErrorType::NullReference;
        }

        Formula::RangeValue get_range_values(const std::string& start_cell, const std::string& end_cell) const override {
            Formula::RangeValue result;
            return result;
        }

    private:
        const MonthData& mdata_;
        const YearData* ydata_;
        int year_;
        int month_;
    };
}

void DBManager::ensure_months_initialized(YearData& ydata) {
    for (int m = 1; m <= 12; ++m) {
        if (ydata.months.find(m) == ydata.months.end()) {
            MonthData mdata;
            mdata.month = m;
            ydata.months[m] = mdata;
        }
    }
}

void DBManager::recalculate_all_formulas_for_month(YearData& ydata, int month) {
    auto mo_it = ydata.months.find(month);
    if (mo_it == ydata.months.end()) return;

    for (auto& mdata : ydata.mids) {
        auto mm_it = mdata.months.find(month);
        if (mm_it != mdata.months.end() && !mm_it->second.formula.empty()) {
            mm_it->second.formula_result = evaluate_expression(ydata.year, month, mm_it->second.formula);
        }
    }
}

bool DBManager::configure_year_range(int start_year, int end_year) {
    if (start_year > end_year) {
        std::cerr << "[DB Error] 시작 년도가 종료 년도보다 클 수 없습니다.\n";
        return false;
    }

    config_.start_year = start_year;
    config_.end_year = end_year;

    for (int yr = start_year; yr <= end_year; ++yr) {
        if (years_.find(yr) == years_.end()) {
            set_year(yr);
        }
    }
    return true;
}

void DBManager::set_year(int year, const std::string& description) {
    auto& ydata = years_[year];
    ydata.year = year;
    ydata.description = description;
    ydata.is_active = true;
    ensure_months_initialized(ydata);
}

bool DBManager::add_mid(int year, const std::string& mid_name, const std::string& custom_uuid) {
    if (mid_name.empty()) return false;

    auto& ydata = years_[year];
    ydata.year = year;
    ydata.is_active = true;
    ensure_months_initialized(ydata);

    MidData mdata;
    mdata.uuid = custom_uuid.empty() ? generate_uuid("mid") : custom_uuid;
    mdata.mid = mid_name;
    for (int m = 1; m <= 12; ++m) {
        MidMonthData mm;
        mm.month = m;
        mdata.months[m] = mm;
    }
    ydata.mids.push_back(mdata);
    return true;
}

bool DBManager::remove_mid(int year, const std::string& uuid_or_mid) {
    auto it = years_.find(year);
    if (it == years_.end()) return false;

    auto& mids = it->second.mids;
    auto m_it = std::remove_if(mids.begin(), mids.end(), [&](const MidData& mdata) {
        return mdata.uuid == uuid_or_mid || mdata.mid == uuid_or_mid;
    });

    if (m_it != mids.end()) {
        mids.erase(m_it, mids.end());
        return true;
    }
    return false;
}

bool DBManager::update_mid_title(int year, const std::string& uuid_or_mid, const std::string& new_title) {
    if (new_title.empty()) return false;
    auto it = years_.find(year);
    if (it == years_.end()) return false;

    for (auto& mdata : it->second.mids) {
        if (mdata.uuid == uuid_or_mid || mdata.mid == uuid_or_mid) {
            mdata.mid = new_title;
            return true;
        }
    }
    return false;
}

bool DBManager::move_mid(int year, int from_index, int to_index) {
    auto it = years_.find(year);
    if (it == years_.end()) return false;

    auto& mids = it->second.mids;
    int size = static_cast<int>(mids.size());
    if (from_index < 0 || from_index >= size || to_index < 0 || to_index >= size || from_index == to_index) {
        return false;
    }

    MidData moved_mid = mids[from_index];
    mids.erase(mids.begin() + from_index);
    mids.insert(mids.begin() + to_index, moved_mid);
    return true;
}

bool DBManager::add_id(int year, int month, const std::string& id_name, const std::string& custom_uuid) {
    if (month < 1 || month > 12) return false;
    if (id_name.empty()) return false;

    auto& ydata = years_[year];
    ydata.year = year;
    ydata.is_active = true;
    ensure_months_initialized(ydata);

    auto& month_data = ydata.months[month];

    ItemData item;
    item.uuid = custom_uuid.empty() ? generate_uuid("id") : custom_uuid;
    item.id = id_name;
    item.total_value = 0.0;

    month_data.items.push_back(item);

    recalculate_all_formulas_for_month(ydata, month);
    return true;
}

bool DBManager::remove_id(int year, int month, const std::string& id_or_uuid) {
    if (month < 1 || month > 12) return false;

    auto y_it = years_.find(year);
    if (y_it == years_.end()) return false;

    auto mo_it = y_it->second.months.find(month);
    if (mo_it == y_it->second.months.end()) return false;

    auto& items = mo_it->second.items;
    auto it = std::remove_if(items.begin(), items.end(), [&](const ItemData& item) {
        return item.uuid == id_or_uuid || item.id == id_or_uuid;
    });

    if (it != items.end()) {
        items.erase(it, items.end());
        recalculate_all_formulas_for_month(y_it->second, month);
        return true;
    }
    return false;
}

bool DBManager::update_id_title(int year, int month, const std::string& uuid_or_id, const std::string& new_title) {
    if (month < 1 || month > 12 || new_title.empty()) return false;

    auto y_it = years_.find(year);
    if (y_it == years_.end()) return false;

    auto mo_it = y_it->second.months.find(month);
    if (mo_it == y_it->second.months.end()) return false;

    for (auto& item : mo_it->second.items) {
        if (item.uuid == uuid_or_id || item.id == uuid_or_id) {
            item.id = new_title;
            recalculate_all_formulas_for_month(y_it->second, month);
            return true;
        }
    }
    return false;
}

bool DBManager::move_id(int year, int month, int from_index, int to_index) {
    if (month < 1 || month > 12) return false;

    auto y_it = years_.find(year);
    if (y_it == years_.end()) return false;

    auto mo_it = y_it->second.months.find(month);
    if (mo_it == y_it->second.months.end()) return false;

    auto& items = mo_it->second.items;
    int size = static_cast<int>(items.size());
    if (from_index < 0 || from_index >= size || to_index < 0 || to_index >= size || from_index == to_index) {
        return false;
    }

    ItemData moved_item = items[from_index];
    items.erase(items.begin() + from_index);
    items.insert(items.begin() + to_index, moved_item);
    return true;
}

bool DBManager::add_subid(int year, int month, const std::string& item_uuid_or_id, const std::string& sub_id_name, double value, const std::string& custom_sub_uuid) {
    if (month < 1 || month > 12 || item_uuid_or_id.empty() || sub_id_name.empty()) return false;

    auto& ydata = years_[year];
    ydata.year = year;
    ydata.is_active = true;
    ensure_months_initialized(ydata);

    auto& month_data = ydata.months[month];

    ItemData* target_item = nullptr;
    for (auto& item : month_data.items) {
        if (item.uuid == item_uuid_or_id || item.id == item_uuid_or_id) {
            target_item = &item;
            break;
        }
    }

    if (!target_item) {
        return false;
    }

    SubItem sub;
    sub.uuid = custom_sub_uuid.empty() ? generate_uuid("sub") : custom_sub_uuid;
    sub.sub_id = sub_id_name;
    sub.value = value;

    target_item->sub_items.push_back(sub);
    target_item->recalculate_total();

    recalculate_all_formulas_for_month(ydata, month);
    return true;
}

bool DBManager::remove_subid(int year, int month, const std::string& item_uuid_or_id, const std::string& sub_uuid_or_name) {
    if (month < 1 || month > 12 || sub_uuid_or_name.empty()) return false;

    auto y_it = years_.find(year);
    if (y_it == years_.end()) return false;

    auto mo_it = y_it->second.months.find(month);
    if (mo_it == y_it->second.months.end()) return false;

    // 1. First try matching parent item by UUID or ID name
    for (auto& item : mo_it->second.items) {
        if (item.uuid == item_uuid_or_id || item.id == item_uuid_or_id) {
            auto& subs = item.sub_items;
            for (auto it = subs.begin(); it != subs.end(); ++it) {
                if (it->uuid == sub_uuid_or_name || it->sub_id == sub_uuid_or_name) {
                    subs.erase(it);
                    item.recalculate_total();
                    recalculate_all_formulas_for_month(y_it->second, month);
                    return true;
                }
            }
        }
    }

    // 2. Fallback: Search across all items in this month for sub_uuid_or_name
    for (auto& item : mo_it->second.items) {
        auto& subs = item.sub_items;
        for (auto it = subs.begin(); it != subs.end(); ++it) {
            if (it->uuid == sub_uuid_or_name || it->sub_id == sub_uuid_or_name) {
                subs.erase(it);
                item.recalculate_total();
                recalculate_all_formulas_for_month(y_it->second, month);
                return true;
            }
        }
    }

    return false;
}

bool DBManager::update_subid(int year, int month, const std::string& item_uuid_or_id, const std::string& sub_uuid_or_name, const std::string& new_sub_name, double value) {
    if (month < 1 || month > 12 || sub_uuid_or_name.empty()) return false;

    auto y_it = years_.find(year);
    if (y_it == years_.end()) return false;

    auto mo_it = y_it->second.months.find(month);
    if (mo_it == y_it->second.months.end()) return false;

    // 1. First try matching parent item by UUID or ID name
    for (auto& item : mo_it->second.items) {
        if (item.uuid == item_uuid_or_id || item.id == item_uuid_or_id) {
            for (auto& sub : item.sub_items) {
                if (sub.uuid == sub_uuid_or_name || sub.sub_id == sub_uuid_or_name) {
                    if (!new_sub_name.empty()) sub.sub_id = new_sub_name;
                    sub.value = value;
                    item.recalculate_total();
                    recalculate_all_formulas_for_month(y_it->second, month);
                    return true;
                }
            }
        }
    }

    // 2. Fallback: Search across all items in this month for sub_uuid_or_name
    for (auto& item : mo_it->second.items) {
        for (auto& sub : item.sub_items) {
            if (sub.uuid == sub_uuid_or_name || sub.sub_id == sub_uuid_or_name) {
                if (!new_sub_name.empty()) sub.sub_id = new_sub_name;
                sub.value = value;
                item.recalculate_total();
                recalculate_all_formulas_for_month(y_it->second, month);
                return true;
            }
        }
    }

    return false;
}

bool DBManager::move_subid(int year, int month, const std::string& item_uuid_or_id, int from_index, int to_index) {
    if (month < 1 || month > 12) return false;

    auto y_it = years_.find(year);
    if (y_it == years_.end()) return false;

    auto mo_it = y_it->second.months.find(month);
    if (mo_it == y_it->second.months.end()) return false;

    for (auto& item : mo_it->second.items) {
        if (item.uuid == item_uuid_or_id || item.id == item_uuid_or_id) {
            auto& subs = item.sub_items;
            int size = static_cast<int>(subs.size());
            if (from_index < 0 || from_index >= size || to_index < 0 || to_index >= size || from_index == to_index) {
                return false;
            }
            SubItem moved_sub = subs[from_index];
            subs.erase(subs.begin() + from_index);
            subs.insert(subs.begin() + to_index, moved_sub);
            return true;
        }
    }
    return false;
}

double DBManager::evaluate_expression(int year, int month, const std::string& expr) const {
    if (expr.empty()) return 0.0;

    const MonthData* target_mdata = nullptr;
    const YearData* ydata_ptr = nullptr;
    auto y_it = years_.find(year);
    if (y_it != years_.end()) {
        ydata_ptr = &y_it->second;
        auto mo_it = y_it->second.months.find(month);
        if (mo_it != y_it->second.months.end()) {
            target_mdata = &mo_it->second;
        }
    }

    MonthData empty_mdata;
    const MonthData& mdata = target_mdata ? *target_mdata : empty_mdata;
    DBMonthContext context(mdata, ydata_ptr, year, month);

    try {
        Formula::Lexer lexer(expr);
        Formula::Parser parser(lexer);
        std::unique_ptr<Formula::ASTNode> ast = parser.parse();
        Formula::Evaluator evaluator(context);
        Formula::Value res = evaluator.evaluate(ast.get());

        if (std::holds_alternative<double>(res)) {
            return std::get<double>(res);
        }
    } catch (...) {}

    return 0.0;
}

bool DBManager::set_formula(int year, const std::string& uuid_or_mid, int month, const std::string& formula_expr) {
    if (month < 1 || month > 12 || uuid_or_mid.empty()) return false;

    auto& ydata = years_[year];
    ydata.year = year;
    ydata.is_active = true;
    ensure_months_initialized(ydata);

    for (auto& mdata : ydata.mids) {
        if (mdata.uuid == uuid_or_mid || mdata.mid == uuid_or_mid) {
            auto& mm_data = mdata.months[month];
            mm_data.formula = formula_expr;
            mm_data.formula_result = evaluate_expression(year, month, formula_expr);
            return true;
        }
    }
    return false;
}

bool DBManager::remove_formula(int year, const std::string& uuid_or_mid, int month) {
    if (month < 1 || month > 12 || uuid_or_mid.empty()) return false;

    auto y_it = years_.find(year);
    if (y_it == years_.end()) return false;

    for (auto& mdata : y_it->second.mids) {
        if (mdata.uuid == uuid_or_mid || mdata.mid == uuid_or_mid) {
            auto mm_it = mdata.months.find(month);
            if (mm_it != mdata.months.end()) {
                mm_it->second.formula.clear();
                mm_it->second.formula_result = 0.0;
                return true;
            }
        }
    }
    return false;
}

const YearData* DBManager::get_year(int year) const {
    auto it = years_.find(year);
    if (it != years_.end()) {
        return &it->second;
    }
    return nullptr;
}

YearData* DBManager::get_year(int year) {
    auto it = years_.find(year);
    if (it != years_.end()) {
        return &it->second;
    }
    return nullptr;
}

std::vector<int> DBManager::get_year_list(bool include_inactive) const {
    std::vector<int> list;
    for (const auto& [yr, ydata] : years_) {
        if (include_inactive || ydata.is_active) {
            list.push_back(yr);
        }
    }
    std::sort(list.begin(), list.end());
    return list;
}

void DBManager::print_db_status(bool show_all) const {
    std::cout << "========== DB Status ==========\n";
    for (const auto& [yr, ydata] : years_) {
        if (!show_all && !ydata.is_active) continue;
        std::cout << "Year: " << yr << "\n";
        for (const auto& [m, mdata] : ydata.months) {
            if (mdata.items.empty()) continue;
            std::cout << "  Month " << m << ":\n";
            for (const auto& item : mdata.items) {
                std::cout << "    ID [" << item.uuid << "] " << item.id << " (Total: " << item.total_value << ")\n";
                for (const auto& sub : item.sub_items) {
                    std::cout << "      SubID [" << sub.uuid << "] " << sub.sub_id << " = " << sub.value << "\n";
                }
            }
        }
    }
    std::cout << "===============================\n";
}

std::string DBManager::serialize_json() const {
    std::ostringstream ss;
    ss << "{\n";
    ss << "  \"config\": {\n";
    ss << "    \"start_year\": " << config_.start_year << ",\n";
    ss << "    \"end_year\": " << config_.end_year << "\n";
    ss << "  },\n";

    ss << "  \"years\": [\n";
    size_t y_count = 0;
    for (const auto& [yr, ydata] : years_) {
        ss << "    {\n";
        ss << "      \"year\": " << yr << ",\n";
        ss << "      \"description\": \"" << escape_json_string(ydata.description) << "\",\n";
        ss << "      \"is_active\": " << (ydata.is_active ? "true" : "false") << ",\n";

        // MIDs
        ss << "      \"mids\": [\n";
        size_t m_count = 0;
        for (const auto& mdata : ydata.mids) {
            ss << "        {\n";
            ss << "          \"uuid\": \"" << escape_json_string(mdata.uuid) << "\",\n";
            ss << "          \"mid\": \"" << escape_json_string(mdata.mid) << "\",\n";
            ss << "          \"months\": [\n";
            for (int m = 1; m <= 12; ++m) {
                auto mm_it = mdata.months.find(m);
                std::string formula = (mm_it != mdata.months.end()) ? mm_it->second.formula : "";
                ss << "            { \"month\": " << m << ", \"formula\": \"" << escape_json_string(formula) << "\" }" << (m < 12 ? "," : "") << "\n";
            }
            ss << "          ]\n";
            ss << "        }" << (++m_count < ydata.mids.size() ? "," : "") << "\n";
        }
        ss << "      ],\n";

        // Months
        ss << "      \"months\": [\n";
        for (int m = 1; m <= 12; ++m) {
            auto mo_it = ydata.months.find(m);
            ss << "        {\n";
            ss << "          \"month\": " << m << ",\n";
            ss << "          \"items\": [\n";
            if (mo_it != ydata.months.end()) {
                size_t i_count = 0;
                for (const auto& item : mo_it->second.items) {
                    ss << "            {\n";
                    ss << "              \"uuid\": \"" << escape_json_string(item.uuid) << "\",\n";
                    ss << "              \"id\": \"" << escape_json_string(item.id) << "\",\n";
                    ss << "              \"total_value\": " << item.total_value << ",\n";
                    ss << "              \"sub_items\": [\n";
                    size_t s_count = 0;
                    for (const auto& sub : item.sub_items) {
                        ss << "                { \"uuid\": \"" << escape_json_string(sub.uuid)
                           << "\", \"sub_id\": \"" << escape_json_string(sub.sub_id)
                           << "\", \"value\": " << sub.value << " }"
                           << (++s_count < item.sub_items.size() ? "," : "") << "\n";
                    }
                    ss << "              ]\n";
                    ss << "            }" << (++i_count < mo_it->second.items.size() ? "," : "") << "\n";
                }
            }
            ss << "          ]\n";
            ss << "        }" << (m < 12 ? "," : "") << "\n";
        }
        ss << "      ]\n";

        ss << "    }" << (++y_count < years_.size() ? "," : "") << "\n";
    }
    ss << "  ]\n";
    ss << "}\n";
    return ss.str();
}

bool DBManager::deserialize_json(const std::string& json_str) {
    years_.clear();

    size_t sy_pos = json_str.find("\"start_year\":");
    if (sy_pos != std::string::npos) {
        size_t sy_end = json_str.find_first_of(",}\n", sy_pos + 13);
        try { config_.start_year = std::stoi(trim(json_str.substr(sy_pos + 13, sy_end - (sy_pos + 13)))); } catch (...) {}
    }

    size_t ey_pos = json_str.find("\"end_year\":");
    if (ey_pos != std::string::npos) {
        size_t ey_end = json_str.find_first_of(",}\n", ey_pos + 11);
        try { config_.end_year = std::stoi(trim(json_str.substr(ey_pos + 11, ey_end - (ey_pos + 11)))); } catch (...) {}
    }

    size_t yr_pos = 0;
    while ((yr_pos = json_str.find("\"year\":", yr_pos)) != std::string::npos) {
        size_t yr_end = json_str.find_first_of(",}\n", yr_pos + 7);
        if (yr_end != std::string::npos) {
            try {
                int yr = std::stoi(trim(json_str.substr(yr_pos + 7, yr_end - (yr_pos + 7))));
                if (yr >= 1900 && yr <= 2999) {
                    YearData ydata;
                    ydata.year = yr;
                    ydata.is_active = true;
                    ensure_months_initialized(ydata);
                    years_[yr] = ydata;
                }
            } catch (...) {}
        }
        yr_pos += 7;
    }

    // Parsing items & MIDs
    size_t yr_label_pos = 0;
    while ((yr_label_pos = json_str.find("\"year\":", yr_label_pos)) != std::string::npos) {
        size_t yr_end = json_str.find_first_of(",}\n", yr_label_pos + 7);
        if (yr_end == std::string::npos) break;
        int yr = 0;
        try { yr = std::stoi(trim(json_str.substr(yr_label_pos + 7, yr_end - (yr_label_pos + 7)))); } catch (...) {}

        if (yr >= 1900 && yr <= 2999 && years_.count(yr)) {
            auto& ydata = years_[yr];

            size_t next_yr = json_str.find("\"year\":", yr_label_pos + 7);
            size_t yr_block_end = (next_yr == std::string::npos) ? json_str.length() : next_yr;

            // MIDs Parsing
            size_t mids_pos = yr_label_pos;
            while ((mids_pos = json_str.find("\"mid\":", mids_pos)) != std::string::npos && mids_pos < yr_block_end) {
                size_t m_start = json_str.find("\"", mids_pos + 6);
                size_t m_end = json_str.find("\"", m_start + 1);
                if (m_start != std::string::npos && m_end != std::string::npos) {
                    std::string mid_id = json_str.substr(m_start + 1, m_end - m_start - 1);
                    std::string mid_uuid;
                    size_t u_pos = json_str.rfind("\"uuid\":", mids_pos);
                    if (u_pos != std::string::npos && u_pos > yr_label_pos && mids_pos - u_pos < 80) {
                        size_t u_start = json_str.find("\"", u_pos + 7);
                        size_t u_end = json_str.find("\"", u_start + 1);
                        if (u_start != std::string::npos && u_end != std::string::npos) {
                            mid_uuid = json_str.substr(u_start + 1, u_end - u_start - 1);
                        }
                    }
                    if (mid_uuid.empty()) mid_uuid = generate_uuid("mid");

                    MidData mdata;
                    mdata.uuid = mid_uuid;
                    mdata.mid = mid_id;
                    for (int m = 1; m <= 12; ++m) {
                        MidMonthData mm;
                        mm.month = m;
                        mdata.months[m] = mm;
                    }

                    size_t next_mid_pos = json_str.find("\"mid\":", mids_pos + 6);
                    size_t mid_block_end = (next_mid_pos == std::string::npos || next_mid_pos > yr_block_end) ? yr_block_end : next_mid_pos;

                    size_t months_pos = json_str.find("\"months\":", mids_pos);
                    if (months_pos != std::string::npos && months_pos < mid_block_end) {
                        for (int m = 1; m <= 12; ++m) {
                            std::string m_search = "\"month\": " + std::to_string(m);
                            size_t mo_pos = json_str.find(m_search, months_pos);
                            if (mo_pos == std::string::npos || mo_pos >= mid_block_end) {
                                m_search = "\"month\":" + std::to_string(m);
                                mo_pos = json_str.find(m_search, months_pos);
                            }

                            if (mo_pos != std::string::npos && mo_pos < mid_block_end) {
                                size_t f_pos = json_str.find("\"formula\":", mo_pos);
                                if (f_pos != std::string::npos && f_pos < mo_pos + 200) {
                                    size_t q_start = json_str.find("\"", f_pos + 10);
                                    size_t q_end = json_str.find("\"", q_start + 1);
                                    if (q_start != std::string::npos && q_end != std::string::npos) {
                                        mdata.months[m].formula = json_str.substr(q_start + 1, q_end - q_start - 1);
                                    }
                                }
                            }
                        }
                    }
                    ydata.mids.push_back(mdata);
                }
                mids_pos += 6;
            }

            // Items Parsing
            size_t items_pos = yr_label_pos;
            while ((items_pos = json_str.find("\"id\":", items_pos)) != std::string::npos && items_pos < yr_block_end) {
                size_t id_quote_start = json_str.find("\"", items_pos + 5);
                size_t id_quote_end = json_str.find("\"", id_quote_start + 1);
                if (id_quote_start != std::string::npos && id_quote_end != std::string::npos) {
                    std::string item_id = json_str.substr(id_quote_start + 1, id_quote_end - id_quote_start - 1);

                    std::string item_uuid;
                    size_t uuid_pos = json_str.rfind("\"uuid\":", items_pos);
                    if (uuid_pos != std::string::npos && uuid_pos > yr_label_pos && items_pos - uuid_pos < 80) {
                        size_t u_start = json_str.find("\"", uuid_pos + 7);
                        size_t u_end = json_str.find("\"", u_start + 1);
                        if (u_start != std::string::npos && u_end != std::string::npos) {
                            item_uuid = json_str.substr(u_start + 1, u_end - u_start - 1);
                        }
                    }
                    if (item_uuid.empty()) item_uuid = generate_uuid("id");

                    int target_month = 1;
                    size_t month_pos = json_str.rfind("\"month\":", items_pos);
                    if (month_pos != std::string::npos && month_pos > yr_label_pos) {
                        size_t m_end = json_str.find_first_of(",}\n", month_pos + 8);
                        try { target_month = std::stoi(trim(json_str.substr(month_pos + 8, m_end - (month_pos + 8)))); } catch (...) {}
                    }

                    if (target_month >= 1 && target_month <= 12) {
                        ItemData item;
                        item.uuid = item_uuid;
                        item.id = item_id;

                        size_t sub_items_pos = json_str.find("\"sub_items\":", items_pos);
                        size_t next_item_pos = json_str.find("\"id\":", items_pos + 5);
                        if (sub_items_pos != std::string::npos && (next_item_pos == std::string::npos || sub_items_pos < next_item_pos)) {
                            size_t sub_id_pos = sub_items_pos;
                            while ((sub_id_pos = json_str.find("\"sub_id\":", sub_id_pos)) != std::string::npos) {
                                if (next_item_pos != std::string::npos && sub_id_pos > next_item_pos) break;

                                size_t s_start = json_str.find("\"", sub_id_pos + 9);
                                size_t s_end = json_str.find("\"", s_start + 1);
                                if (s_start != std::string::npos && s_end != std::string::npos) {
                                    std::string s_id = json_str.substr(s_start + 1, s_end - s_start - 1);

                                    std::string s_uuid;
                                    size_t s_uuid_pos = json_str.rfind("\"uuid\":", sub_id_pos);
                                    if (s_uuid_pos != std::string::npos && s_uuid_pos > sub_items_pos && sub_id_pos - s_uuid_pos < 80) {
                                        size_t su_start = json_str.find("\"", s_uuid_pos + 7);
                                        size_t su_end = json_str.find("\"", su_start + 1);
                                        if (su_start != std::string::npos && su_end != std::string::npos) {
                                            s_uuid = json_str.substr(su_start + 1, su_end - su_start - 1);
                                        }
                                    }
                                    if (s_uuid.empty()) s_uuid = generate_uuid("sub");

                                    double s_val = 0.0;
                                    size_t val_pos = json_str.find("\"value\":", sub_id_pos);
                                    if (val_pos != std::string::npos) {
                                        size_t v_end = json_str.find_first_of(",}\n", val_pos + 8);
                                        try { s_val = std::stod(trim(json_str.substr(val_pos + 8, v_end - (val_pos + 8)))); } catch (...) {}
                                    }

                                    SubItem sub{s_uuid, s_id, s_val};
                                    item.sub_items.push_back(sub);
                                }
                                sub_id_pos += 9;
                            }
                        }

                        item.recalculate_total();
                        ydata.months[target_month].items.push_back(item);
                    }
                }
                items_pos += 5;
            }

            for (int m = 1; m <= 12; ++m) {
                recalculate_all_formulas_for_month(ydata, m);
            }
        }
        yr_label_pos += 7;
    }

    return true;
}

bool DBManager::save_to_file(const std::string& filepath) {
    try {
        std::string target_path = resolve_path(filepath);
        std::ofstream ofs(target_path);
        if (!ofs.is_open()) return false;
        ofs << serialize_json();
        ofs.close();
        return true;
    } catch (...) {
        return false;
    }
}

bool DBManager::load_from_file(const std::string& filepath) {
    try {
        std::string target_path = resolve_path(filepath);
        if (!std::filesystem::exists(target_path)) return false;
        std::ifstream ifs(target_path);
        if (!ifs.is_open()) return false;
        std::stringstream ss;
        ss << ifs.rdbuf();
        ifs.close();
        return deserialize_json(ss.str());
    } catch (...) {
        return false;
    }
}

} // namespace DB
