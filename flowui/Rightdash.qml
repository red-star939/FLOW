import QtQuick
import QtQuick.Controls

Rectangle {
    id: rightdashRoot

    property int selectedYear: 2026
    property int selectedMonth: 8
    property int selectedDay: 15
    property var midList: []

    property int lastValidMonth: 8
    readonly property int activeMonth: selectedMonth > 0 ? selectedMonth : (lastValidMonth > 0 ? lastValidMonth : 1)

    property var dailyItems: []
    property real totalDailyExpense: 0
    property real totalMonthlyDailyExpense: 0
    property bool isInternalEdit: false

    radius: 24
    color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeDashBg : "#141414"
    border.width: 1
    border.color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeBorderColor : "#343434"

    Behavior on color { ColorAnimation { duration: 250 } }
    Behavior on border.color { ColorAnimation { duration: 250 } }
    clip: true

    onSelectedMonthChanged: {
        rightdashRoot.isInternalEdit = false
        if (selectedMonth > 0) {
            lastValidMonth = selectedMonth
        }
        refreshDailyData()
    }

    onSelectedYearChanged: {
        rightdashRoot.isInternalEdit = false
        refreshDailyData()
    }

    onSelectedDayChanged: {
        rightdashRoot.isInternalEdit = false
        refreshDailyData()
    }

    function recalculateTotals() {
        var sum = 0
        if (dailyItems && dailyItems.length > 0) {
            for (var i = 0; i < dailyItems.length; i++) {
                var item = dailyItems[i]
                if (item && item.value !== undefined) {
                    var v = Number(item.value.toString().replace(/[^0-9.-]+/g, ""))
                    if (!isNaN(v)) sum += v
                }
            }
        }
        var diff = sum - totalDailyExpense
        totalDailyExpense = sum
        totalMonthlyDailyExpense += diff
    }

    function refreshDailyData() {
        if (typeof dbController !== "undefined" && typeof dbController.getDailyItems === "function") {
            var items = dbController.getDailyItems(selectedYear, activeMonth, selectedDay)
            dailyItems = items ? items.slice() : []
            rightdashRoot.isInternalEdit = false;

            recalculateTotals()

            if (typeof dbController.getMonthlyDailyTotal === "function") {
                totalMonthlyDailyExpense = dbController.getMonthlyDailyTotal(selectedYear, activeMonth)
            } else {
                totalMonthlyDailyExpense = totalDailyExpense
            }
        }
    }

    Component.onCompleted: {
        var d = new Date()
        selectedYear = d.getFullYear()
        var m = d.getMonth() + 1
        selectedMonth = m
        lastValidMonth = m
        selectedDay = d.getDate()
        refreshDailyData()
    }

    Connections {
        target: typeof dbController !== "undefined" ? dbController : null
        function onDailyDataChanged(y, m, d) {
            if (y === rightdashRoot.selectedYear && m === rightdashRoot.activeMonth) {
                rightdashRoot.refreshDailyData()
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // ─── 상단 카테고리 제목 (당일지출 & 휠 일자 선택기) ───
        Item {
            width: parent.width
            height: 42

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                // 카테고리 뱃지 아이콘 (마우스 호버 시 1.25배 확대 연출)
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                    scale: dailyIconHover.containsMouse ? 1.25 : 1.0

                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                    Text {
                        anchors.centerIn: parent
                        text: "💳"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: dailyIconHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "당일지출"
                        color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF"
                        font.pixelSize: 17
                        font.bold: true

                        Behavior on color { ColorAnimation { duration: 250 } }
                    }

                    Text {
                        text: "Daily Expenses"
                        color: "#8E8E93"
                        font.pixelSize: 12
                    }
                }
            }

            // 우측: 3D 휠 일자 선택기 (Wheelday)
            Wheelday {
                id: dayWheel
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 105
                height: 38
                selectedYear: rightdashRoot.selectedYear
                selectedMonth: rightdashRoot.activeMonth
                selectedDay: rightdashRoot.selectedDay

                onDayChanged: (d) => {
                    rightdashRoot.selectedDay = d
                }
            }
        }

        // 구분선 (Divider)
        Rectangle {
            width: parent.width
            height: 1
            color: "#333333"
        }

        // ─── SubID 블록 컴포넌트로 직접 구성된 당일지출 리스트 ───
        ListView {
            id: dailyListView
            width: parent.width
            height: parent.height - 124
            clip: true
            spacing: 8
            model: rightdashRoot.dailyItems

            delegate: SubIDblock {
                blockIndex: index
                uuid: modelData.uuid ? modelData.uuid : ""
                parentFlickable: dailyListView
                title: modelData.name ? modelData.name : "새 항목"
                value: modelData.value !== undefined ? modelData.value.toString() : ""

                onTitleEdited: function(newTitle) {
                    if (typeof dbController !== "undefined") {
                        rightdashRoot.isInternalEdit = true
                        var val = Number(value.replace(/[^0-9.-]+/g, ""))
                        dbController.updateDailyItem(rightdashRoot.selectedYear, rightdashRoot.activeMonth, rightdashRoot.selectedDay, modelData.uuid, newTitle, isNaN(val) ? 0 : val)
                    }
                }

                onValueEdited: function(newValue) {
                    var rawNum = Number(newValue.replace(/[^0-9.-]+/g, ""))
                    var cleanVal = isNaN(rawNum) ? 0 : rawNum
                    if (rightdashRoot.dailyItems && index >= 0 && index < rightdashRoot.dailyItems.length) {
                        rightdashRoot.dailyItems[index].value = cleanVal
                    }
                    rightdashRoot.recalculateTotals()

                    if (typeof dbController !== "undefined") {
                        rightdashRoot.isInternalEdit = true
                        dbController.updateDailyItem(rightdashRoot.selectedYear, rightdashRoot.activeMonth, rightdashRoot.selectedDay, modelData.uuid, title, cleanVal)
                    }
                }

                onMoveRequested: function(fromIndex, toIndex) {
                    var clampedTo = Math.max(0, Math.min(rightdashRoot.dailyItems.length - 1, toIndex))
                    if (fromIndex !== clampedTo && typeof dbController !== "undefined") {
                        dbController.moveDailyItem(rightdashRoot.selectedYear, rightdashRoot.activeMonth, rightdashRoot.selectedDay, fromIndex, clampedTo)
                    }
                }

                onRemoveRequested: function(subIndex) {
                    if (typeof dbController !== "undefined") {
                        dbController.removeDailyItem(rightdashRoot.selectedYear, rightdashRoot.activeMonth, rightdashRoot.selectedDay, modelData.uuid)
                    }
                }
            }

            // 하단: 동그라미 + 모양 호버 버튼
            footer: Item {
                id: subAddContainer
                width: dailyListView.width
                height: 36

                HoverHandler {
                    id: subAddHoverHandler
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    radius: 13
                    color: subAddHoverHandler.hovered ? "#FFFFFF" : "#3A3A3A"
                    opacity: subAddHoverHandler.hovered ? 1.0 : 0.0
                    visible: opacity > 0.0

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: subAddHoverHandler.hovered ? "#202020" : "#AAAAAA"
                        font.pixelSize: 16
                        font.bold: true

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (typeof dbController !== "undefined") {
                                dbController.addDailyItem(rightdashRoot.selectedYear, rightdashRoot.activeMonth, rightdashRoot.selectedDay, "새 항목", 0)
                            }
                        }
                    }
                }
            }
        }

        // ─── 하단 합계 피드 (일자별 합계 + 해당 월 총 합계) ───
        Item {
            width: parent.width
            height: 52

            // 구분선
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#3A3A3A"
            }

            Column {
                anchors.fill: parent
                anchors.topMargin: 4
                spacing: 2

                // Row 1: 일자별 합계
                Item {
                    width: parent.width
                    height: 22

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: rightdashRoot.selectedDay + "일 합계"
                        color: "#AAAAAA"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: Number(rightdashRoot.totalDailyExpense).toLocaleString(Qt.locale("ko_KR"), "f", 0)
                        color: "#FF453A"
                        font.pixelSize: 13
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }
                }

                // Row 2: 해당 월 총합계
                Item {
                    width: parent.width
                    height: 22

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: rightdashRoot.activeMonth + "월 총합계"
                        color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF"
                        font.pixelSize: 12
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: Number(rightdashRoot.totalMonthlyDailyExpense).toLocaleString(Qt.locale("ko_KR"), "f", 0)
                        color: "#FF453A"
                        font.pixelSize: 14
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }
                }
            }
        }
    }
}
