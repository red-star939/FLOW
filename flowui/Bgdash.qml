import QtQuick
import QtQuick.Controls

Item {
    id: bgdashRoot
    anchors.fill: parent
    property bool menuVisible: false
    property bool yearsetVisible: false
    property bool categorysetVisible: false
    property bool colorsetVisible: false

    // System Theme Color Properties
    property string themeMainBg: "#141414"
    property string themeDashBg: "#141414"
    property string themeCardBg: "#1F1F1F"
    property string themeIdCardBg: "#1F1F1F"
    property string themeBorderColor: "#343434"
    property string themeTextColor: "#FFFFFF"
    property string themeTitleBadgeBg: "#222222"

    function applyTheme(mainBg, cardBg, borderCol, textCol, badgeBg, dashBg, idCardBg) {
        themeMainBg = mainBg
        themeCardBg = cardBg
        themeBorderColor = borderCol
        themeTextColor = textCol
        themeTitleBadgeBg = badgeBg
        themeDashBg = dashBg ? dashBg : mainBg
        themeIdCardBg = idCardBg ? idCardBg : cardBg
    }

    Component.onCompleted: {
        if (typeof dbController !== "undefined" && typeof dbController.getSavedThemeIndex === "function") {
            var savedThemeIdx = dbController.getSavedThemeIndex();
            if (savedThemeIdx === 1) {
                applyTheme("#578679", "#E0D9CF", "#C2A17B", "#090A0B", "#819E8A", "#578679", "#819E8A");
            } else {
                applyTheme("#141414", "#1F1F1F", "#343434", "#FFFFFF", "#222222", "#141414", "#1F1F1F");
            }
        }
    }

    property var idDataList: (typeof dbController !== "undefined" && typeof yearWheel !== "undefined" && typeof monthSelector !== "undefined")
                             ? dbController.getIDItems(yearWheel.selectedYear, monthSelector.selectedMonth)
                             : []

    // Scroll Position State Persistence Store for ID blocks and SubID lists
    property real lastIdScrollX: 0
    property var subScrollMap: ({})
    property bool isInternalEdit: false

    function setSubScroll(blockUuid, scrollY) {
        if (blockUuid && blockUuid !== "") {
            var map = bgdashRoot.subScrollMap ? bgdashRoot.subScrollMap : {};
            map[blockUuid] = scrollY;
            bgdashRoot.subScrollMap = map;
        }
    }

    function getSubScroll(blockUuid) {
        if (blockUuid && bgdashRoot.subScrollMap && bgdashRoot.subScrollMap[blockUuid] !== undefined) {
            return bgdashRoot.subScrollMap[blockUuid];
        }
        return 0;
    }

    function refreshIDData(isNewBlockAdded) {
        if (typeof dbController !== "undefined" && typeof yearWheel !== "undefined" && typeof monthSelector !== "undefined") {
            var savedContentX = (idBlocksView && idBlocksView.contentX > 0) ? idBlocksView.contentX : bgdashRoot.lastIdScrollX;
            var oldCount = bgdashRoot.idDataList ? bgdashRoot.idDataList.length : 0;

            bgdashRoot.idDataList = dbController.getIDItems(yearWheel.selectedYear, monthSelector.selectedMonth);

            if (idBlocksView) {
                idBlocksView.forceLayout();
                var newCount = bgdashRoot.idDataList ? bgdashRoot.idDataList.length : 0;
                var maxScroll = Math.max(0, idBlocksView.contentWidth - idBlocksView.width);
                var targetX = (isNewBlockAdded || newCount > oldCount) ? maxScroll : Math.max(0, Math.min(maxScroll, savedContentX));
                idBlocksView.targetContentX = targetX;
                idBlocksView.contentX = targetX;
                bgdashRoot.lastIdScrollX = targetX;
            }

            Qt.callLater(function() {
                if (!idBlocksView) return;
                var newCount2 = bgdashRoot.idDataList ? bgdashRoot.idDataList.length : 0;
                var maxScroll2 = Math.max(0, idBlocksView.contentWidth - idBlocksView.width);
                var targetX2 = (isNewBlockAdded || newCount2 > oldCount) ? maxScroll2 : Math.max(0, Math.min(maxScroll2, savedContentX));
                idBlocksView.targetContentX = targetX2;
                idBlocksView.contentX = targetX2;
                bgdashRoot.lastIdScrollX = targetX2;
            });
        }
    }

    property var midDataList: (typeof dbController !== "undefined" && typeof yearWheel !== "undefined")
                              ? dbController.getMIDItems(yearWheel.selectedYear)
                              : []

    function refreshMIDData() {
        if (typeof dbController !== "undefined" && typeof yearWheel !== "undefined") {
            bgdashRoot.midDataList = dbController.getMIDItems(yearWheel.selectedYear)
        }
    }

    Connections {
        target: typeof dbController !== "undefined" ? dbController : null
        function onIdDataChanged(yr, m) {
            if (bgdashRoot.isInternalEdit) return;
            bgdashRoot.refreshIDData()
        }
        function onMidDataChanged(yr) {
            bgdashRoot.refreshMIDData()
        }
        function onYearRangeChanged(sYear, eYear) {
            if (typeof yearWheel !== "undefined") {
                yearWheel.syncYearRange()
            }
            bgdashRoot.refreshIDData()
            bgdashRoot.refreshMIDData()
        }
    }

    // ==========================
    // 기존 Dashboard 영역
    // ==========================
    Item {
        id: mainContent
        anchors.fill: parent
        opacity: (bgdashRoot.menuVisible || bgdashRoot.yearsetVisible) ? 0.85 : 1.0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        // 배경
        Rectangle {
            anchors.fill: parent
            color: bgdashRoot.themeMainBg
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        Column {
            id: dashboardColumn
            anchors {
                fill: parent
                margins: 20
            }

            spacing: 18

            // ==========================
            // 상단 대시보드
            // ==========================
            Rectangle {
                id: topDashboard
                width: parent.width
                height: parent.height * 0.62
                radius: 24
                color: bgdashRoot.themeDashBg
                border.width: 1
                border.color: bgdashRoot.themeBorderColor

                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on border.color { ColorAnimation { duration: 250 } }
                clip: true

                // System Background Automatic Time Synchronization Engine (App Launch One-Time Sync)
                Item {
                    id: systemTimeSyncEngine
                    visible: false

                    function syncSystemTime() {
                        var d = new Date()
                        var sysYear = d.getFullYear()
                        var sysMonth = d.getMonth() + 1

                        if (typeof yearWheel !== "undefined" && yearWheel.selectedYear !== sysYear) {
                            yearWheel.selectedYear = sysYear
                            yearWheel.syncYearRange()
                        }
                        if (typeof monthSelector !== "undefined" && monthSelector.selectedMonth !== sysMonth) {
                            monthSelector.selectedMonth = sysMonth
                        }

                        bgdashRoot.refreshIDData()
                        bgdashRoot.refreshMIDData()
                    }

                    Component.onCompleted: syncSystemTime()
                }

                // 휠 연도 선택기 (Wheeldate - Horizontal 3D Cylinder)
                Wheeldate {
                    id: yearWheel
                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        topMargin: 20
                    }
                    width: 650
                    height: 70

                    onYearChanged: (yr) => {
                        console.log("Selected Year from Wheel:", yr)
                        bgdashRoot.refreshIDData()
                        bgdashRoot.refreshMIDData()
                    }
                }

                // 월 선택 바 (Selectdate - 1~12월 & 합계 선택)
                Selectdate {
                    id: monthSelector
                    anchors {
                        top: yearWheel.bottom
                        topMargin: 12
                        left: parent.left
                        right: parent.right
                    }
                    selectedYear: yearWheel.selectedYear
                    onMonthChanged: (m) => {
                        console.log("Selected Month for Year", yearWheel.selectedYear, ":", m)
                        bgdashRoot.refreshIDData()
                    }
                }

                // MID 블록 목록 (월간 간격 정렬)
                ListView {
                    id: midBlocksView
                    anchors {
                        top: monthSelector.bottom
                        topMargin: 12
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        bottomMargin: 16
                    }
                    clip: true
                    spacing: 8
                    model: bgdashRoot.midDataList

                    delegate: MIDblock {
                        blockIndex: index
                        parentFlickable: midBlocksView
                        uuid: modelData.uuid ? modelData.uuid : ""
                        midName: modelData.mid ? modelData.mid : ""
                        monthsData: modelData.months ? modelData.months : []
                        totalValue: modelData.totalValue !== undefined ? modelData.totalValue : 0.0
                        selectedYear: yearWheel.selectedYear
                        selectedMonth: monthSelector.selectedMonth

                        onRemoveRequested: {
                            if (typeof dbController !== "undefined") {
                                var targetId = modelData.uuid ? modelData.uuid : modelData.mid
                                dbController.removeMIDBlock(yearWheel.selectedYear, targetId)
                                bgdashRoot.refreshMIDData()
                            }
                        }

                        onTitleEdited: (newTitle) => {
                            if (typeof dbController !== "undefined") {
                                var targetId = modelData.uuid ? modelData.uuid : modelData.mid
                                dbController.updateMIDBlockTitle(yearWheel.selectedYear, targetId, newTitle)
                                bgdashRoot.refreshMIDData()
                            }
                        }

                        onMoveRequested: (fromIndex, toIndex) => {
                            var clampedTo = Math.max(0, Math.min(bgdashRoot.midDataList.length - 1, toIndex))
                            if (fromIndex !== clampedTo && typeof dbController !== "undefined") {
                                dbController.moveMIDBlock(yearWheel.selectedYear, fromIndex, clampedTo)
                                bgdashRoot.refreshMIDData()
                            }
                        }

                        onFormulaRequested: (midUuid, midName, buttonItem) => {
                            funcboxDialog.openModal(yearWheel.selectedYear, midUuid, midName, monthSelector.selectedMonth, buttonItem)
                        }
                    }

                    // MID 추가 버튼 (+)
                    footer: Item {
                        width: midBlocksView.width
                        height: 36

                        HoverHandler {
                            id: midAddFooterHover
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            radius: 14
                            color: midAddHover.containsMouse ? "#FFFFFF" : "#3A3A3A"
                            opacity: (midAddFooterHover.hovered || midAddHover.containsMouse) ? 1.0 : 0.0
                            visible: opacity > 0.0

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: midAddHover.containsMouse ? "#202020" : "#CCCCCC"
                                font.pixelSize: 18
                                font.bold: true
                            }

                            MouseArea {
                                id: midAddHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (typeof dbController !== "undefined") {
                                        dbController.addMIDBlock(yearWheel.selectedYear, "MID 블록")
                                        bgdashRoot.refreshMIDData()
                                    }
                                }
                            }
                        }
                    }
                }

                // Hamburger Menu Icon Area (Top-Right of Top Dashboard - Hover Mode)
                Item {
                    width: 60
                    height: 60
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 5
                        rightMargin: 10
                    }

                    HoverHandler {
                        id: menuBtnZoneHover
                    }

                    Rectangle {
                        id: menuBtn
                        width: 38
                        height: 38
                        radius: 19
                        color: menuHover.containsMouse ? "#323232" : "#282828"
                        border.width: 1
                        border.color: menuHover.containsMouse ? "#555555" : "#3A3A3A"
                        anchors.centerIn: parent

                        opacity: (menuBtnZoneHover.hovered || menuHover.containsMouse) ? 1.0 : 0.0
                        visible: opacity > 0.0

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Repeater {
                                model: 3
                                Rectangle {
                                    width: 16
                                    height: 2
                                    radius: 1
                                    color: menuHover.containsMouse ? "#FFFFFF" : "#AAAAAA"

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }
                        }

                        MouseArea {
                            id: menuHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                bgdashRoot.menuVisible = true
                            }
                        }
                    }
                }
            }

            // ==========================
            // 하단 대시보드
            // ==========================
            Rectangle {
                id: bottomDashboard
                width: parent.width
                height: parent.height * 0.38 - 18
                radius: 24
                color: bgdashRoot.themeDashBg
                border.width: 1
                border.color: bgdashRoot.themeBorderColor

                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on border.color { ColorAnimation { duration: 250 } }
                clip: true

                // ID 블록 카드 가로 스크롤 뷰 (Total 모드: monthSelector.selectedMonth == 0 일 때 숨김)
                ListView {
                    id: idBlocksView
                    visible: monthSelector.selectedMonth !== 0
                    anchors {
                        fill: parent
                        margins: 16
                    }
                    orientation: ListView.Horizontal
                    spacing: 16
                    clip: true
                    model: bgdashRoot.idDataList

                    boundsBehavior: Flickable.DragAndOvershootBounds
                    flickDeceleration: 1500
                    maximumFlickVelocity: 3000

                    property real targetContentX: contentX

                    Behavior on targetContentX {
                        id: smoothScrollAnim
                        enabled: !idBlocksView.moving && !idBlocksView.dragging
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutQuad
                        }
                    }

                    onTargetContentXChanged: {
                        if (!idBlocksView.moving && !idBlocksView.dragging) {
                            idBlocksView.contentX = targetContentX;
                        }
                    }

                    onContentXChanged: {
                        if (idBlocksView.moving || idBlocksView.flicking || idBlocksView.dragging) {
                            idBlocksView.targetContentX = idBlocksView.contentX;
                            bgdashRoot.lastIdScrollX = idBlocksView.contentX;
                        }
                    }

                    // Horizontal Mouse Wheel Scroll Handler (iPhone Smooth Inertia Scroll)
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        acceptedButtons: Qt.NoButton
                        onWheel: (wheel) => {
                            var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                            if (delta !== 0) {
                                var maxScroll = Math.max(0, idBlocksView.contentWidth - idBlocksView.width)
                                var step = delta * 1.3
                                var newTarget = Math.max(0, Math.min(maxScroll, idBlocksView.targetContentX - step))
                                idBlocksView.targetContentX = newTarget
                                bgdashRoot.lastIdScrollX = newTarget
                            }
                        }
                    }

                    delegate: IDblock {
                        blockIndex: index
                        uuid: modelData.uuid ? modelData.uuid : ""
                        height: idBlocksView.height
                        selectedYear: yearWheel.selectedYear
                        selectedMonth: monthSelector.selectedMonth
                        idName: modelData.id ? modelData.id : ""
                        totalValue: modelData.totalValue !== undefined ? modelData.totalValue : 0.0
                        subItems: modelData.subItems ? modelData.subItems : []

                        onRemoveRequested: {
                            if (typeof dbController !== "undefined") {
                                var targetId = modelData.uuid ? modelData.uuid : modelData.id
                                dbController.removeIDBlock(yearWheel.selectedYear, monthSelector.selectedMonth, targetId)
                                bgdashRoot.refreshIDData()
                            }
                        }

                        onTitleEdited: (newTitle) => {
                            if (typeof dbController !== "undefined") {
                                var targetId = modelData.uuid ? modelData.uuid : modelData.id
                                dbController.updateIDBlockTitle(yearWheel.selectedYear, monthSelector.selectedMonth, targetId, newTitle)
                                bgdashRoot.refreshIDData()
                            }
                        }

                        onMoveRequested: (fromIndex, toIndex) => {
                            var clampedTo = Math.max(0, Math.min(bgdashRoot.idDataList.length - 1, toIndex))
                            if (fromIndex !== clampedTo && typeof dbController !== "undefined") {
                                dbController.moveIDBlock(yearWheel.selectedYear, monthSelector.selectedMonth, fromIndex, clampedTo)
                                bgdashRoot.refreshIDData()
                            }
                        }
                    }

                    // ID 블록 추가 버튼 (+) 카드 - 합계 모드(monthSelector.selectedMonth == 0)에서는 비활성화
                    footer: Item {
                        visible: monthSelector.selectedMonth !== 0
                        width: visible ? 70 : 0
                        height: idBlocksView.height

                        HoverHandler {
                            id: idAddFooterHover
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 18
                            color: addHover.containsMouse ? "#2C2C2C" : "#1F1F1F"
                            border.width: 1
                            border.color: addHover.containsMouse ? "#555555" : "#343434"
                            opacity: (idAddFooterHover.hovered || addHover.containsMouse) ? 1.0 : 0.0
                            visible: opacity > 0.0

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 34
                                height: 34
                                radius: 17
                                color: addHover.containsMouse ? "#FFFFFF" : "#3A3A3A"

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: addHover.containsMouse ? "#202020" : "#CCCCCC"
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: addHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (typeof dbController !== "undefined") {
                                        dbController.addIDBlock(yearWheel.selectedYear, monthSelector.selectedMonth, "")
                                        bgdashRoot.refreshIDData(true)
                                    }
                                }
                            }
                        }
                    }
                }

                // 합계 선택 시 리포트 블록 3개 표시 (Reportblock.qml) - ListView 바깥 레벨
                Reportblock {
                    id: reportBlock
                    anchors.fill: parent
                    anchors.margins: 12
                    visible: monthSelector.selectedMonth === 0
                    selectedYear: yearWheel.selectedYear
                }
            }
        }
    }

    // Global ESC Key Handler for Menu & Overlay Panels
    Shortcut {
        sequence: "Esc"
        enabled: bgdashRoot.menuVisible || bgdashRoot.yearsetVisible || bgdashRoot.categorysetVisible || bgdashRoot.colorsetVisible
        onActivated: {
            if (bgdashRoot.menuVisible) {
                if (menuPanel.settingsOpen) {
                    menuPanel.settingsOpen = false
                } else {
                    bgdashRoot.menuVisible = false
                }
            } else if (bgdashRoot.yearsetVisible) {
                bgdashRoot.yearsetVisible = false
            } else if (bgdashRoot.categorysetVisible) {
                bgdashRoot.categorysetVisible = false
            } else if (bgdashRoot.colorsetVisible) {
                bgdashRoot.colorsetVisible = false
            }
        }
    }

    // ==========================
    // Menu.qml 연결 부분
    // ==========================
    Appmenu {
        id: menuPanel
        anchors.fill: parent
        visible: bgdashRoot.menuVisible
        opacity: bgdashRoot.menuVisible ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        onCloseRequested: {
            bgdashRoot.menuVisible = false
        }

        onOptionSelected: (option) => {
            if (option === "System Color") {
                bgdashRoot.menuVisible = false
                bgdashRoot.colorsetVisible = true
            } else if (option === "Year Setting") {
                bgdashRoot.menuVisible = false
                bgdashRoot.yearsetVisible = true
            } else if (option === "Category") {
                bgdashRoot.menuVisible = false
                bgdashRoot.categorysetVisible = true
            } else if (option === "Exit") {
                Qt.quit()
            }
        }
    }

    // ==========================
    // Yearset.qml 연결 부분
    // ==========================
    Yearset {
        id: yearsetPanel
        anchors.fill: parent
        visible: bgdashRoot.yearsetVisible
        opacity: bgdashRoot.yearsetVisible ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        onCloseRequested: {
            bgdashRoot.yearsetVisible = false
        }
        onApplied: (startYear, endYear) => {
            yearWheel.startYear = startYear
            yearWheel.endYear = endYear
            yearWheel.syncYearRange()
            bgdashRoot.refreshIDData()
            bgdashRoot.refreshMIDData()
        }
    }

    // ==========================
    // Categoryset.qml 연결 부분
    // ==========================
    Categoryset {
        id: categorysetPanel
        anchors.fill: parent
        visible: bgdashRoot.categorysetVisible
        opacity: bgdashRoot.categorysetVisible ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        onCloseRequested: {
            bgdashRoot.categorysetVisible = false
        }
    }

    // ==========================
    // Colorset.qml 연결 부분
    // ==========================
    Colorset {
        id: colorsetPanel
        anchors.fill: parent
        visible: bgdashRoot.colorsetVisible
        opacity: bgdashRoot.colorsetVisible ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        onThemeSelected: function(mainBg, cardBg, borderCol, textCol, badgeBg, dashBg, idCardBg) {
            bgdashRoot.applyTheme(mainBg, cardBg, borderCol, textCol, badgeBg, dashBg, idCardBg)
        }

        onCloseRequested: {
            bgdashRoot.colorsetVisible = false
        }
    }

    // ==========================
    // Funcbox.qml 수식 모달 연결 부분
    // ==========================
    Funcbox {
        id: funcboxDialog
        onFormulaApplied: {
            bgdashRoot.refreshMIDData()
        }
    }
}