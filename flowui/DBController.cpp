#include "DBController.hpp"
#include <QDebug>
#include <QSettings>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonArray>
#include <QUuid>

DBController::DBController(QObject *parent)
    : QObject(parent)
{
    loadDatabase();
}

int DBController::startYear() const {
    return m_dbManager.get_config().start_year;
}

int DBController::endYear() const {
    return m_dbManager.get_config().end_year;
}

void DBController::setStartYear(int y) {
    if (startYear() != y) {
        configureYearRange(y, endYear());
    }
}

void DBController::setEndYear(int y) {
    if (endYear() != y) {
        configureYearRange(startYear(), y);
    }
}

QVariantList DBController::yearList() const {
    QVariantList list;
    std::vector<int> yrs = m_dbManager.get_year_list(false);
    for (int y : yrs) {
        list.append(y);
    }
    return list;
}

bool DBController::configureYearRange(int startYear, int endYear) {
    bool ok = m_dbManager.configure_year_range(startYear, endYear);
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit yearRangeChanged(startYear, endYear);
    }
    return ok;
}

bool DBController::saveDatabase() {
    return m_dbManager.save_to_file("db/database.json");
}

bool DBController::loadDatabase() {
    bool ok = m_dbManager.load_from_file("db/database.json");
    emit yearRangeChanged(startYear(), endYear());
    return ok;
}

// ==========================================
// MID Blocks Implementation
// ==========================================

QVariantList DBController::getMIDItems(int year) {
    QVariantList list;
    if (year <= 0) return list;

    bool isNewYear = (m_dbManager.get_year(year) == nullptr);
    DB::YearData* ydata = m_dbManager.get_year(year);
    if (!ydata) {
        m_dbManager.set_year(year);
        ydata = m_dbManager.get_year(year);
    }
    if (!ydata) return list;

    if (isNewYear && ydata->mids.empty()) {
        m_dbManager.add_mid(year, "생활비용");
        m_dbManager.add_mid(year, "영업이익");
        m_dbManager.save_to_file("db/database.json");
    }

    // Recalculate all formulas for all 12 months to guarantee formula_result values are 100% up to date
    for (int m = 1; m <= 12; ++m) {
        m_dbManager.recalculate_all_formulas_for_month(*ydata, m);
    }

    for (const auto& mdata : ydata->mids) {
        QVariantMap midMap;
        midMap["uuid"] = QString::fromStdString(mdata.uuid);
        midMap["mid"] = QString::fromStdString(mdata.mid);
        midMap["name"] = QString::fromStdString(mdata.mid);

        QVariantList monthsList;
        QVariantMap monthsMap;
        double totalSum = 0.0;

        for (int m = 1; m <= 12; ++m) {
            QVariantMap monthMap;
            monthMap["month"] = m;
            auto mm_it = mdata.months.find(m);
            if (mm_it != mdata.months.end()) {
                monthMap["formula"] = QString::fromStdString(mm_it->second.formula);
                monthMap["value"] = mm_it->second.formula_result;
                monthMap["formula_result"] = mm_it->second.formula_result;
                monthsMap[QString::number(m)] = mm_it->second.formula_result;
                totalSum += mm_it->second.formula_result;
            } else {
                monthMap["formula"] = "";
                monthMap["value"] = 0.0;
                monthMap["formula_result"] = 0.0;
                monthsMap[QString::number(m)] = 0.0;
            }
            monthsList.append(monthMap);
        }
        midMap["months"] = monthsList;
        midMap["monthsMap"] = monthsMap;
        midMap["totalValue"] = totalSum;
        midMap["total"] = totalSum;
        list.append(midMap);
    }
    return list;
}

bool DBController::addMIDBlock(int year, const QString& midName) {
    if (year <= 0) return false;
    QString finalName = midName.trimmed();
    if (finalName.isEmpty()) {
        QVariantList currentMids = getMIDItems(year);
        finalName = QString("MID 블록 %1").arg(currentMids.size() + 1);
    }

    bool ok = m_dbManager.add_mid(year, finalName.toStdString());
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit midDataChanged(year);
    }
    return ok;
}

bool DBController::removeMIDBlock(int year, const QString& uuidOrMid) {
    if (year <= 0 || uuidOrMid.isEmpty()) return false;
    bool ok = m_dbManager.remove_mid(year, uuidOrMid.toStdString());
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit midDataChanged(year);
    }
    return ok;
}

bool DBController::updateMIDBlockTitle(int year, const QString& uuidOrMid, const QString& newTitle) {
    if (year <= 0 || uuidOrMid.isEmpty() || newTitle.isEmpty()) return false;
    bool ok = m_dbManager.update_mid_title(year, uuidOrMid.toStdString(), newTitle.toStdString());
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit midDataChanged(year);
    }
    return ok;
}

bool DBController::moveMIDBlock(int year, int fromIndex, int toIndex) {
    if (year <= 0) return false;
    bool ok = m_dbManager.move_mid(year, fromIndex, toIndex);
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit midDataChanged(year);
    }
    return ok;
}

bool DBController::setMIDMonthFormula(int year, const QString& midUuidOrName, int month, const QString& formula) {
    if (year <= 0 || midUuidOrName.isEmpty()) return false;
    bool ok = m_dbManager.set_formula(year, midUuidOrName.toStdString(), month, formula.toStdString());
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit midDataChanged(year);
    }
    return ok;
}

QString DBController::getMIDMonthFormula(int year, const QString& midUuidOrName, int month) {
    if (year <= 0 || midUuidOrName.isEmpty()) return "";
    int targetMonth = (month == 0) ? 1 : month;

    DB::YearData* ydata = m_dbManager.get_year(year);
    if (!ydata) return "";

    for (const auto& mdata : ydata->mids) {
        if (mdata.uuid == midUuidOrName.toStdString() || mdata.mid == midUuidOrName.toStdString()) {
            auto mm_it = mdata.months.find(targetMonth);
            if (mm_it != mdata.months.end()) {
                return QString::fromStdString(mm_it->second.formula);
            }
        }
    }
    return "";
}

int DBController::getSavedThemeIndex() {
    QSettings settings("HONG_ST", "FlowUI");
    return settings.value("SelectedThemeIndex", 0).toInt();
}

bool DBController::saveThemeIndex(int themeIndex) {
    QSettings settings("HONG_ST", "FlowUI");
    settings.setValue("SelectedThemeIndex", themeIndex);
    return true;
}

// ==========================================
// ID Blocks Implementation
// ==========================================

QVariantList DBController::getIDItems(int year, int month) {
    QVariantList list;
    if (year <= 0) return list;

    DB::YearData* ydata = m_dbManager.get_year(year);
    if (!ydata) {
        m_dbManager.set_year(year);
        ydata = m_dbManager.get_year(year);
    }
    if (!ydata) return list;

    if (month == 0) {
        // 합계 선택 시 ID 블록 미표시
        return list;
    }

    if (month >= 1 && month <= 12) {
        auto m_it = ydata->months.find(month);
        if (m_it == ydata->months.end()) {
            m_dbManager.add_id(year, month, "ID 블록 1");
            m_dbManager.add_id(year, month, "ID 블록 2");
            m_dbManager.add_id(year, month, "ID 블록 3");
            m_dbManager.save_to_file("db/database.json");
            m_it = ydata->months.find(month);
        }

        if (m_it != ydata->months.end()) {
            for (const auto& item_data : m_it->second.items) {
                QVariantMap itemMap;
                itemMap["uuid"] = QString::fromStdString(item_data.uuid);
                itemMap["id"] = QString::fromStdString(item_data.id);
                itemMap["totalValue"] = item_data.total_value;

                QVariantList subList;
                for (const auto& sub_item : item_data.sub_items) {
                    QVariantMap subMap;
                    subMap["uuid"] = QString::fromStdString(sub_item.uuid);
                    subMap["title"] = QString::fromStdString(sub_item.sub_id);
                    subMap["subId"] = QString::fromStdString(sub_item.sub_id);
                    subMap["value"] = sub_item.value;
                    subList.append(subMap);
                }
                itemMap["subItems"] = subList;
                list.append(itemMap);
            }
        }
    } else if (month == 0) {
        // month 0: 합계 (All 12 Months Annual Sum of ID blocks)
        std::map<std::string, std::pair<std::string, double>> aggregatedTotals; // id -> {uuid, sumTotal}
        std::map<std::string, std::map<std::string, double>> aggregatedSubItems; // id -> (subId -> sumVal)
        std::vector<std::string> idOrder;

        for (int m = 1; m <= 12; ++m) {
            auto m_it = ydata->months.find(m);
            if (m_it != ydata->months.end()) {
                for (const auto& item_data : m_it->second.items) {
                    if (aggregatedTotals.find(item_data.id) == aggregatedTotals.end()) {
                        idOrder.push_back(item_data.id);
                        aggregatedTotals[item_data.id] = {item_data.uuid, 0.0};
                    }
                    aggregatedTotals[item_data.id].second += item_data.total_value;

                    for (const auto& sub : item_data.sub_items) {
                        aggregatedSubItems[item_data.id][sub.sub_id] += sub.value;
                    }
                }
            }
        }

        for (const auto& idName : idOrder) {
            QVariantMap itemMap;
            itemMap["uuid"] = QString::fromStdString(aggregatedTotals[idName].first);
            itemMap["id"] = QString::fromStdString(idName);
            itemMap["totalValue"] = aggregatedTotals[idName].second;

            QVariantList subList;
            for (const auto& subPair : aggregatedSubItems[idName]) {
                QVariantMap subMap;
                subMap["uuid"] = QString::fromStdString("sub_" + subPair.first);
                subMap["title"] = QString::fromStdString(subPair.first);
                subMap["subId"] = QString::fromStdString(subPair.first);
                subMap["value"] = subPair.second;
                subList.append(subMap);
            }
            itemMap["subItems"] = subList;
            list.append(itemMap);
        }
    }
    return list;
}

bool DBController::addIDBlock(int year, int month, const QString& idName) {
    if (year <= 0) return false;
    int targetMonth = (month == 0) ? 1 : month;

    QString finalName = idName.trimmed();
    if (finalName.isEmpty()) {
        QVariantList currentItems = getIDItems(year, targetMonth);
        int nextNum = currentItems.size() + 1;
        finalName = QString("ID 블록 %1").arg(nextNum);
    }

    bool ok = m_dbManager.add_id(year, targetMonth, finalName.toStdString());
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit idDataChanged(year, month);
        emit midDataChanged(year);
    }
    return ok;
}

bool DBController::removeIDBlock(int year, int month, const QString& uuidOrId) {
    if (year <= 0 || uuidOrId.isEmpty()) return false;
    int targetMonth = (month == 0) ? 1 : month;

    bool ok = m_dbManager.remove_id(year, targetMonth, uuidOrId.toStdString());
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit idDataChanged(year, month);
        emit midDataChanged(year);
    }
    return ok;
}

bool DBController::updateIDBlockTitle(int year, int month, const QString& uuidOrId, const QString& newIdName) {
    if (year <= 0 || uuidOrId.isEmpty() || newIdName.isEmpty()) return false;
    int targetMonth = (month == 0) ? 1 : month;

    bool ok = m_dbManager.update_id_title(year, targetMonth, uuidOrId.toStdString(), newIdName.toStdString());
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit idDataChanged(year, month);
        emit midDataChanged(year);
    }
    return ok;
}

bool DBController::moveIDBlock(int year, int month, int fromIndex, int toIndex) {
    if (year <= 0) return false;
    int targetMonth = (month == 0) ? 1 : month;

    bool ok = m_dbManager.move_id(year, targetMonth, fromIndex, toIndex);
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit idDataChanged(year, month);
        emit midDataChanged(year);
    }
    return ok;
}

QString DBController::addSubID(int year, int month, const QString& blockUuidOrId, const QString& subIdName, double value) {
    if (year <= 0 || blockUuidOrId.isEmpty()) return "";
    int targetMonth = (month == 0) ? 1 : month;

    QString finalSubName = subIdName.trimmed();
    if (finalSubName.isEmpty()) {
        finalSubName = "새 항목";
    }

    static qint64 counter = 0;
    counter++;
    QString newSubUuid = QString("sub_%1_%2").arg(QDateTime::currentMSecsSinceEpoch()).arg(counter);

    bool ok = m_dbManager.add_subid(year, targetMonth, blockUuidOrId.toStdString(), finalSubName.toStdString(), value, newSubUuid.toStdString());
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit idDataChanged(year, month);
        emit midDataChanged(year);
        return newSubUuid;
    }
    return "";
}

bool DBController::removeSubID(int year, int month, const QString& blockUuidOrId, const QString& subUuidOrName) {
    if (year <= 0 || blockUuidOrId.isEmpty() || subUuidOrName.isEmpty()) return false;
    int targetMonth = (month == 0) ? 1 : month;

    bool ok = m_dbManager.remove_subid(year, targetMonth, blockUuidOrId.toStdString(), subUuidOrName.toStdString());
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit idDataChanged(year, month);
        emit midDataChanged(year);
    }
    return ok;
}

bool DBController::updateSubID(int year, int month, const QString& blockUuidOrId, const QString& subUuidOrName, const QString& newSubIdName, double value) {
    if (year <= 0 || blockUuidOrId.isEmpty() || subUuidOrName.isEmpty()) return false;
    int targetMonth = (month == 0) ? 1 : month;

    bool ok = m_dbManager.update_subid(year, targetMonth, blockUuidOrId.toStdString(), subUuidOrName.toStdString(), newSubIdName.toStdString(), value);
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit idDataChanged(year, month);
        emit midDataChanged(year);
    }
    return ok;
}

bool DBController::moveSubID(int year, int month, const QString& blockUuidOrId, int fromIndex, int toIndex) {
    if (year <= 0 || blockUuidOrId.isEmpty()) return false;
    int targetMonth = (month == 0) ? 1 : month;

    bool ok = m_dbManager.move_subid(year, targetMonth, blockUuidOrId.toStdString(), fromIndex, toIndex);
    if (ok) {
        m_dbManager.save_to_file("db/database.json");
        emit idDataChanged(year, month);
        emit midDataChanged(year);
    }
    return ok;
}

QVariantList DBController::getGraphSlotMids(int year) {
    QSettings settings("HONG_ST", "FlowApp");
    QString key = QString("GraphSlots/%1").arg(year);
    QStringList names = settings.value(key).toStringList();

    QVariantList result;
    QVariantList yearMids = getMIDItems(year);

    for (int i = 0; i < 3; ++i) {
        if (i < names.size() && !names[i].isEmpty()) {
            QString targetVal = names[i];
            bool found = false;
            if (targetVal == "전체 MID 합계") {
                QVariantMap itemObj;
                itemObj["name"] = "전체 MID 합계";
                itemObj["mid"] = "전체 MID 합계";
                itemObj["uuid"] = "";
                result.append(itemObj);
                found = true;
            } else {
                for (const QVariant& v : yearMids) {
                    QVariantMap m = v.toMap();
                    if (m.value("uuid").toString() == targetVal ||
                        m.value("name").toString() == targetVal ||
                        m.value("mid").toString() == targetVal) {
                        result.append(m);
                        found = true;
                        break;
                    }
                }
            }
            if (!found) {
                result.append(QVariant());
            }
        } else {
            result.append(QVariant());
        }
    }
    return result;
}

bool DBController::saveGraphSlotMids(int year, const QVariantList& slotMids) {
    QSettings settings("HONG_ST", "FlowApp");
    QString key = QString("GraphSlots/%1").arg(year);
    QStringList names;

    for (const QVariant& v : slotMids) {
        if (v.isValid() && !v.isNull()) {
            QVariantMap m = v.toMap();
            QString uuid = m.value("uuid").toString();
            if (!uuid.isEmpty()) {
                names.append(uuid);
            } else {
                QString name = m.value("name").toString();
                if (name.isEmpty()) name = m.value("mid").toString();
                names.append(name);
            }
        } else {
            names.append("");
        }
    }
    settings.setValue(key, names);
    return true;
}

QStringList DBController::getCategoryList(const QString& type) {
    QSettings settings("HONG_ST", "FlowApp");
    QString key = QString("Categories/%1").arg(type);
    QStringList list = settings.value(key).toStringList();
    if (list.isEmpty()) {
        if (type == "MID") {
            list = QStringList() << "수입금액" << "지출금액" << "기타";
        } else if (type == "ID") {
            list = QStringList() << "월급" << "고정지출" << "당일지출" << "기타";
        } else if (type == "SubID") {
            list = QStringList() << "알바" << "근로" << "저금" << "교통비" << "통신비" << "음식" << "여행" << "기타";
        }
    }
    return list;
}

bool DBController::saveCategoryList(const QString& type, const QStringList& categories) {
    QSettings settings("HONG_ST", "FlowApp");
    QString key = QString("Categories/%1").arg(type);
    settings.setValue(key, categories);
    return true;
}

QVariantList DBController::getSubIDItemsForYear(int year) {
    QVariantList list;
    if (year <= 0) return list;

    QMap<QString, double> subTotals;
    QMap<QString, QString> subUuids;

    DB::YearData* ydata = m_dbManager.get_year(year);
    if (ydata) {
        for (int m = 1; m <= 12; ++m) {
            auto mo_it = ydata->months.find(m);
            if (mo_it != ydata->months.end()) {
                for (const auto& item : mo_it->second.items) {
                    for (const auto& sub : item.sub_items) {
                        QString name = QString::fromStdString(sub.sub_id).trimmed();
                        if (!name.isEmpty()) {
                            subTotals[name] += sub.value;
                            if (!subUuids.contains(name)) {
                                subUuids[name] = QString::fromStdString(sub.uuid);
                            }
                        }
                    }
                }
            }
        }
    }

    for (auto it = subTotals.begin(); it != subTotals.end(); ++it) {
        QVariantMap subMap;
        subMap["name"] = it.key();
        subMap["title"] = it.key();
        subMap["subId"] = it.key();
        subMap["mid"] = it.key();
        subMap["uuid"] = subUuids.value(it.key());
        subMap["totalValue"] = it.value();
        list.append(subMap);
    }

    return list;
}

QString DBController::getShareAnalysisMode() {
    QSettings settings("HONG_ST", "FlowUI");
    return settings.value("ShareAnalysisMode", "MID").toString();
}

bool DBController::setShareAnalysisMode(const QString& mode) {
    QSettings settings("HONG_ST", "FlowUI");
    settings.setValue("ShareAnalysisMode", mode);
    return true;
}

QString DBController::getMonthlyNote(int year, int month) {
    QSettings settings("HONG_ST", "FlowUI");
    QString key = QString("Notes/%1_%2").arg(year).arg(month);
    return settings.value(key, "").toString();
}

bool DBController::saveMonthlyNote(int year, int month, const QString& note) {
    QSettings settings("HONG_ST", "FlowUI");
    QString key = QString("Notes/%1_%2").arg(year).arg(month);
    settings.setValue(key, note);
    return true;
}

QVariantList DBController::getDailyItems(int year, int month, int day) {
    QSettings settings("HONG_ST", "FlowUI");
    QString key = QString("DailyExpenses/%1_%2_%3").arg(year).arg(month).arg(day);
    QByteArray data = settings.value(key).toByteArray();
    if (data.isEmpty()) return QVariantList();

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray()) return QVariantList();
    return doc.array().toVariantList();
}

double DBController::getMonthlyDailyTotal(int year, int month) {
    double total = 0.0;
    for (int day = 1; day <= 31; ++day) {
        QVariantList items = getDailyItems(year, month, day);
        for (const QVariant& item : items) {
            QVariantMap map = item.toMap();
            total += map["value"].toDouble();
        }
    }
    return total;
}

QString DBController::addDailyItem(int year, int month, int day, const QString& name, double value) {
    QSettings settings("HONG_ST", "FlowUI");
    QString key = QString("DailyExpenses/%1_%2_%3").arg(year).arg(month).arg(day);
    QVariantList list = getDailyItems(year, month, day);

    QString uuid = QUuid::createUuid().toString(QUuid::WithoutBraces);
    QVariantMap item;
    item["uuid"] = uuid;
    item["name"] = name.isEmpty() ? QString("지출 항목 %1").arg(list.size() + 1) : name;
    item["value"] = value;

    list.append(item);

    QJsonArray arr = QJsonArray::fromVariantList(list);
    settings.setValue(key, QJsonDocument(arr).toJson(QJsonDocument::Compact));
    emit dailyDataChanged(year, month, day);

    DB::YearData* ydata = m_dbManager.get_year(year);
    if (ydata) {
        m_dbManager.recalculate_all_formulas_for_month(*ydata, month);
    }
    emit midDataChanged(year);
    return uuid;
}

bool DBController::removeDailyItem(int year, int month, int day, const QString& uuid) {
    QSettings settings("HONG_ST", "FlowUI");
    QString key = QString("DailyExpenses/%1_%2_%3").arg(year).arg(month).arg(day);
    QVariantList list = getDailyItems(year, month, day);

    bool found = false;
    for (int i = 0; i < list.size(); ++i) {
        QVariantMap map = list[i].toMap();
        if (map["uuid"].toString() == uuid) {
            list.removeAt(i);
            found = true;
            break;
        }
    }

    if (found) {
        QJsonArray arr = QJsonArray::fromVariantList(list);
        settings.setValue(key, QJsonDocument(arr).toJson(QJsonDocument::Compact));
        emit dailyDataChanged(year, month, day);
        syncDailyToSubID(year, month);

        DB::YearData* ydata = m_dbManager.get_year(year);
        if (ydata) {
            m_dbManager.recalculate_all_formulas_for_month(*ydata, month);
        }
        emit midDataChanged(year);
    }
    return found;
}

bool DBController::updateDailyItem(int year, int month, int day, const QString& uuid, const QString& newName, double value) {
    QSettings settings("HONG_ST", "FlowUI");
    QString key = QString("DailyExpenses/%1_%2_%3").arg(year).arg(month).arg(day);
    QVariantList list = getDailyItems(year, month, day);

    bool found = false;
    for (int i = 0; i < list.size(); ++i) {
        QVariantMap map = list[i].toMap();
        if (map["uuid"].toString() == uuid) {
            map["name"] = newName;
            map["value"] = value;
            list[i] = map;
            found = true;
            break;
        }
    }

    if (found) {
        QJsonArray arr = QJsonArray::fromVariantList(list);
        settings.setValue(key, QJsonDocument(arr).toJson(QJsonDocument::Compact));
        emit dailyDataChanged(year, month, day);
        syncDailyToSubID(year, month);

        DB::YearData* ydata = m_dbManager.get_year(year);
        if (ydata) {
            m_dbManager.recalculate_all_formulas_for_month(*ydata, month);
        }
        emit midDataChanged(year);
    }
    return found;
}

bool DBController::moveDailyItem(int year, int month, int day, int fromIndex, int toIndex) {
    QSettings settings("HONG_ST", "FlowUI");
    QString key = QString("DailyExpenses/%1_%2_%3").arg(year, month, day);

    QVariantList list = getDailyItems(year, month, day);
    if (fromIndex < 0 || fromIndex >= list.size()) return false;
    int clampedTo = qBound(0, toIndex, list.size() - 1);
    if (fromIndex == clampedTo) return false;

    list.move(fromIndex, clampedTo);

    QJsonArray arr = QJsonArray::fromVariantList(list);
    settings.setValue(key, QJsonDocument(arr).toJson(QJsonDocument::Compact));
    emit dailyDataChanged(year, month, day);

    DB::YearData* ydata = m_dbManager.get_year(year);
    if (ydata) {
        m_dbManager.recalculate_all_formulas_for_month(*ydata, month);
    }
    emit midDataChanged(year);
    return true;
}

bool DBController::syncDailyToSubID(int year, int month) {
    if (year <= 0 || month <= 0 || month > 12) return false;

    // 1. Calculate sum for each category across all days (1..31) of the month
    QMap<QString, double> categorySums;
    for (int d = 1; d <= 31; ++d) {
        QVariantList dailyList = getDailyItems(year, month, d);
        for (const auto& itemVar : dailyList) {
            QVariantMap item = itemVar.toMap();
            QString name = item["name"].toString().trimmed();
            double val = item["value"].toDouble();
            if (!name.isEmpty()) {
                categorySums[name] += val;
            }
        }
    }

    // 2. Find matching SubID blocks in the ID blocks for that month and update their values
    QVariantList idList = getIDItems(year, month);
    bool updated = false;
    for (const auto& idBlockVar : idList) {
        QVariantMap idBlock = idBlockVar.toMap();
        QString idUuid = idBlock["uuid"].toString();
        QVariantList subList = idBlock["subBlockModel"].toList();
        for (const auto& subVar : subList) {
            QVariantMap subMap = subVar.toMap();
            QString subUuid = subMap["uuid"].toString();
            QString subName = subMap["name"].toString().trimmed();
            if (categorySums.contains(subName)) {
                double newSum = categorySums[subName];
                if (m_dbManager.update_subid(year, month, idUuid.toStdString(), subUuid.toStdString(), subName.toStdString(), newSum)) {
                    updated = true;
                }
            }
        }
    }

    if (updated) {
        m_dbManager.save_to_file("db/database.json");
        emit idDataChanged(year, month);
    }
    return updated;
}
