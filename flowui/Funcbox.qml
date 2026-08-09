import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

Item {
    id: root

    property bool isOpen: false
    property bool isAdvancedMode: false // false = 간편 모드, true = 고급 모드

    // Simple Mode State
    property string simpleBlock1Item: ""
    property string simpleBlock2Item: ""
    property string simpleOp: ""
    property bool isSelectingBlock1: false
    property bool isSelectingBlock2: false

    // ESC Key Shortcut to Close Formula Modal
    Shortcut {
        sequence: "Esc"
        enabled: root.isOpen
        onActivated: {
            root.isOpen = false
        }
    }
    property int selectedYear: 2026
    property string targetMidUuid: ""
    property string targetMidName: ""
    property int targetMonth: 0 // 0 = 전체 월 동시 적용, 1~12 = 개별 월

    property real popoverX: 100
    property real popoverY: 100
    property real tailX: 300
    property bool tailOnTop: true

    property string selectedOp: "+"

    property var operatorDocs: ({
        "+": { name: "+ (더하기)", category: "산술 연산자", desc: "두 값을 더합니다.", example: "예시: 매출 + 지원금  🡲  1,000 + 500 = 1,500" },
        "-": { name: "- (빼기)", category: "산술 연산자", desc: "왼쪽 값에서 오른쪽 값을 땁니다.", example: "예시: 매출 - 원가  🡲  1,000 - 300 = 700" },
        "*": { name: "* (곱하기)", category: "산술 연산자", desc: "두 값을 곱합니다.", example: "예시: 수량 * 단가  🡲  10 * 50 = 500" },
        "/": { name: "/ (나누기)", category: "산술 연산자", desc: "왼쪽 값을 오른쪽 값으로 나눕니다.", example: "예시: 총액 / 인원수  🡲  1,000 / 4 = 250" },
        "$": { name: "$ (고정/참조)", category: "산술 연산자", desc: "셀 또는 기준값을 고정 참조합니다.", example: "예시: $기본급 + 수당  🡲  $5,000 + 200 = 5,200" },
        "%": { name: "% (백분율)", category: "산술 연산자", desc: "백분율(비율)을 계산합니다.", example: "예시: 매출 * 10%  🡲  1,000 * 0.1 = 100" },
        "^": { name: "^ (거듭제곱)", category: "산술 연산자", desc: "왼쪽 값의 승수를 계산합니다.", example: "예시: 1.05 ^ 2  🡲  1.05의 2승 = 1.1025" },

        "=": { name: "= (같음)", category: "비교 연산자", desc: "두 값이 같은지 비교합니다 (참: 1, 거짓: 0).", example: "예시: 목표 = 달성액  🡲  1,000 = 1,000 (참: 1)" },
        "!=": { name: "!= (같지 않음)", category: "비교 연산자", desc: "두 값이 다른지 비교합니다.", example: "예시: 재고 != 0  🡲  5 != 0 (참: 1)" },
        "<": { name: "< (작음)", category: "비교 연산자", desc: "왼쪽이 오른쪽보다 작은지 비교합니다.", example: "예시: 지출 < 예산  🡲  800 < 1,000 (참: 1)" },
        "<=": { name: "<= (작거나 같음)", category: "비교 연산자", desc: "왼쪽이 오른쪽보다 작거나 같은지 비교합니다.", example: "예시: 연체일 <= 30  🡲  15 <= 30 (참: 1)" },
        ">": { name: "> (큼)", category: "비교 연산자", desc: "왼쪽이 오른쪽보다 큰지 비교합니다.", example: "예시: 매출 > 목표  🡲  1,200 > 1,000 (참: 1)" },
        ">=": { name: ">= (크거나 같음)", category: "비교 연산자", desc: "왼쪽이 오른쪽보다 크거나 같은지 비교합니다.", example: "예시: 점수 >= 80  🡲  85 >= 80 (참: 1)" },

        "(": { name: "( (여는 괄호)", category: "구분자 및 특수 기호", desc: "우선순위 연산을 위한 괄호를 시작합니다.", example: "예시: (매출 - 원가) * 0.1  🡲  (1,000 - 400) * 0.1 = 60" },
        ")": { name: ") (닫는 괄호)", category: "구분자 및 특수 기호", desc: "우선순위 연산 괄호를 닫습니다.", example: "예시: (A + B) / C" },
        ",": { name: ", (쉼표)", category: "구분자 및 특수 기호", desc: "함수의 인자를 구분합니다.", example: "예시: SUM(A, B, C)" },
        ":": { name: ": (콜론)", category: "구분자 및 특수 기호", desc: "범위를 지정하는 구분자입니다.", example: "예시: SUM(블록1 : 블록5)" }
    })

    signal formulaApplied()
    signal closed()

    anchors.fill: parent
    visible: isOpen
    z: 2000

    property var referenceBlocks: []
    property var formulaTokens: []

    function getFormulaTokens() {
        var raw = formulaInput.text.trim()
        if (!raw) return []
        var tokens = []
        var current = ""
        for (var i = 0; i < raw.length; i++) {
            var ch = raw[i]
            if (ch === '+' || ch === '-' || ch === '*' || ch === '/' || ch === '(' || ch === ')' || ch === '%' || ch === '^') {
                if (current.trim()) tokens.push(current.trim())
                tokens.push(ch)
                current = ""
            } else if (ch === ' ') {
                if (current.trim()) {
                    tokens.push(current.trim())
                    current = ""
                }
            } else {
                current += ch
            }
        }
        if (current.trim()) tokens.push(current.trim())
        return tokens
    }

    function syncSimpleModeFromText() {
        var tokens = getFormulaTokens()
        if (tokens.length >= 3) {
            simpleBlock1Item = tokens[0]
            if (tokens[1] === "+" || tokens[1] === "-") {
                simpleOp = tokens[1]
            } else {
                simpleOp = ""
            }
            simpleBlock2Item = tokens[tokens.length - 1]
        } else if (tokens.length === 1) {
            simpleBlock1Item = tokens[0]
            simpleOp = ""
            simpleBlock2Item = ""
        } else {
            simpleBlock1Item = ""
            simpleOp = ""
            simpleBlock2Item = ""
        }
        isSelectingBlock1 = false
        isSelectingBlock2 = false
    }

    function updateSimpleFormulaText() {
        var opStr = simpleOp !== "" ? (" " + simpleOp + " ") : " "
        if (simpleBlock1Item !== "" && simpleBlock2Item !== "") {
            formulaInput.text = simpleBlock1Item + opStr + simpleBlock2Item
        } else if (simpleBlock1Item !== "") {
            formulaInput.text = simpleBlock1Item
        } else if (simpleBlock2Item !== "") {
            formulaInput.text = simpleBlock2Item
        } else {
            formulaInput.text = ""
        }
        updateTokensFromText()
    }

    function updateTokensFromText() {
        formulaTokens = getFormulaTokens()
    }

    function removeTokenAt(idx) {
        var tokens = getFormulaTokens()
        if (idx >= 0 && idx < tokens.length) {
            tokens.splice(idx, 1)
            formulaInput.text = tokens.join(" ")
            updateTokensFromText()
        }
    }

    function refreshReferenceBlocks() {
        var list = ["당일지출"]
        if (typeof dbController !== "undefined") {
            var mids = dbController.getMIDItems(selectedYear)
            if (mids) {
                for (var i = 0; i < mids.length; i++) {
                    if (mids[i].name) list.push(mids[i].name)
                }
            }
            var m = targetMonth === 0 ? 1 : targetMonth
            var ids = dbController.getIDItems(selectedYear, m)
            if (ids) {
                for (var j = 0; j < ids.length; j++) {
                    if (ids[j].id) {
                        list.push(ids[j].id)
                        if (ids[j].subItems && ids[j].subItems.length > 0) {
                            for (var k = 0; k < ids[j].subItems.length; k++) {
                                var sName = ids[j].subItems[k].title ? ids[j].subItems[k].title : ids[j].subItems[k].subId
                                if (sName) list.push(sName)
                            }
                        }
                    }
                }
            }
        }
        referenceBlocks = list
    }

    function updateFormulaInputText() {
        if (typeof dbController !== "undefined" && root.targetMidUuid !== "") {
            var m = root.targetMonth === 0 ? 1 : root.targetMonth
            var existing = dbController.getMIDMonthFormula(root.selectedYear, root.targetMidUuid, m)
            formulaInput.text = existing ? existing : ""
            updateTokensFromText()
            syncSimpleModeFromText()
        }
        refreshReferenceBlocks()
    }

    onTargetMonthChanged: {
        updateFormulaInputText()
    }

    function openModal(year, midUuid, midName, currentMonth, buttonItem) {
        selectedYear = year
        targetMidUuid = midUuid
        targetMidName = midName
        targetMonth = currentMonth !== undefined ? currentMonth : 0
        selectedOp = "+"
        isAdvancedMode = false // Default to Simple Mode as requested
        updateFormulaInputText()
        refreshReferenceBlocks()

        if (buttonItem && typeof buttonItem.mapToItem === "function") {
            var globalPos = buttonItem.mapToItem(root, 0, 0)
            var btnCenterX = globalPos.x + buttonItem.width / 2
            var btnCenterY = globalPos.y + buttonItem.height / 2

            var cardW = popoverCard.width
            var cardH = popoverCard.height

            var prefX = btnCenterX - cardW + 40
            popoverX = Math.max(16, Math.min(root.width - cardW - 16, prefX))

            if (btnCenterY + cardH + 20 <= root.height) {
                popoverY = btnCenterY + 16
                tailOnTop = true
            } else {
                popoverY = Math.max(16, btnCenterY - cardH - 16)
                tailOnTop = false
            }

            tailX = Math.max(24, Math.min(cardW - 24, btnCenterX - popoverX))
        } else {
            popoverX = (root.width - popoverCard.width) / 2
            popoverY = (root.height - popoverCard.height) / 2
            tailX = popoverCard.width / 2
            tailOnTop = true
        }

        isOpen = true
    }

    function closeModal() {
        isOpen = false
        closed()
    }

    function applyFormula() {
        if (!root.isOpen) return
        var expr = formulaInput.text.trim()
        if (typeof dbController !== "undefined" && root.targetMidUuid !== "") {
            if (root.targetMonth === 0) {
                for (var m = 1; m <= 12; m++) {
                    dbController.setMIDMonthFormula(root.selectedYear, root.targetMidUuid, m, expr)
                }
            } else {
                dbController.setMIDMonthFormula(root.selectedYear, root.targetMidUuid, root.targetMonth, expr)
            }
            root.formulaApplied()
            root.closeModal()
        }
    }

    function insertSymbol(sym) {
        var current = formulaInput.text
        if (current.length > 0 && !current.endsWith(" ")) {
            current += " "
        }
        formulaInput.text = current + sym + " "
        updateTokensFromText()
    }

    // Backdrop overlay (transparent, click outside to apply & close)
    Rectangle {
        anchors.fill: parent
        color: "#15000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.applyFormula()
        }
    }

    // ─── Speech Bubble Popover Container ───
    Item {
        id: popoverWrapper
        x: root.popoverX
        y: root.popoverY
        width: popoverCard.width
        height: popoverCard.height

        scale: root.isOpen ? 1.0 : 0.85
        opacity: root.isOpen ? 1.0 : 0.0

        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        // Main Popover Card
        Rectangle {
            id: popoverCard
            width: 560
            height: 560
            radius: 18
            color: "#1F1F1F"
            border.width: 1.5
            border.color: "#343434"
            z: 1

            MouseArea {
                anchors.fill: parent
                onClicked: {} // Prevent click-through
            }

            // Header Section
            Rectangle {
                id: headerArea
                width: parent.width
                height: 52
                radius: 18
                color: "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    // f Icon Circle
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: "#FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "f"
                            color: "#121212"
                            font.pixelSize: 16
                            font.bold: true
                            font.italic: true
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: "수식 설정 (" + (root.isAdvancedMode ? "고급 모드" : "간편 모드") + ")"
                            color: "#FFFFFF"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            text: root.targetMidName + " (" + root.selectedYear + "년)"
                            color: "#8E8E93"
                            font.pixelSize: 12
                        }
                    }
                }

                // iOS-Style Segmented Mode Switch (간편 모드 | 고급 모드)
                Rectangle {
                    id: modeToggleSwitch
                    anchors {
                        right: closeBtn.left
                        rightMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    width: 136
                    height: 28
                    radius: 14
                    color: "#2C2C2E"
                    border.width: 1
                    border.color: "#3A3A3C"

                    // Sliding Pill Thumb
                    Rectangle {
                        x: root.isAdvancedMode ? 67 : 2
                        y: 2
                        width: 67
                        height: 24
                        radius: 12
                        color: "#FFFFFF"

                        Behavior on x {
                            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        Item {
                            width: 68
                            height: 28
                            Text {
                                anchors.centerIn: parent
                                text: "간편 모드"
                                font.pixelSize: 11
                                font.bold: true
                                color: !root.isAdvancedMode ? "#121212" : "#8E8E93"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.isAdvancedMode = false
                            }
                        }
                        Item {
                            width: 68
                            height: 28
                            Text {
                                anchors.centerIn: parent
                                text: "고급 모드"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.isAdvancedMode ? "#121212" : "#8E8E93"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.isAdvancedMode = true
                            }
                        }
                    }
                }

                // Close Button (×)
                Rectangle {
                    id: closeBtn
                    width: 30
                    height: 30
                    radius: 15
                    color: closeHover.containsMouse ? "#FFFFFF" : "#3A3A3A"
                    border.width: 1
                    border.color: closeHover.containsMouse ? "#FFFFFF" : "#4A4A4A"
                    scale: closeHover.containsMouse ? 1.08 : 1.0

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                    anchors {
                        right: parent.right
                        rightMargin: 16
                        verticalCenter: parent.verticalCenter
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: closeHover.containsMouse ? "#121212" : "#DDDDDD"
                        font.pixelSize: 16
                        font.bold: true

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeModal()
                    }
                }
            }

            // Divider Line
            Rectangle {
                id: headerDivider
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: headerArea.bottom
                height: 1
                color: "#343434"
            }

            // Hidden Shared Text Field for formula persistence
            TextField {
                id: formulaInput
                visible: false
                onTextChanged: root.updateTokensFromText()
            }

            // ─── SIMPLE MODE CONTAINER (간편 모드) ───
            Item {
                id: simpleModeContainer
                anchors {
                    top: headerDivider.bottom
                    topMargin: 16
                    left: parent.left
                    leftMargin: 18
                    right: parent.right
                    rightMargin: 18
                    bottom: parent.bottom
                    bottomMargin: 16
                }
                visible: !root.isAdvancedMode

                Column {
                    anchors.fill: parent
                    spacing: 14

                    // 1. Center Row containing Block 1, Circle, Block 2
                    Item {
                        width: parent.width
                        height: 250

                        Row {
                            anchors.centerIn: parent
                            spacing: 16

                            // Block 1 (Left Block with Dashed Border)
                            Rectangle {
                                id: simpleBlock1
                                width: 210
                                height: 250
                                radius: 16
                                color: block1Hover.containsMouse ? "#222224" : "#18181A"

                                Behavior on color { ColorAnimation { duration: 180 } }

                                // Top-Right Clear Button (×)
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: b1ClearHover.containsMouse ? "#FF5F57" : "#333336"
                                    visible: root.simpleBlock1Item !== "" || root.isSelectingBlock1
                                    z: 20
                                    anchors {
                                        top: parent.top
                                        topMargin: 8
                                        right: parent.right
                                        rightMargin: 8
                                    }

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: b1ClearHover.containsMouse ? "#FFFFFF" : "#AAAAAA"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: b1ClearHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.simpleBlock1Item = ""
                                            root.isSelectingBlock1 = false
                                            root.updateSimpleFormulaText()
                                        }
                                    }
                                }

                                // Dashed Border Shape (Dashed Line when unselected)
                                Shape {
                                    id: block1DashedShape
                                    anchors.fill: parent
                                    visible: root.simpleBlock1Item === "" && !root.isSelectingBlock1
                                    ShapePath {
                                        strokeColor: block1Hover.containsMouse ? "#FFFFFF" : "#555558"
                                        strokeWidth: 1.5
                                        fillColor: "transparent"
                                        strokeStyle: ShapePath.DashLine
                                        dashPattern: [5, 4]
                                        PathRectangle {
                                            x: 1
                                            y: 1
                                            width: simpleBlock1.width - 2
                                            height: simpleBlock1.height - 2
                                            radius: 16
                                        }
                                    }
                                }

                                // Solid Border when selected or selecting
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 16
                                    color: "transparent"
                                    border.width: 1.5
                                    border.color: root.isSelectingBlock1 ? "#00E5FF" : (root.simpleBlock1Item !== "" ? "#FFFFFF" : "#343434")
                                    visible: root.simpleBlock1Item !== "" || root.isSelectingBlock1
                                }

                                // State A: Unselected empty state
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 12
                                    visible: root.simpleBlock1Item === "" && !root.isSelectingBlock1

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 44
                                        height: 44
                                        radius: 22
                                        color: block1Hover.containsMouse ? "#FFFFFF" : "#2A2A2D"

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "+"
                                            color: block1Hover.containsMouse ? "#121212" : "#CCCCCC"
                                            font.pixelSize: 22
                                            font.bold: true

                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: block1Hover.containsMouse ? "블록 설정하기" : "MID / ID 블록 설정 1"
                                        color: block1Hover.containsMouse ? "#FFFFFF" : "#888888"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                }

                                // State B: Selection Menu Mode
                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    visible: root.isSelectingBlock1

                                    Column {
                                        anchors.fill: parent
                                        spacing: 6

                                        Text {
                                            text: "블록 1 선택"
                                            color: "#8E8E93"
                                            font.pixelSize: 11
                                            font.bold: true
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }

                                        Flickable {
                                            width: parent.width
                                            height: parent.height - 24
                                            contentHeight: b1SelCol.height
                                            clip: true

                                            Column {
                                                id: b1SelCol
                                                width: parent.width
                                                spacing: 4

                                                Repeater {
                                                    model: root.referenceBlocks
                                                    delegate: Rectangle {
                                                        width: parent.width
                                                        height: 28
                                                        radius: 6
                                                        color: b1OptHover.containsMouse ? "#FFFFFF" : "#252528"

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: modelData === "당일지출" ? "💳 " + modelData : "🏷️ " + modelData
                                                            color: b1OptHover.containsMouse ? "#121212" : "#DDDDDD"
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            elide: Text.ElideRight
                                                            width: parent.width - 8
                                                            horizontalAlignment: Text.AlignHCenter
                                                        }

                                                        MouseArea {
                                                            id: b1OptHover
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                root.simpleBlock1Item = modelData
                                                                root.isSelectingBlock1 = false
                                                                root.updateSimpleFormulaText()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // State C: Selected item state
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 10
                                    visible: root.simpleBlock1Item !== "" && !root.isSelectingBlock1

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "설정된 블록 1"
                                        color: "#8E8E93"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.simpleBlock1Item === "당일지출" ? "💳 " + root.simpleBlock1Item : "🏷️ " + root.simpleBlock1Item
                                        color: "#FFFFFF"
                                        font.pixelSize: 16
                                        font.bold: true
                                        elide: Text.ElideRight
                                        width: simpleBlock1.width - 24
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 60
                                        height: 22
                                        radius: 11
                                        color: b1ChgHover.containsMouse ? "#FFFFFF" : "#2C2C2E"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "변경"
                                            color: b1ChgHover.containsMouse ? "#121212" : "#AAAAAA"
                                            font.pixelSize: 10
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: b1ChgHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.isSelectingBlock1 = true
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: block1Hover
                                    anchors.fill: parent
                                    enabled: !root.isSelectingBlock1
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.isSelectingBlock1 = true
                                        root.isSelectingBlock2 = false
                                    }
                                }
                            }

                            // Circle between Block 1 and Block 2 (Dashed when empty, Solid when set)
                            Rectangle {
                                id: centerCircle
                                width: 46
                                height: 46
                                radius: 23
                                color: circleHover.containsMouse ? "#3A3A3D" : "#222225"
                                border.width: root.simpleOp !== "" ? 1.5 : 0
                                border.color: circleHover.containsMouse ? "#FFFFFF" : "#AAAAAA"
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                // Dashed Border Shape (visible when simpleOp is empty)
                                Shape {
                                    anchors.fill: parent
                                    visible: root.simpleOp === ""
                                    ShapePath {
                                        strokeColor: circleHover.containsMouse ? "#FFFFFF" : "#66666B"
                                        strokeWidth: 1.5
                                        fillColor: "transparent"
                                        strokeStyle: ShapePath.DashLine
                                        dashPattern: [4, 4]
                                        PathAngleArc {
                                            centerX: 23
                                            centerY: 23
                                            radiusX: 21
                                            radiusY: 21
                                            startAngle: 0
                                            sweepAngle: 360
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.simpleOp
                                    color: "#FFFFFF"
                                    font.pixelSize: 20
                                    font.bold: true
                                }

                                MouseArea {
                                    id: circleHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.simpleOp === "+") root.simpleOp = "-"
                                        else if (root.simpleOp === "-") root.simpleOp = ""
                                        else root.simpleOp = "+"
                                        root.updateSimpleFormulaText()
                                    }
                                }
                            }

                            // Block 2 (Right Block with Dashed Border)
                            Rectangle {
                                id: simpleBlock2
                                width: 210
                                height: 250
                                radius: 16
                                color: block2Hover.containsMouse ? "#222224" : "#18181A"

                                Behavior on color { ColorAnimation { duration: 180 } }

                                // Top-Right Clear Button (×)
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: b2ClearHover.containsMouse ? "#FF5F57" : "#333336"
                                    visible: root.simpleBlock2Item !== "" || root.isSelectingBlock2
                                    z: 20
                                    anchors {
                                        top: parent.top
                                        topMargin: 8
                                        right: parent.right
                                        rightMargin: 8
                                    }

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: b2ClearHover.containsMouse ? "#FFFFFF" : "#AAAAAA"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: b2ClearHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.simpleBlock2Item = ""
                                            root.isSelectingBlock2 = false
                                            root.updateSimpleFormulaText()
                                        }
                                    }
                                }

                                // Dashed Border Shape (Dashed Line when unselected)
                                Shape {
                                    id: block2DashedShape
                                    anchors.fill: parent
                                    visible: root.simpleBlock2Item === "" && !root.isSelectingBlock2
                                    ShapePath {
                                        strokeColor: block2Hover.containsMouse ? "#FFFFFF" : "#555558"
                                        strokeWidth: 1.5
                                        fillColor: "transparent"
                                        strokeStyle: ShapePath.DashLine
                                        dashPattern: [5, 4]
                                        PathRectangle {
                                            x: 1
                                            y: 1
                                            width: simpleBlock2.width - 2
                                            height: simpleBlock2.height - 2
                                            radius: 16
                                        }
                                    }
                                }

                                // Solid Border when selected or selecting
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 16
                                    color: "transparent"
                                    border.width: 1.5
                                    border.color: root.isSelectingBlock2 ? "#00E5FF" : (root.simpleBlock2Item !== "" ? "#FFFFFF" : "#343434")
                                    visible: root.simpleBlock2Item !== "" || root.isSelectingBlock2
                                }

                                // State A: Unselected empty state
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 12
                                    visible: root.simpleBlock2Item === "" && !root.isSelectingBlock2

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 44
                                        height: 44
                                        radius: 22
                                        color: block2Hover.containsMouse ? "#FFFFFF" : "#2A2A2D"

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "+"
                                            color: block2Hover.containsMouse ? "#121212" : "#CCCCCC"
                                            font.pixelSize: 22
                                            font.bold: true

                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: block2Hover.containsMouse ? "블록 설정하기" : "MID / ID 블록 설정 2"
                                        color: block2Hover.containsMouse ? "#FFFFFF" : "#888888"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                }

                                // State B: Selection Menu Mode
                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    visible: root.isSelectingBlock2

                                    Column {
                                        anchors.fill: parent
                                        spacing: 6

                                        Text {
                                            text: "블록 2 선택"
                                            color: "#8E8E93"
                                            font.pixelSize: 11
                                            font.bold: true
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }

                                        Flickable {
                                            width: parent.width
                                            height: parent.height - 24
                                            contentHeight: b2SelCol.height
                                            clip: true

                                            Column {
                                                id: b2SelCol
                                                width: parent.width
                                                spacing: 4

                                                Repeater {
                                                    model: root.referenceBlocks
                                                    delegate: Rectangle {
                                                        width: parent.width
                                                        height: 28
                                                        radius: 6
                                                        color: b2OptHover.containsMouse ? "#FFFFFF" : "#252528"

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: modelData === "당일지출" ? "💳 " + modelData : "🏷️ " + modelData
                                                            color: b2OptHover.containsMouse ? "#121212" : "#DDDDDD"
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            elide: Text.ElideRight
                                                            width: parent.width - 8
                                                            horizontalAlignment: Text.AlignHCenter
                                                        }

                                                        MouseArea {
                                                            id: b2OptHover
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                root.simpleBlock2Item = modelData
                                                                root.isSelectingBlock2 = false
                                                                root.updateSimpleFormulaText()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // State C: Selected item state
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 10
                                    visible: root.simpleBlock2Item !== "" && !root.isSelectingBlock2

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "설정된 블록 2"
                                        color: "#8E8E93"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.simpleBlock2Item === "당일지출" ? "💳 " + root.simpleBlock2Item : "🏷️ " + root.simpleBlock2Item
                                        color: "#FFFFFF"
                                        font.pixelSize: 16
                                        font.bold: true
                                        elide: Text.ElideRight
                                        width: simpleBlock2.width - 24
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 60
                                        height: 22
                                        radius: 11
                                        color: b2ChgHover.containsMouse ? "#FFFFFF" : "#2C2C2E"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "변경"
                                            color: b2ChgHover.containsMouse ? "#121212" : "#AAAAAA"
                                            font.pixelSize: 10
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: b2ChgHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.isSelectingBlock2 = true
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: block2Hover
                                    anchors.fill: parent
                                    enabled: !root.isSelectingBlock2
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.isSelectingBlock2 = true
                                        root.isSelectingBlock1 = false
                                    }
                                }
                            }
                        }
                    }

                    // 2. Target Month Selector Row
                    Text {
                        text: "수식 적용 대상 월"
                        color: "#CCCCCC"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Flickable {
                        width: parent.width
                        height: 32
                        contentWidth: sMonthRow.width
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Row {
                            id: sMonthRow
                            spacing: 6

                            Rectangle {
                                width: 52
                                height: 28
                                radius: 14
                                color: root.targetMonth === 0 ? "#FFFFFF" : "#2C2C2C"
                                border.width: 1
                                border.color: root.targetMonth === 0 ? "#FFFFFF" : "#3D3D3D"

                                Text {
                                    anchors.centerIn: parent
                                    text: "전체 월"
                                    color: root.targetMonth === 0 ? "#121212" : "#AAAAAA"
                                    font.pixelSize: 11
                                    font.bold: root.targetMonth === 0
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.targetMonth = 0
                                }
                            }

                            Repeater {
                                model: 12
                                delegate: Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: root.targetMonth === index + 1 ? "#FFFFFF" : "#2C2C2C"
                                    border.width: 1
                                    border.color: root.targetMonth === index + 1 ? "#FFFFFF" : "#3D3D3D"

                                    Text {
                                        anchors.centerIn: parent
                                        text: (index + 1).toString()
                                        color: root.targetMonth === index + 1 ? "#121212" : "#AAAAAA"
                                        font.pixelSize: 12
                                        font.bold: root.targetMonth === index + 1
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.targetMonth = index + 1
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 6 }

                    // 3. Action Buttons (Clear, Apply)
                    Row {
                        anchors.right: parent.right
                        spacing: 10

                        Rectangle {
                            width: 90
                            height: 36
                            radius: 10
                            color: sClearHover.containsMouse ? "#3A2A2A" : "#2A1A1A"
                            border.width: 1
                            border.color: "#FF5F57"

                            Text {
                                anchors.centerIn: parent
                                text: "수식 삭제"
                                color: "#FF5F57"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                id: sClearHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    formulaInput.text = ""
                                    root.simpleBlock1Item = ""
                                    root.simpleBlock2Item = ""
                                    root.simpleOp = ""
                                    root.updateTokensFromText()
                                    root.applyFormula()
                                }
                            }
                        }

                        Rectangle {
                            width: 110
                            height: 36
                            radius: 10
                            color: sApplyHover.containsMouse ? "#E0E0E0" : "#FFFFFF"

                            Text {
                                anchors.centerIn: parent
                                text: "수식 적용"
                                color: "#121212"
                                font.pixelSize: 13
                                font.bold: true
                            }

                            MouseArea {
                                id: sApplyHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.applyFormula()
                            }
                        }
                    }
                }
            }

            // ─── ADVANCED MODE CONTAINER (고급 모드) ───
            Item {
                id: advancedModeContainer
                anchors {
                    top: headerDivider.bottom
                    topMargin: 14
                    left: parent.left
                    leftMargin: 18
                    right: parent.right
                    rightMargin: 18
                    bottom: parent.bottom
                    bottomMargin: 16
                }
                visible: root.isAdvancedMode

                Column {
                    anchors.fill: parent
                    spacing: 10

                    // 1. 수식 구문 입력 (TOP)
                    Text {
                        text: "수식 구문 입력"
                        color: "#CCCCCC"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Rectangle {
                        width: parent.width
                        height: 38
                        radius: 8
                        color: "#1F1F1F"
                        border.width: 1.5
                        border.color: "#343434"

                        TextField {
                            id: formulaInputAdv
                            anchors.fill: parent
                            anchors.margins: 4
                            verticalAlignment: TextInput.AlignVCenter
                            text: formulaInput.text
                            onTextChanged: {
                                if (formulaInput.text !== text) {
                                    formulaInput.text = text
                                }
                            }

                            color: "#FFFFFF"
                            font.pixelSize: 14
                            placeholderText: "예: ID 블록 1 - ID 블록 2"
                            placeholderTextColor: "#555555"

                            selectByMouse: true
                            selectedTextColor: "#121212"
                            selectionColor: "#FFFFFF"

                            onAccepted: root.applyFormula()
                            onEditingFinished: {
                                if (root.isOpen) root.applyFormula()
                            }

                            Keys.onReturnPressed: root.applyFormula()
                            Keys.onEnterPressed: root.applyFormula()

                            background: Rectangle {
                                color: "transparent"
                            }
                        }
                    }

                    // 2. 사용 가능한 기호 & 연산자 (White Active Theme)
                    Rectangle {
                        width: parent.width
                        height: 124
                        radius: 10
                        color: "#1F1F1F"
                        border.width: 1.5
                        border.color: "#343434"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            // Row 1: 산술 연산자
                            Row {
                                spacing: 6
                                Text {
                                    text: "산술 연산자:"
                                    color: "#CCCCCC"
                                    font.pixelSize: 11
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 72
                                }
                                Repeater {
                                    model: ["+", "-", "*", "/", "$", "%", "^"]
                                    delegate: Rectangle {
                                        width: 26
                                        height: 24
                                        radius: 6
                                        color: root.selectedOp === modelData ? "#FFFFFF" : (opHover.containsMouse ? "#3A3A3A" : "#282828")
                                        border.width: 1
                                        border.color: root.selectedOp === modelData ? "#FFFFFF" : "#404040"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: root.selectedOp === modelData ? "#121212" : "#CCCCCC"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: opHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedOp = modelData
                                            onDoubleClicked: root.insertSymbol(modelData)
                                        }
                                    }
                                }
                            }

                            // Row 2: 비교 연산자
                            Row {
                                spacing: 6
                                Text {
                                    text: "비교 연산자:"
                                    color: "#CCCCCC"
                                    font.pixelSize: 11
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 72
                                }
                                Repeater {
                                    model: ["=", "!=", "<", "<=", ">", ">="]
                                    delegate: Rectangle {
                                        width: modelData.length > 1 ? 32 : 26
                                        height: 24
                                        radius: 6
                                        color: root.selectedOp === modelData ? "#FFFFFF" : (opHover2.containsMouse ? "#3A3A3A" : "#282828")
                                        border.width: 1
                                        border.color: root.selectedOp === modelData ? "#FFFFFF" : "#404040"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: root.selectedOp === modelData ? "#121212" : "#CCCCCC"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: opHover2
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedOp = modelData
                                            onDoubleClicked: root.insertSymbol(modelData)
                                        }
                                    }
                                }
                            }

                            // Row 3: 구분자 및 기호
                            Row {
                                spacing: 6
                                Text {
                                    text: "구분자/기호:"
                                    color: "#CCCCCC"
                                    font.pixelSize: 11
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 72
                                }
                                Repeater {
                                    model: ["(", ")", ",", ":"]
                                    delegate: Rectangle {
                                        width: 26
                                        height: 24
                                        radius: 6
                                        color: root.selectedOp === modelData ? "#FFFFFF" : (opHover3.containsMouse ? "#3A3A3A" : "#282828")
                                        border.width: 1
                                        border.color: root.selectedOp === modelData ? "#FFFFFF" : "#404040"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: root.selectedOp === modelData ? "#121212" : "#CCCCCC"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: opHover3
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedOp = modelData
                                            onDoubleClicked: root.insertSymbol(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 3. 선택된 기호 설명 및 사용법 예시 카드
                    Rectangle {
                        id: explanationCard
                        width: parent.width
                        height: 82
                        radius: 10
                        color: "#1F1F1F"
                        border.width: 1.5
                        border.color: "#343434"

                        property var currentDoc: root.operatorDocs[root.selectedOp] ? root.operatorDocs[root.selectedOp] : root.operatorDocs["+"]

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            Item {
                                width: parent.width
                                height: 20

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: explanationCard.currentDoc.name
                                    color: "#FFFFFF"
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 76
                                    height: 20
                                    radius: 10
                                    color: addSymHover.containsMouse ? "#FFFFFF" : "#3A3A3A"
                                    border.width: 1
                                    border.color: addSymHover.containsMouse ? "#FFFFFF" : "#666666"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+ 수식에 추가"
                                        color: addSymHover.containsMouse ? "#121212" : "#FFFFFF"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: addSymHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.insertSymbol(root.selectedOp)
                                    }
                                }
                            }

                            Text {
                                text: explanationCard.currentDoc.desc
                                color: "#DDDDDD"
                                font.pixelSize: 11
                            }

                            Text {
                                text: explanationCard.currentDoc.example
                                color: "#FFD54F"
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }

                    // 4. 사용 가능한 참조 항목 (ID / MID / 당일지출)
                    Text {
                        text: "사용 가능한 참조 항목 (클릭 시 수식에 자동 삽입)"
                        color: "#CCCCCC"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Flickable {
                        id: refFlickable
                        width: parent.width
                        height: 32
                        contentWidth: refRow.width
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        MouseArea {
                            anchors.fill: parent
                            onWheel: (wheel) => {
                                var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                                refFlickable.contentX = Math.max(0, Math.min(refFlickable.contentWidth - refFlickable.width, refFlickable.contentX - delta))
                            }
                        }

                        Row {
                            id: refRow
                            spacing: 6

                            Repeater {
                                model: root.referenceBlocks
                                delegate: Rectangle {
                                    height: 28
                                    width: refText.implicitWidth + 18
                                    radius: 14
                                    color: refHover.containsMouse ? "#FFFFFF" : "#282828"
                                    border.width: 1
                                    border.color: refHover.containsMouse ? "#FFFFFF" : "#404040"

                                    Text {
                                        id: refText
                                        anchors.centerIn: parent
                                        text: modelData === "당일지출" ? "💳 " + modelData : "🏷️ " + modelData
                                        color: refHover.containsMouse ? "#121212" : "#CCCCCC"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: refHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.insertSymbol(modelData)
                                        onWheel: (wheel) => {
                                            var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                                            refFlickable.contentX = Math.max(0, Math.min(refFlickable.contentWidth - refFlickable.width, refFlickable.contentX - delta))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 5. 대상 월 선택 (White Theme Circular Buttons)
                    Text {
                        text: "대상 월 선택"
                        color: "#CCCCCC"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Flickable {
                        id: monthFlickable
                        width: parent.width
                        height: 32
                        contentWidth: monthRow.width
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        MouseArea {
                            anchors.fill: parent
                            onWheel: (wheel) => {
                                var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                                monthFlickable.contentX = Math.max(0, Math.min(monthFlickable.contentWidth - monthFlickable.width, monthFlickable.contentX - delta))
                            }
                        }

                        Row {
                            id: monthRow
                            spacing: 5

                            Rectangle {
                                width: 50
                                height: 28
                                radius: 14
                                color: root.targetMonth === 0 ? "#FFFFFF" : "#2C2C2C"
                                border.width: 1
                                border.color: root.targetMonth === 0 ? "#FFFFFF" : "#3D3D3D"

                                Text {
                                    anchors.centerIn: parent
                                    text: "전체"
                                    color: root.targetMonth === 0 ? "#121212" : "#AAAAAA"
                                    font.pixelSize: 11
                                    font.bold: root.targetMonth === 0
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.targetMonth = 0
                                    onWheel: (wheel) => {
                                        var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                                        monthFlickable.contentX = Math.max(0, Math.min(monthFlickable.contentWidth - monthFlickable.width, monthFlickable.contentX - delta))
                                    }
                                }
                            }

                            Repeater {
                                model: 12
                                delegate: Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: root.targetMonth === index + 1 ? "#FFFFFF" : "#2C2C2C"
                                    border.width: 1
                                    border.color: root.targetMonth === index + 1 ? "#FFFFFF" : "#3D3D3D"

                                    Text {
                                        anchors.centerIn: parent
                                        text: (index + 1).toString()
                                        color: root.targetMonth === index + 1 ? "#121212" : "#AAAAAA"
                                        font.pixelSize: 12
                                        font.bold: root.targetMonth === index + 1
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.targetMonth = index + 1
                                        onWheel: (wheel) => {
                                            var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                                            monthFlickable.contentX = Math.max(0, Math.min(monthFlickable.contentWidth - monthFlickable.width, monthFlickable.contentX - delta))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 6. Action Buttons (Clear, Apply)
                    Row {
                        anchors.right: parent.right
                        spacing: 8

                        Rectangle {
                            width: 80
                            height: 32
                            radius: 8
                            color: clearHover.containsMouse ? "#3A2A2A" : "#2A1A1A"
                            border.width: 1
                            border.color: "#FF5F57"

                            Text {
                                anchors.centerIn: parent
                                text: "수식 삭제"
                                color: "#FF5F57"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                id: clearHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof dbController !== "undefined" && root.targetMidUuid !== "") {
                                        if (root.targetMonth === 0) {
                                            for (var m = 1; m <= 12; m++) {
                                                dbController.setMIDMonthFormula(root.selectedYear, root.targetMidUuid, m, "")
                                            }
                                        } else {
                                            dbController.setMIDMonthFormula(root.selectedYear, root.targetMidUuid, root.targetMonth, "")
                                        }
                                        root.formulaApplied()
                                        root.closeModal()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 100
                            height: 32
                            radius: 8
                            color: applyHover.containsMouse ? "#E0E0E0" : "#FFFFFF"

                            Text {
                                anchors.centerIn: parent
                                text: "수식 적용"
                                color: "#121212"
                                font.pixelSize: 13
                                font.bold: true
                            }

                            MouseArea {
                                id: applyHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.applyFormula()
                            }
                        }
                    }
                }
            }
        }
    }
}
