import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int selectedYear: 2026
    property int selectedMonth: 8
    property int selectedDay: 8

    readonly property int activeMonth: (selectedMonth > 0 && selectedMonth <= 12) ? selectedMonth : (new Date().getMonth() + 1)
    readonly property int activeDay: (selectedDay > 0 && selectedDay <= 31) ? selectedDay : (new Date().getDate())

    property var todayDateObj: new Date(selectedYear, activeMonth - 1, activeDay)
    property var yesterdayDateObj: {
        var d = new Date(selectedYear, activeMonth - 1, activeDay)
        d.setDate(d.getDate() - 1)
        return d
    }

    readonly property int todayYear: todayDateObj.getFullYear()
    readonly property int todayMonth: todayDateObj.getMonth() + 1
    readonly property int todayDay: todayDateObj.getDate()

    readonly property int yesterdayYear: yesterdayDateObj.getFullYear()
    readonly property int yesterdayMonth: yesterdayDateObj.getMonth() + 1
    readonly property int yesterdayDay: yesterdayDateObj.getDate()

    property var todayDailyItems: []
    property var yesterdayDailyItems: []

    function refreshDailyComparisonData() {
        if (typeof dbController !== "undefined" && typeof dbController.getDailyItems === "function") {
            var tItems = dbController.getDailyItems(todayYear, todayMonth, todayDay)
            todayDailyItems = tItems ? tItems.slice() : []

            var yItems = dbController.getDailyItems(yesterdayYear, yesterdayMonth, yesterdayDay)
            yesterdayDailyItems = yItems ? yItems.slice() : []
        }
    }

    function getItemsTotal(itemsList) {
        var sum = 0.0
        if (itemsList && itemsList.length > 0) {
            for (var i = 0; i < itemsList.length; i++) {
                var item = itemsList[i]
                if (item && item.value !== undefined) {
                    var v = Number(item.value.toString().replace(/[^0-9.-]+/g, ""))
                    if (!isNaN(v)) sum += v
                }
            }
        }
        return sum
    }

    readonly property real todayTotalExpense: getItemsTotal(todayDailyItems)
    readonly property real yesterdayTotalExpense: getItemsTotal(yesterdayDailyItems)
    readonly property real diffExpenseAmount: todayTotalExpense - yesterdayTotalExpense
    readonly property real diffExpensePercent: {
        if (yesterdayTotalExpense > 0) {
            return (diffExpenseAmount / yesterdayTotalExpense) * 100.0
        } else if (todayTotalExpense > 0) {
            return 100.0
        } else {
            return 0.0
        }
    }

    function getDailyComparisonList() {
        var map = {}
        var keys = []

        if (yesterdayDailyItems) {
            for (var i = 0; i < yesterdayDailyItems.length; i++) {
                var yItem = yesterdayDailyItems[i]
                var name = (yItem && yItem.name) ? yItem.name : "미지정 항목"
                var val = Number(yItem && yItem.value !== undefined ? yItem.value.toString().replace(/[^0-9.-]+/g, "") : 0)
                if (isNaN(val)) val = 0

                if (!map[name]) {
                    map[name] = { name: name, yesterdayVal: 0, todayVal: 0 }
                    keys.push(name)
                }
                map[name].yesterdayVal += val
            }
        }

        if (todayDailyItems) {
            for (var j = 0; j < todayDailyItems.length; j++) {
                var tItem = todayDailyItems[j]
                var tName = (tItem && tItem.name) ? tItem.name : "미지정 항목"
                var tVal = Number(tItem && tItem.value !== undefined ? tItem.value.toString().replace(/[^0-9.-]+/g, "") : 0)
                if (isNaN(tVal)) tVal = 0

                if (!map[tName]) {
                    map[tName] = { name: tName, yesterdayVal: 0, todayVal: 0 }
                    keys.push(tName)
                }
                map[tName].todayVal += tVal
            }
        }

        var result = []
        for (var k = 0; k < keys.length; k++) {
            var entry = map[keys[k]]
            entry.diff = entry.todayVal - entry.yesterdayVal
            result.push(entry)
        }
        return result
    }

    property var midList: (typeof dbController !== "undefined" && visible) ? dbController.getMIDItems(selectedYear) : []

    // 3 Fixed MID Setting Slots Array [Slot 1, Slot 2, Slot 3]
    property var slotMids: [null, null, null]
    property int activeSelectingSlot: -1

    // Slot Colors Palette
    property var slotColors: ["#00E5FF", "#FFD60A", "#FF453A"]
    property var slotColorPalette: ["#00E5FF", "#FFD60A", "#FF453A", "#30D158", "#FF9F0A", "#BF5AF2", "#64D2FF", "#FFFFFF"]

    function getSlotColor(slotIdx) {
        if (slotColors && slotColors[slotIdx] !== undefined) {
            return slotColors[slotIdx]
        }
        return slotColorPalette[slotIdx % slotColorPalette.length]
    }

    function cycleSlotColor(slotIdx) {
        var colors = slotColors.slice()
        var curColor = getSlotColor(slotIdx)
        var curIdx = slotColorPalette.indexOf(curColor)
        var nextIdx = (curIdx + 1) % slotColorPalette.length
        colors[slotIdx] = slotColorPalette[nextIdx]
        slotColors = colors
    }

    // Block 1 Setting Mode (Fade-Out State)
    property bool graphSettingsOpen: false

    function refreshMIDList() {
        if (typeof dbController !== "undefined") {
            midList = dbController.getMIDItems(selectedYear)
        }
    }

    function loadSlotMids() {
        if (typeof dbController !== "undefined") {
            var saved = dbController.getGraphSlotMids(selectedYear)
            if (saved && saved.length === 3) {
                slotMids = saved
                return
            }
        }
        slotMids = [null, null, null]
    }

    function updateAndSaveSlotMids(newSlotMids) {
        slotMids = newSlotMids
        if (typeof dbController !== "undefined") {
            dbController.saveGraphSlotMids(selectedYear, newSlotMids)
        }
    }

    onSelectedYearChanged: {
        refreshMIDList()
        loadSlotMids()
        refreshDailyComparisonData()
    }

    onSelectedMonthChanged: {
        refreshDailyComparisonData()
    }

    onSelectedDayChanged: {
        refreshDailyComparisonData()
    }

    onVisibleChanged: {
        if (visible) {
            refreshMIDList()
            loadSlotMids()
            refreshDailyComparisonData()
        }
    }

    Connections {
        target: typeof dbController !== "undefined" ? dbController : null
        function onMidDataChanged(year) {
            if (year === root.selectedYear) {
                root.refreshMIDList()
                root.loadSlotMids()
            }
        }
        function onIdDataChanged(yr, m) {
            if (yr === root.selectedYear) {
                root.refreshMIDList()
            }
        }
        function onDailyDataChanged(y, m, d) {
            root.refreshDailyComparisonData()
        }
    }

    function getMIDName(item) {
        if (!item) return ""
        if (item.mid !== undefined && item.mid !== "") return item.mid
        if (item.name !== undefined && item.name !== "") return item.name
        return "MID 블록"
    }

    function getMIDTotal(item) {
        if (!item) return 0
        if (item.totalValue !== undefined) return Number(item.totalValue)
        if (item.total !== undefined) return Number(item.total)
        return 0
    }

    function getGrandTotal() {
        var total = 0
        for (var i = 0; i < midList.length; i++) {
            total += getMIDTotal(midList[i])
        }
        return total
    }

    function getMonthlyTotal(m) {
        var sum = 0
        for (var i = 0; i < midList.length; i++) {
            sum += getSlotMonthValue(midList[i], m)
        }
        return sum
    }

    function isValidNum(n) {
        return (n !== null && n !== undefined && !isNaN(n) && isFinite(n))
    }

    function getSlotMonthValue(midItem, m) {
        if (!midItem) return 0
        if (midItem.name === "전체 MID 합계" || midItem.uuid === "") {
            return getMonthlyTotal(m)
        }
        var val = 0
        if (midItem.monthsMap && midItem.monthsMap[m] !== undefined) {
            val = Number(midItem.monthsMap[m])
        } else if (midItem.months) {
            if (Array.isArray(midItem.months)) {
                for (var idx = 0; idx < midItem.months.length; idx++) {
                    var monthEntry = midItem.months[idx]
                    if (monthEntry) {
                        var em = (monthEntry.month !== undefined) ? Number(monthEntry.month) : (idx + 1)
                        if (em === m) {
                            val = Number(monthEntry.value !== undefined ? monthEntry.value : (monthEntry.formula_result !== undefined ? monthEntry.formula_result : 0))
                            break
                        }
                    }
                }
            } else if (typeof midItem.months === "object") {
                var mData = midItem.months[m]
                if (mData !== undefined) {
                    val = (typeof mData === "object" && mData.value !== undefined) ? Number(mData.value) : Number(mData)
                }
            }
        }
        if (!isValidNum(val)) return 0
        return val
    }

    function getActiveSlots() {
        var list = []
        for (var i = 0; i < slotMids.length; i++) {
            if (slotMids[i] !== null && slotMids[i] !== undefined) {
                list.push({ slotIdx: i, data: slotMids[i] })
            }
        }
        return list
    }

    // Compute Chart Max Value: Highest MID Total Sum (or Max Monthly Value)
    function getChartMaxVal() {
        var active = getActiveSlots()
        var maxTot = 0
        var hasValidData = false

        if (active.length === 0) {
            for (var i = 0; i < midList.length; i++) {
                var tot = getMIDTotal(midList[i])
                if (isValidNum(tot) && tot > 0) {
                    if (tot > maxTot) maxTot = tot
                    hasValidData = true
                }
            }
        } else {
            for (var k = 0; k < active.length; k++) {
                var tot = getMIDTotal(active[k].data)
                if (isValidNum(tot) && tot > 0) {
                    if (tot > maxTot) maxTot = tot
                    hasValidData = true
                }
            }
        }

        if (active.length === 0) {
            for (var m = 1; m <= 12; m++) {
                var v = getMonthlyTotal(m)
                if (isValidNum(v) && v > maxTot) {
                    maxTot = v
                    hasValidData = true
                }
            }
        } else {
            for (var k2 = 0; k2 < active.length; k2++) {
                for (var m2 = 1; m2 <= 12; m2++) {
                    var v2 = getSlotMonthValue(active[k2].data, m2)
                    if (isValidNum(v2) && v2 > maxTot) {
                        maxTot = v2
                        hasValidData = true
                    }
                }
            }
        }

        return (hasValidData && maxTot > 0) ? maxTot : 100
    }

    Item {
        anchors.fill: parent
        anchors.margins: 4

        Row {
            id: reportRow
            anchors.fill: parent
            spacing: 16

            // ─────────────────────────────────────────────────────────────
            // 1. 큰 블록 (Large Main Report Block - 63% Width) - 그래프 분석
            // ─────────────────────────────────────────────────────────────
            Rectangle {
                id: mainLargeBlock
                width: Math.max(460, Math.floor((parent.width - 16) * 0.63))
                height: parent.height - 4
                radius: 16
                color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeDashBg : "#141414"
                border.width: 1.5
                border.color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeBorderColor : "#343434"

                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on border.color { ColorAnimation { duration: 250 } }

                // ─── Entire Inner Content (Fades Out Completely when graphSettingsOpen is true) ───
                Item {
                    id: blockContentContainer
                    anchors.fill: parent
                    opacity: root.graphSettingsOpen ? 0.0 : 1.0
                    visible: opacity > 0.0

                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        // Header Title
                        Item {
                            width: parent.width
                            height: 34

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: "#FFFFFF"
                                    anchors.verticalCenter: parent.verticalCenter
                                    scale: b1IconHover.containsMouse ? 1.25 : 1.0

                                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Σ"
                                        color: "#121212"
                                        font.pixelSize: 17
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: b1IconHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text {
                                        text: root.selectedYear + "년 그래프 분석"
                                        color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF"
                                        font.pixelSize: 17
                                        font.bold: true
                                        Behavior on color { ColorAnimation { duration: 250 } }
                                    }
                                    Text {
                                        text: "Graph Analytics & Monthly Trend"
                                        color: "#8E8E93"
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }

                        // Divider Line
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#333333"
                        }

                        // Slot Color Legend Indicators Row (Directly below horizontal divider line, Right-Aligned)
                        Item {
                            width: parent.width
                            height: root.getActiveSlots().length > 0 ? 22 : 0
                            visible: root.getActiveSlots().length > 0

                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 16

                                Repeater {
                                    model: root.getActiveSlots()

                                    delegate: Row {
                                        spacing: 6
                                        anchors.verticalCenter: parent.verticalCenter

                                        Rectangle {
                                            id: slotDot
                                            width: 10
                                            height: 10
                                            radius: 5
                                            color: root.getSlotColor(modelData.slotIdx)
                                            anchors.verticalCenter: parent.verticalCenter
                                            scale: slotDotHover.containsMouse ? 1.4 : 1.0

                                            Behavior on color { ColorAnimation { duration: 180 } }
                                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                                            MouseArea {
                                                id: slotDotHover
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.cycleSlotColor(modelData.slotIdx)
                                                }
                                            }
                                        }

                                        Text {
                                            text: root.getMIDName(modelData.data)
                                            color: "#CCCCCC"
                                            font.pixelSize: 12
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }

                        // ─── Main Interactive 12-Month Chart Box ───
                        Rectangle {
                            id: mainChartBox
                            width: parent.width
                            height: parent.height - (root.getActiveSlots().length > 0 ? 80 : 58)
                            color: "transparent"
                            border.width: 0

                            property real chartMax: root.getChartMaxVal()

                            Item {
                                anchors.fill: parent
                                anchors.margins: 14

                                // ─── Left Y-Axis (세로축 - 금액 표시) ───
                                Item {
                                    id: yAxisArea
                                    width: 65
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 20 // space for X-axis labels
                                    anchors.left: parent.left

                                    // 5 Y-Axis Value Ticks (Equal Divisions: 100%, 75%, 50%, 25%, 0%)
                                    Repeater {
                                        model: 5

                                        delegate: Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 8
                                            y: (parent.height * (index / 4.0)) - (height / 2)
                                            property real tickVal: mainChartBox.chartMax * (1.0 - (index / 4.0))
                                            text: isNaN(tickVal) ? "0" : Number(Math.round(tickVal)).toLocaleString(Qt.locale("ko_KR"), "f", 0)
                                            color: "#999999"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }
                                }

                                // Vertical Y-Axis Divider Line
                                Rectangle {
                                    anchors.left: yAxisArea.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 20
                                    width: 1
                                    color: "#333333"
                                }

                                // ─── Chart Data Grid Area (가로축 1~12월 & 데이터 바) ───
                                Item {
                                    id: chartDataArea
                                    anchors.left: yAxisArea.right
                                    anchors.leftMargin: 1
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom

                                    // Horizontal Gridlines (세로축 금액 등분 가로줄)
                                    Repeater {
                                        model: 5

                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 1
                                            color: index === 4 ? "#444444" : "#242424"
                                            y: (chartDataArea.height - 20) * (index / 4.0)
                                        }
                                    }

                                    // X-Axis Axis Bottom Line
                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#444444"
                                        y: chartDataArea.height - 20
                                    }

                                    // ─── 12 Months Columns Row (가로축 1월~12월) ───
                                    Row {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 20
                                        spacing: Math.max(2, (width - (12 * 30)) / 11)

                                        Repeater {
                                            model: 12

                                            delegate: Item {
                                                width: 30
                                                height: parent.height

                                                property int monthNum: index + 1
                                                property var activeSlotsList: root.getActiveSlots()

                                                // Vertical Bars for Active Slots
                                                Row {
                                                    anchors.bottom: parent.bottom
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    spacing: 2

                                                    Repeater {
                                                        model: activeSlotsList.length > 0 ? activeSlotsList : 1

                                                        delegate: Rectangle {
                                                            anchors.bottom: parent.bottom
                                                            width: activeSlotsList.length > 1 ? Math.max(6, (24 / activeSlotsList.length)) : 22

                                                            property real barVal: activeSlotsList.length > 0 ? root.getSlotMonthValue(modelData.data, monthNum) : root.getMonthlyTotal(monthNum)
                                                            property real barMax: mainChartBox.chartMax
                                                            property real calcH: barMax > 0 ? Math.max(4, Math.min(parent.parent.parent.height - 8, (barVal / barMax) * (parent.parent.parent.height - 8))) : 4
                                                            height: calcH
                                                            radius: 3
                                                            color: activeSlotsList.length > 0 ? root.getSlotColor(modelData.slotIdx) : (mBarHover.containsMouse ? "#FFFFFF" : "#3D3D3D")

                                                            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                                                            MouseArea {
                                                                id: mBarHover
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                            }

                                                            // Tooltip on Hover
                                                            Rectangle {
                                                                visible: mBarHover.containsMouse
                                                                anchors.bottom: parent.top
                                                                anchors.bottomMargin: 4
                                                                anchors.horizontalCenter: parent.horizontalCenter
                                                                width: tipTxt.width + 12
                                                                height: 24
                                                                radius: 5
                                                                color: "#2C2C2C"
                                                                border.width: 1
                                                                border.color: "#555555"
                                                                z: 100

                                                                Text {
                                                                    id: tipTxt
                                                                    anchors.centerIn: parent
                                                                    text: Number(parent.parent.barVal).toLocaleString(Qt.locale("ko_KR"), "f", 0)
                                                                    color: "#FFFFFF"
                                                                    font.pixelSize: 12
                                                                    font.bold: true
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                // X-Axis Month Label (1월 ~ 12월)
                                                Text {
                                                    anchors.top: parent.bottom
                                                    anchors.topMargin: 2
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: monthNum + "월"
                                                    color: "#AAAAAA"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ─── 3 MID Setting Cards Layer (Fades In when graphSettingsOpen is true) ───
                Item {
                    id: graphSettingLayer
                    anchors.fill: parent
                    opacity: root.graphSettingsOpen ? 1.0 : 0.0
                    visible: opacity > 0.0

                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    // Backdrop MouseArea: Outside Click Dismisses Settings or In-Card Selection
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.activeSelectingSlot !== -1) {
                                root.activeSelectingSlot = -1;
                            } else {
                                root.graphSettingsOpen = false;
                            }
                        }
                    }

                    // Top Title Header when Settings are Open
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.top: parent.top
                        anchors.topMargin: 16
                        spacing: 10

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: "#FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "⚙"
                                color: "#121212"
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                text: "그래프 설정"
                                color: "#FFFFFF"
                                font.pixelSize: 17
                                font.bold: true
                            }
                            Text {
                                text: "Graph Slot Configuration"
                                color: "#8E8E93"
                                font.pixelSize: 12
                            }
                        }
                    }

                    // Row of 3 In-Card Selector MID Cards
                    Row {
                        id: slotRow
                        spacing: 14
                        anchors.top: parent.top
                        anchors.topMargin: 64
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 16
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 16

                        Repeater {
                            model: 3

                            delegate: Rectangle {
                                id: slotCard
                                width: (parent.width - (2 * 14)) / 3
                                height: parent.height
                                radius: 14

                                property int slotIndex: index
                                property var currentMid: root.slotMids[slotIndex]
                                property bool isFilled: currentMid !== null && currentMid !== undefined
                                property bool isSelecting: root.activeSelectingSlot === slotIndex

                                color: isFilled ? "#262626" : (isSelecting ? "#252525" : (cardHover.containsMouse ? "#303030" : "#222222"))
                                border.width: 1.5
                                border.color: isFilled ? "#444444" : (isSelecting ? "#FFFFFF" : (cardHover.containsMouse ? "#888888" : "#383838"))

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                // ─── Case A: Configured MID Card State (선택 완료: MID 명만 표기) ───
                                Item {
                                    anchors.fill: parent
                                    visible: isFilled && !isSelecting

                                    Text {
                                        anchors.centerIn: parent
                                        text: isFilled ? root.getMIDName(currentMid) : ""
                                        color: "#FFFFFF"
                                        font.pixelSize: 16
                                        font.bold: true
                                        elide: Text.ElideRight
                                        width: parent.width - 24
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    // Reset / Remove Button (×)
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.topMargin: 10
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: rmHover.containsMouse ? "#FF453A" : "#3A3A3A"

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "×"
                                            color: rmHover.containsMouse ? "#FFFFFF" : "#AAAAAA"
                                            font.pixelSize: 13
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: rmHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var arr = root.slotMids.slice()
                                                arr[slotCard.slotIndex] = null
                                                root.updateAndSaveSlotMids(arr)
                                            }
                                        }
                                    }
                                }

                                // ─── Case B: In-Card Selection Mode (카드 안에서 MID 선택) ───
                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    visible: isSelecting

                                    // Card Backdrop MouseArea: Clicking outside option items cancels selection mode
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root.activeSelectingSlot = -1
                                        }
                                    }

                                    Flickable {
                                        anchors.fill: parent
                                        contentHeight: cardSelColumn.height
                                        clip: true

                                        Column {
                                            id: cardSelColumn
                                            width: parent.width
                                            spacing: 5

                                            Text {
                                                text: "MID " + (slotCard.slotIndex + 1) + " 선택"
                                                color: "#8E8E93"
                                                font.pixelSize: 11
                                                font.bold: true
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }

                                            // Option: 전체 MID 합계
                                            Rectangle {
                                                width: parent.width
                                                height: 30
                                                radius: 6
                                                color: cOpt0Hover.containsMouse ? "#3D3D3D" : "#1A1A1A"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "전체 MID 합계"
                                                    color: "#FFFFFF"
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    id: cOpt0Hover
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        var itemObj = { name: "전체 MID 합계", mid: "전체 MID 합계", total: root.getGrandTotal(), uuid: "" }
                                                        var arr = root.slotMids.slice()
                                                        arr[slotCard.slotIndex] = itemObj
                                                        root.updateAndSaveSlotMids(arr)
                                                        root.activeSelectingSlot = -1
                                                    }
                                                }
                                            }

                                            // Options: Actual MID blocks for selectedYear
                                            Repeater {
                                                model: root.midList

                                                delegate: Rectangle {
                                                    width: parent.width
                                                    height: 30
                                                    radius: 6
                                                    color: cOptHover.containsMouse ? "#3D3D3D" : "#1A1A1A"

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: root.getMIDName(modelData)
                                                        color: "#FFFFFF"
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        elide: Text.ElideRight
                                                        width: parent.width - 8
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }

                                                    MouseArea {
                                                        id: cOptHover
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            var arr = root.slotMids.slice()
                                                            arr[slotCard.slotIndex] = modelData
                                                            root.updateAndSaveSlotMids(arr)
                                                            root.activeSelectingSlot = -1
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ─── Case C: Empty Card State (MID 설정 +) ───
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    visible: !isFilled && !isSelecting

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 44
                                        height: 44
                                        radius: 22
                                        color: cardHover.containsMouse ? "#FFFFFF" : "#3A3A3A"

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "+"
                                            color: cardHover.containsMouse ? "#121212" : "#CCCCCC"
                                            font.pixelSize: 24
                                            font.bold: true

                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "MID 설정 " + (index + 1)
                                        color: cardHover.containsMouse ? "#FFFFFF" : "#888888"
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }

                                // Click MouseArea for Empty Card State
                                MouseArea {
                                    id: cardHover
                                    anchors.fill: parent
                                    enabled: !isFilled && !isSelecting
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.activeSelectingSlot = index
                                    }
                                }
                            }
                        }
                    }
                }

                // ─── Top-Right Circular Action Button Container (Hover Mode) ───
                Item {
                    width: 60
                    height: 60
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 5
                    anchors.rightMargin: 5
                    z: 300

                    HoverHandler {
                        id: block1MenuHoverZone
                    }

                    Rectangle {
                        id: topActionBtn
                        anchors.centerIn: parent
                        width: 30
                        height: 30
                        radius: 15
                        color: actionBtnHover.containsMouse ? "#FFFFFF" : "#3A3A3A"
                        border.width: 1
                        border.color: actionBtnHover.containsMouse ? "#FFFFFF" : "#4A4A4A"

                        opacity: (block1MenuHoverZone.hovered || actionBtnHover.containsMouse) ? 1.0 : 0.0
                        visible: opacity > 0.0

                        scale: actionBtnHover.containsMouse ? 1.08 : 1.0

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                        Text {
                            anchors.centerIn: parent
                            text: root.graphSettingsOpen ? "×" : "≡"
                            color: actionBtnHover.containsMouse ? "#121212" : "#DDDDDD"
                            font.pixelSize: root.graphSettingsOpen ? 16 : 14
                            font.bold: true

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: actionBtnHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.graphSettingsOpen = !root.graphSettingsOpen
                                if (!root.graphSettingsOpen) {
                                    root.activeSelectingSlot = -1
                                }
                            }
                        }
                    }
                }
            }

            // ─────────────────────────────────────────────────────────────
            // 2. 동적 크기 블록 (37% Width) - 당일지출 전일 대비 비교 분석
            // ─────────────────────────────────────────────────────────────
            Rectangle {
                id: equalBlock1
                width: Math.max(300, (parent.width - 16) - Math.floor((parent.width - 16) * 0.63))
                height: parent.height - 4
                radius: 16
                color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeDashBg : "#141414"
                border.width: 1.5
                border.color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeBorderColor : "#343434"
                clip: true

                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on border.color { ColorAnimation { duration: 250 } }

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    // Header Title Section
                    Item {
                        width: parent.width
                        height: 32

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Rectangle {
                                width: 30
                                height: 30
                                radius: 15
                                color: "#FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                                scale: b2IconHover.containsMouse ? 1.25 : 1.0

                                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.diffExpenseAmount > 0 ? "📈" : (root.diffExpenseAmount < 0 ? "📉" : "📊")
                                    font.pixelSize: 15
                                }

                                MouseArea {
                                    id: b2IconHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    text: "전일 대비 지출 분석"
                                    color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF"
                                    font.pixelSize: 16
                                    font.bold: true
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                                Text {
                                    text: "Daily Expense Difference Analysis"
                                    color: "#8E8E93"
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#333333"
                    }

                    // 1. Side-by-Side Dual Sub-Cards (전일 vs 금일 총액) - TOP
                    Row {
                        width: parent.width
                        height: 76

                        // Yesterday Card
                        Item {
                            width: (parent.width - 1) / 2
                            height: parent.height

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "전일 (" + root.yesterdayMonth + "/" + root.yesterdayDay + ")"
                                    color: "#8E8E93"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Number(root.yesterdayTotalExpense).toLocaleString(Qt.locale("ko_KR"), "f", 0) + "원"
                                    color: "#DDDDDD"
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: yCntText.width + 10
                                    height: 16
                                    radius: 8
                                    color: "#2C2C2E"

                                    Text {
                                        id: yCntText
                                        anchors.centerIn: parent
                                        text: root.yesterdayDailyItems.length + "개 항목"
                                        color: "#A0A0A0"
                                        font.pixelSize: 9
                                    }
                                }
                            }
                        }

                        // Vertical Divider between Yesterday & Today
                        Rectangle {
                            width: 1
                            height: parent.height - 16
                            color: "#333333"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Today Card
                        Item {
                            width: (parent.width - 1) / 2
                            height: parent.height

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "금일 (" + root.todayMonth + "/" + root.todayDay + ")"
                                    color: "#00E5FF"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Number(root.todayTotalExpense).toLocaleString(Qt.locale("ko_KR"), "f", 0) + "원"
                                    color: "#FFFFFF"
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: tCntText.width + 10
                                    height: 16
                                    radius: 8
                                    color: "#1E2C33"

                                    Text {
                                        id: tCntText
                                        anchors.centerIn: parent
                                        text: root.todayDailyItems.length + "개 항목"
                                        color: "#64D2FF"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    // Horizontal Divider Line above Expense Difference Analysis
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#333333"
                    }

                    // 2. Hero Diff Analysis (지출 분석) - DIRECTLY BELOW
                    Item {
                        width: parent.width
                        height: Math.max(90, equalBlock1.height - 32 - 32 - 1 - 76 - 1 - 30)

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: root.diffExpenseAmount > 0 ? "▲ 지출 증가" : (root.diffExpenseAmount < 0 ? "▼ 지출 절감" : "– 변동 없음")
                                color: root.diffExpenseAmount > 0 ? "#FF453A" : (root.diffExpenseAmount < 0 ? "#30D158" : "#8E8E93")
                                font.pixelSize: 14
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: (root.diffExpenseAmount > 0 ? "+" : "") + Number(root.diffExpenseAmount).toLocaleString(Qt.locale("ko_KR"), "f", 0) + "원"
                                color: "#FFFFFF"
                                font.pixelSize: 20
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: pctText.width + 12
                                height: 22
                                radius: 11
                                color: root.diffExpenseAmount > 0 ? "#FF453A" : (root.diffExpenseAmount < 0 ? "#30D158" : "#555555")
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    id: pctText
                                    anchors.centerIn: parent
                                    text: (root.diffExpenseAmount > 0 ? "+" : "") + root.diffExpensePercent.toFixed(1) + "%"
                                    color: "#FFFFFF"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
