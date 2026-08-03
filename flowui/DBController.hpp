#pragma once

#include <QObject>
#include <QVariantList>
#include "../db/DBManager.hpp"

class DBController : public QObject {
    Q_OBJECT
    Q_PROPERTY(int startYear READ startYear WRITE setStartYear NOTIFY yearRangeChanged)
    Q_PROPERTY(int endYear READ endYear WRITE setEndYear NOTIFY yearRangeChanged)
    Q_PROPERTY(QVariantList yearList READ yearList NOTIFY yearRangeChanged)

public:
    explicit DBController(QObject *parent = nullptr);

    int startYear() const;
    int endYear() const;
    void setStartYear(int y);
    void setEndYear(int y);
    QVariantList yearList() const;

    Q_INVOKABLE bool configureYearRange(int startYear, int endYear);
    Q_INVOKABLE bool saveDatabase();
    Q_INVOKABLE bool loadDatabase();

    // MID Blocks API
    Q_INVOKABLE QVariantList getMIDItems(int year);
    Q_INVOKABLE bool addMIDBlock(int year, const QString& midName = "");
    Q_INVOKABLE bool removeMIDBlock(int year, const QString& uuidOrMid);
    Q_INVOKABLE bool updateMIDBlockTitle(int year, const QString& uuidOrMid, const QString& newTitle);
    Q_INVOKABLE bool moveMIDBlock(int year, int fromIndex, int toIndex);
    Q_INVOKABLE bool setMIDMonthFormula(int year, const QString& midUuidOrName, int month, const QString& formula);
    Q_INVOKABLE QString getMIDMonthFormula(int year, const QString& midUuidOrName, int month);

    // Graph Slot Settings API
    Q_INVOKABLE QVariantList getGraphSlotMids(int year);
    Q_INVOKABLE bool saveGraphSlotMids(int year, const QVariantList& slotMids);

    // Category Settings API
    Q_INVOKABLE QStringList getCategoryList(const QString& type);
    Q_INVOKABLE bool saveCategoryList(const QString& type, const QStringList& categories);

    // System Theme Settings API
    Q_INVOKABLE int getSavedThemeIndex();
    Q_INVOKABLE bool saveThemeIndex(int themeIndex);

    // ID Blocks API
    Q_INVOKABLE QVariantList getIDItems(int year, int month);
    Q_INVOKABLE bool addIDBlock(int year, int month, const QString& idName = "");
    Q_INVOKABLE bool removeIDBlock(int year, int month, const QString& uuidOrId);
    Q_INVOKABLE bool updateIDBlockTitle(int year, int month, const QString& uuidOrId, const QString& newIdName);
    Q_INVOKABLE bool moveIDBlock(int year, int month, int fromIndex, int toIndex);

    // SubID Items API
    Q_INVOKABLE QString addSubID(int year, int month, const QString& blockUuidOrId, const QString& subIdName = "", double value = 0.0);
    Q_INVOKABLE bool removeSubID(int year, int month, const QString& blockUuidOrId, const QString& subUuidOrName);
    Q_INVOKABLE bool updateSubID(int year, int month, const QString& blockUuidOrId, const QString& subUuidOrName, const QString& newSubIdName, double value);
    Q_INVOKABLE bool moveSubID(int year, int month, const QString& blockUuidOrId, int fromIndex, int toIndex);

    // Share Analysis Mode & Data API
    Q_INVOKABLE QVariantList getSubIDItemsForYear(int year);
    Q_INVOKABLE QString getShareAnalysisMode();
    Q_INVOKABLE bool setShareAnalysisMode(const QString& mode);

    // Monthly Quick Note API
    Q_INVOKABLE QString getMonthlyNote(int year, int month);
    Q_INVOKABLE bool saveMonthlyNote(int year, int month, const QString& note);

    // Daily Expense Items API (일별 당일지출 API)
    Q_INVOKABLE QVariantList getDailyItems(int year, int month, int day);
    Q_INVOKABLE double getMonthlyDailyTotal(int year, int month);
    Q_INVOKABLE QString addDailyItem(int year, int month, int day, const QString& name = "", double value = 0.0);
    Q_INVOKABLE bool removeDailyItem(int year, int month, int day, const QString& uuid);
    Q_INVOKABLE bool updateDailyItem(int year, int month, int day, const QString& uuid, const QString& newName, double value);
    Q_INVOKABLE bool moveDailyItem(int year, int month, int day, int fromIndex, int toIndex);
    Q_INVOKABLE bool syncDailyToSubID(int year, int month);

signals:
    void yearRangeChanged(int startYear, int endYear);
    void idDataChanged(int year, int month);
    void midDataChanged(int year);
    void dailyDataChanged(int year, int month, int day);

private:
    DB::DBManager m_dbManager;
};
