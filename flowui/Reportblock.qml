import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int selectedYear: 2026

    property var midList: (typeof dbController !== "undefined" && visible) ? dbController.getMIDItems(selectedYear) : []
    property string shareMode: (typeof dbController !== "undefined" && typeof dbController.getShareAnalysisMode === "function") ? dbController.getShareAnalysisMode() : "MID"
    property var subidList: (typeof dbController !== "undefined" && visible && shareMode === "SubID") ? dbController.getSubIDItemsForYear(selectedYear) : []

    function activeShareList() {
        return shareMode === "SubID" ? subidList : midList;
    }

    function refreshShareList() {
        if (typeof dbController !== "undefined") {
            midList = dbController.getMIDItems(selectedYear)
            if (typeof dbController.getSubIDItemsForYear === "function") {
                subidList = dbController.getSubIDItemsForYear(selectedYear)
            }
        }
    }

    function getShareGrandTotal() {
        var list = activeShareList();
        var total = 0;
        for (var i = 0; i < list.length; i++) {
            total += getMIDTotal(list[i]);
        }
        return total;
    }

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
            if (typeof dbController.getSubIDItemsForYear === "function") {
                subidList = dbController.getSubIDItemsForYear(selectedYear)
            }
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
    }

    onVisibleChanged: {
        if (visible) {
            refreshMIDList()
            loadSlotMids()
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
                color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeCardBg : "#1F1F1F"
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
            // 2. 동적 크기 블록 (37% Width) - MID 점유율 분석 (도넛 차트 & 세로 구분점)
            // ─────────────────────────────────────────────────────────────
            Rectangle {
                id: equalBlock1
                width: Math.max(300, (parent.width - 16) - Math.floor((parent.width - 16) * 0.63))
                height: parent.height - 4
                radius: 16
                color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeCardBg : "#1F1F1F"
                border.width: 1.5
                border.color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeBorderColor : "#343434"

                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on border.color { ColorAnimation { duration: 250 } }

                property var hoveredMidItem: null
                property real hoveredMidPct: 0.0
                property real hoverMouseX: 0.0
                property real hoverMouseY: 0.0

                property var midPaletteColors: ["#00E5FF", "#FFD60A", "#FF453A", "#BF5AF2", "#30D158", "#FF9F0A", "#64D2FF", "#5856D6"]

                function cycleMidPaletteColor(idx) {
                    var colors = midPaletteColors.slice()
                    var palette = ["#00E5FF", "#FFD60A", "#FF453A", "#BF5AF2", "#30D158", "#FF9F0A", "#64D2FF", "#FFFFFF"]
                    var cur = colors[idx % colors.length] ? colors[idx % colors.length] : palette[idx % palette.length]
                    var pIdx = palette.indexOf(cur)
                    var nextColor = palette[(pIdx + 1) % palette.length]
                    colors[idx % colors.length] = nextColor
                    midPaletteColors = colors
                    pieCanvas.requestPaint()
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    // Header Title
                    Item {
                        width: parent.width
                        height: 34

                        HoverHandler {
                            id: block2MenuHoverZone
                        }

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
                                scale: b2IconHover.containsMouse ? 1.25 : 1.0

                                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "%"
                                    color: "#121212"
                                    font.pixelSize: 16
                                    font.bold: true
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
                                    text: root.shareMode === "SubID" ? "SubID 점유율 분석" : "점유율 분석"
                                    color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF"
                                    font.pixelSize: 17
                                    font.bold: true
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                                Text {
                                    text: root.shareMode === "SubID" ? "SubID Share Distribution" : "Share Distribution Analysis"
                                    color: "#8E8E93"
                                    font.pixelSize: 12
                                }
                            }
                        }

                        // Share Analysis Mode Selector Button (≡)
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28
                            height: 28
                            radius: 14
                            color: shareActionBtnHover.containsMouse ? "#FFFFFF" : "#3A3A3A"
                            border.width: 1
                            border.color: shareActionBtnHover.containsMouse ? "#FFFFFF" : "#4A4A4A"

                            opacity: (block2MenuHoverZone.hovered || shareActionBtnHover.containsMouse || sharePopup.opened) ? 1.0 : 0.0
                            visible: opacity > 0.0
                            scale: shareActionBtnHover.containsMouse ? 1.08 : 1.0

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                            Text {
                                anchors.centerIn: parent
                                text: sharePopup.opened ? "×" : "≡"
                                color: shareActionBtnHover.containsMouse ? "#121212" : "#DDDDDD"
                                font.pixelSize: sharePopup.opened ? 16 : 14
                                font.bold: true

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: shareActionBtnHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (sharePopup.opened) sharePopup.close()
                                    else sharePopup.open()
                                }
                            }

                            Popup {
                                id: sharePopup
                                x: -115
                                y: 34
                                width: 145
                                padding: 6
                                modal: false
                                focus: true
                                closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

                                background: Rectangle {
                                    radius: 10
                                    color: "#1F1F1F"
                                    border.width: 1
                                    border.color: "#343434"
                                }

                                Column {
                                    width: parent.width
                                    spacing: 4

                                    Text {
                                        text: "분석 기준 선택"
                                        color: "#8E8E93"
                                        font.pixelSize: 10
                                        font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 28
                                        radius: 6
                                        color: root.shareMode === "MID" ? "#3A3A3A" : (optMidHover.containsMouse ? "#2A2A2A" : "transparent")

                                        Text {
                                            anchors.centerIn: parent
                                            text: "MID 점유율"
                                            color: root.shareMode === "MID" ? "#00E5FF" : "#FFFFFF"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: optMidHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.shareMode = "MID"
                                                if (typeof dbController !== "undefined" && typeof dbController.setShareAnalysisMode === "function") {
                                                    dbController.setShareAnalysisMode("MID")
                                                }
                                                root.refreshShareList()
                                                pieCanvas.requestPaint()
                                                sharePopup.close()
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 28
                                        radius: 6
                                        color: root.shareMode === "SubID" ? "#3A3A3A" : (optSubHover.containsMouse ? "#2A2A2A" : "transparent")

                                        Text {
                                            anchors.centerIn: parent
                                            text: "SubID 점유율"
                                            color: root.shareMode === "SubID" ? "#00E5FF" : "#FFFFFF"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: optSubHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.shareMode = "SubID"
                                                if (typeof dbController !== "undefined" && typeof dbController.setShareAnalysisMode === "function") {
                                                    dbController.setShareAnalysisMode("SubID")
                                                }
                                                root.refreshShareList()
                                                pieCanvas.requestPaint()
                                                sharePopup.close()
                                            }
                                        }
                                    }
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

                    // ─── Donut Chart & Vertical Legend Container ───
                    Item {
                        id: chartContainer
                        width: parent.width
                        height: parent.height - 70

                        // Left/Center Side: Enlarged Donut Chart Area
                        Item {
                            id: donutArea
                            width: Math.min(parent.width - 130, parent.height)
                            height: width
                            anchors.left: parent.left
                            anchors.leftMargin: 22
                            anchors.verticalCenter: parent.verticalCenter

                            Canvas {
                                id: pieCanvas
                                anchors.centerIn: parent
                                width: parent.width
                                height: parent.height

                                property var paletteColors: ["#00E5FF", "#FFD60A", "#FF453A", "#BF5AF2", "#30D158", "#FF9F0A", "#64D2FF", "#5856D6"]

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    var cx = width / 2;
                                    var cy = height / 2;
                                    var radius = Math.min(cx, cy) - 2;
                                    var innerRadius = radius * 0.58;

                                    var activeList = root.activeShareList();
                                    var grandTot = root.getShareGrandTotal();

                                    if (grandTot <= 0 || activeList.length === 0) {
                                        ctx.beginPath();
                                        ctx.arc(cx, cy, radius, 0, 2 * Math.PI, false);
                                        ctx.fillStyle = "#2C2C2C";
                                        ctx.fill();

                                        ctx.beginPath();
                                        ctx.arc(cx, cy, innerRadius, 0, 2 * Math.PI, false);
                                        ctx.fillStyle = "#1F1F1F";
                                        ctx.fill();
                                        return;
                                    }

                                    var startAngle = -Math.PI / 2;

                                    for (var i = 0; i < activeList.length; i++) {
                                        var item = activeList[i];
                                        var val = root.getMIDTotal(item);
                                        if (val <= 0) continue;

                                        var sliceAngle = (val / grandTot) * (2 * Math.PI);
                                        var endAngle = startAngle + sliceAngle;

                                        ctx.beginPath();
                                        ctx.moveTo(cx, cy);
                                        ctx.arc(cx, cy, radius, startAngle, endAngle, false);
                                        ctx.closePath();
                                        ctx.fillStyle = equalBlock1.midPaletteColors[i % equalBlock1.midPaletteColors.length];
                                        ctx.fill();

                                        startAngle = endAngle;
                                    }

                                    // Center Hole (Donut style)
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, innerRadius, 0, 2 * Math.PI, false);
                                    ctx.fillStyle = "#1F1F1F";
                                    ctx.fill();
                                }

                                Connections {
                                    target: root
                                    function onMidListChanged() { pieCanvas.requestPaint() }
                                    function onSubidListChanged() { pieCanvas.requestPaint() }
                                    function onShareModeChanged() { pieCanvas.requestPaint() }
                                    function onSelectedYearChanged() { pieCanvas.requestPaint() }
                                }

                                Component.onCompleted: requestPaint()

                                // Mouse Area for Slice Hover Detection
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onPositionChanged: (mouse) => {
                                        var cx = width / 2;
                                        var cy = height / 2;
                                        var dx = mouse.x - cx;
                                        var dy = mouse.y - cy;
                                        var dist = Math.sqrt(dx * dx + dy * dy);
                                        var outerRadius = Math.min(cx, cy) - 2;
                                        var innerRadius = outerRadius * 0.58;

                                        var activeList = root.activeShareList();
                                        var grandTot = root.getShareGrandTotal();

                                        equalBlock1.hoverMouseX = mouse.x + donutArea.x;
                                        equalBlock1.hoverMouseY = mouse.y + donutArea.y;

                                        if (dist >= innerRadius && dist <= outerRadius && grandTot > 0) {
                                            var angle = Math.atan2(dy, dx);
                                            var normAngle = angle + Math.PI / 2;
                                            if (normAngle < 0) normAngle += 2 * Math.PI;

                                            var startAngle = 0;
                                            var foundItem = null;
                                            var foundPct = 0;

                                            for (var i = 0; i < activeList.length; i++) {
                                                var item = activeList[i];
                                                var val = root.getMIDTotal(item);
                                                if (val <= 0) continue;

                                                var sliceAngle = (val / grandTot) * (2 * Math.PI);
                                                var endAngle = startAngle + sliceAngle;

                                                if (normAngle >= startAngle && normAngle <= endAngle) {
                                                    foundItem = item;
                                                    foundPct = (val / grandTot) * 100;
                                                    break;
                                                }
                                                startAngle = endAngle;
                                            }

                                            equalBlock1.hoveredMidItem = foundItem;
                                            equalBlock1.hoveredMidPct = foundPct;
                                        } else {
                                            equalBlock1.hoveredMidItem = null;
                                            equalBlock1.hoveredMidPct = 0;
                                        }
                                    }

                                    onExited: {
                                        equalBlock1.hoveredMidItem = null;
                                        equalBlock1.hoveredMidPct = 0;
                                    }
                                }
                            }

                            // Center Hole Text (Always displays clean Total MID / SubID)
                            Column {
                                anchors.centerIn: parent
                                spacing: 1

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.shareMode === "SubID" ? "총 SubID" : "총 MID"
                                    color: "#8E8E93"
                                    font.pixelSize: 11
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Number(root.getShareGrandTotal()).toLocaleString(Qt.locale("ko_KR"), "f", 0)
                                    color: "#FFFFFF"
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                        }

                        // Far Right Side: Vertically Aligned Color Dot Legends
                        Flickable {
                            id: legendFlickable
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            width: 120
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.topMargin: 4
                            anchors.bottomMargin: 4
                            contentHeight: legendColumn.height
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: legendColumn
                                width: parent.width
                                spacing: 10

                                Repeater {
                                    model: root.activeShareList()

                                    delegate: Row {
                                        spacing: 8
                                        width: parent.width
                                        anchors.left: parent.left
                                        z: legendDotHover.containsMouse ? 20 : 1

                                        Rectangle {
                                            id: legendDot
                                            width: 10
                                            height: 10
                                            radius: 5
                                            z: 10
                                            color: equalBlock1.midPaletteColors[index % equalBlock1.midPaletteColors.length]
                                            anchors.verticalCenter: parent.verticalCenter
                                            scale: legendDotHover.containsMouse ? 1.4 : 1.0

                                            Behavior on color { ColorAnimation { duration: 180 } }
                                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                                            MouseArea {
                                                id: legendDotHover
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    equalBlock1.cycleMidPaletteColor(index)
                                                }
                                            }
                                        }

                                        Text {
                                            text: root.getMIDName(modelData)
                                            color: "#DDDDDD"
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                            width: parent.width - 17
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }

                        // Floating Hover Tooltip Message Box over Donut Slices
                        Rectangle {
                            id: donutTooltip
                            visible: equalBlock1.hoveredMidItem !== null
                            x: Math.min(chartContainer.width - width - 10, Math.max(10, equalBlock1.hoverMouseX + 10))
                            y: Math.min(chartContainer.height - height - 10, Math.max(10, equalBlock1.hoverMouseY - 35))
                            width: Math.max(120, tipCol.width + 20)
                            height: tipCol.height + 12
                            radius: 6
                            color: "#2C2C2C"
                            border.width: 1
                            border.color: "#555555"
                            z: 200

                            Column {
                                id: tipCol
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: equalBlock1.hoveredMidItem ? root.getMIDName(equalBlock1.hoveredMidItem) : ""
                                    color: "#00E5FF"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: equalBlock1.hoveredMidItem ? (equalBlock1.hoveredMidPct.toFixed(1) + "% (" + Number(root.getMIDTotal(equalBlock1.hoveredMidItem)).toLocaleString(Qt.locale("ko_KR"), "f", 0) + ")") : ""
                                    color: "#FFFFFF"
                                    font.pixelSize: 10
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
