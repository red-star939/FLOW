import QtQuick
import QtQuick.Controls

Item {
    id: categorysetRoot
    anchors.fill: parent

    signal closeRequested()

    // ESC Key Shortcut to Close Categoryset Menu
    Shortcut {
        sequence: "Esc"
        enabled: categorysetRoot.visible && categorysetRoot.opacity > 0
        onActivated: {
            categorysetRoot.closeRequested()
        }
    }

    property var midCategories: ["수입금액", "지출금액", "기타"]
    property var idCategories: ["월급", "고정지출", "당일지출", "기타"]
    property var subIdCategories: ["알바", "근로", "저금", "교통비", "통신비", "음식", "여행", "기타"]

    property string addingType: "" // "MID", "ID", "SubID" or ""
    property string newCategoryText: ""
    property string activeDeleteKey: "" // e.g. "MID:월급"

    onVisibleChanged: {
        if (visible) {
            cardScaleAnim.start()
            addingType = ""
            newCategoryText = ""
            activeDeleteKey = ""
            loadSavedCategories()
        }
    }

    Component.onCompleted: {
        loadSavedCategories()
    }

    function loadSavedCategories() {
        if (typeof dbController !== "undefined" && typeof dbController.getCategoryList === "function") {
            var savedMID = dbController.getCategoryList("MID")
            if (savedMID && savedMID.length > 0) midCategories = savedMID

            var savedID = dbController.getCategoryList("ID")
            if (savedID && savedID.length > 0) idCategories = savedID

            var savedSubID = dbController.getCategoryList("SubID")
            if (savedSubID && savedSubID.length > 0) subIdCategories = savedSubID
        }
    }

    function saveCategoryList(type, list) {
        if (typeof dbController !== "undefined" && typeof dbController.saveCategoryList === "function") {
            dbController.saveCategoryList(type, list)
        }
    }

    function addCustomCategoryForType(type, catName) {
        var name = catName.trim()
        if (name === "") return

        var list = []
        if (type === "MID") list = midCategories.slice()
        else if (type === "ID") list = idCategories.slice()
        else list = subIdCategories.slice()

        if (list.indexOf(name) !== -1) return

        var elseIdx = list.indexOf("기타")
        if (elseIdx !== -1) {
            list.splice(elseIdx, 0, name)
        } else {
            list.push(name)
        }

        if (type === "MID") { midCategories = list; saveCategoryList("MID", list) }
        else if (type === "ID") { idCategories = list; saveCategoryList("ID", list) }
        else { subIdCategories = list; saveCategoryList("SubID", list) }

        addingType = ""
        newCategoryText = ""
        activeDeleteKey = ""
    }

    function deleteCustomCategoryForType(type, catName) {
        var list = []
        if (type === "MID") list = midCategories.slice()
        else if (type === "ID") list = idCategories.slice()
        else list = subIdCategories.slice()

        var idx = list.indexOf(catName)
        if (idx !== -1) {
            list.splice(idx, 1)
            if (type === "MID") { midCategories = list; saveCategoryList("MID", list) }
            else if (type === "ID") { idCategories = list; saveCategoryList("ID", list) }
            else { subIdCategories = list; saveCategoryList("SubID", list) }
        }
        activeDeleteKey = ""
    }

    function resetActiveStates() {
        addingType = ""
        activeDeleteKey = ""
        newCategoryText = ""
    }

    // ==========================
    // Overlay Background (Click outside resets active state & closes dialog)
    // ==========================
    Rectangle {
        anchors.fill: parent
        color: "#CC141414"

        MouseArea {
            anchors.fill: parent
            onClicked: {
                categorysetRoot.resetActiveStates()
                categorysetRoot.closeRequested()
            }
        }
    }

    // ==========================
    // Modal Dialog Card
    // ==========================
    Rectangle {
        id: card
        width: 760
        height: 580
        anchors.centerIn: parent
        radius: 20
        color: "#1F1F1F"
        border.width: 1.5
        border.color: "#343434"

        scale: 0.95

        NumberAnimation on scale {
            id: cardScaleAnim
            from: 0.92
            to: 1.0
            duration: 220
            easing.type: Easing.OutCubic
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                categorysetRoot.resetActiveStates()
            }
        }

        Column {
            anchors {
                fill: parent
                margins: 24
            }
            spacing: 16

            // Header Section
            Row {
                width: parent.width

                Row {
                    spacing: 12
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "02"
                        color: "#555555"
                        font.pixelSize: 18
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Category Setting"
                        color: "#FFFFFF"
                        font.pixelSize: 22
                        font.bold: true
                        font.letterSpacing: 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Close Button (×)
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
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
                        onClicked: {
                            categorysetRoot.resetActiveStates()
                            categorysetRoot.closeRequested()
                        }
                    }
                }
            }

            // Divider Line
            Rectangle {
                width: parent.width
                height: 1
                color: "#343434"
            }

            // 3 Vertical Category Level Blocks Container
            Flickable {
                width: parent.width
                height: parent.height - 110
                contentHeight: verticalCategoryColumn.height
                clip: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        categorysetRoot.resetActiveStates()
                    }
                }

                Column {
                    id: verticalCategoryColumn
                    width: parent.width
                    spacing: 14

                    Repeater {
                        model: [
                            { type: "MID", name: "MID 카테고리", list: categorysetRoot.midCategories },
                            { type: "ID", name: "ID 카테고리", list: categorysetRoot.idCategories },
                            { type: "SubID", name: "SubID 카테고리", list: categorysetRoot.subIdCategories }
                        ]

                        delegate: Rectangle {
                            id: categoryBlockCard
                            width: parent.width
                            property string blockType: modelData.type
                            property string blockName: modelData.name
                            property var itemList: modelData.list

                            height: Math.max(115, categoryContentCol.height + 24)
                            radius: 14
                            color: "#181818"
                            border.width: 1
                            border.color: "#2C2C2C"

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    categorysetRoot.resetActiveStates()
                                }
                            }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 16

                                // Left Title Badge
                                Rectangle {
                                    width: 130
                                    height: parent.height
                                    radius: 10
                                    color: "#252525"
                                    border.width: 1
                                    border.color: "#343434"

                                    Text {
                                        anchors.centerIn: parent
                                        text: categoryBlockCard.blockName
                                        color: "#FFFFFF"
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }

                                // Right Content Area: Morphing (+) Chip & Fixed-Width Category Chips Flow
                                Column {
                                    id: categoryContentCol
                                    width: parent.width - 158
                                    spacing: 10
                                    anchors.verticalCenter: parent.verticalCenter

                                    Flow {
                                        width: parent.width
                                        spacing: 8

                                        Repeater {
                                            model: categoryBlockCard.itemList

                                            delegate: Rectangle {
                                                id: chipItem
                                                property string itemText: modelData
                                                property bool isAddChip: itemText === "기타"
                                                property bool isExpanded: isAddChip && (categorysetRoot.addingType === categoryBlockCard.blockType)

                                                property string chipKey: categoryBlockCard.blockType + ":" + itemText
                                                property bool isDeletePending: (categorysetRoot.activeDeleteKey === chipKey)

                                                height: 32
                                                width: isAddChip
                                                       ? (isExpanded ? Math.min(230, categoryContentCol.width) : 32)
                                                       : (chipNameTxt.implicitWidth + 24)
                                                radius: 16
                                                color: isAddChip
                                                       ? (isExpanded ? "#1F1F1F" : (chipHover.containsMouse ? "#FFFFFF" : "#3A3A3A"))
                                                       : (isDeletePending ? "#8B2525" : (chipHover.containsMouse ? "#333333" : "#262626"))
                                                border.width: 1
                                                border.color: isAddChip
                                                        ? (isExpanded ? "#555555" : (chipHover.containsMouse ? "#FFFFFF" : "#4A4A4A"))
                                                        : (isDeletePending ? "#FF453A" : "#3D3D3D")
                                                scale: (!isExpanded && chipHover.containsMouse) ? 1.12 : 1.0
                                                clip: true
                                                z: isDeletePending ? 10 : 1

                                                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                                Behavior on color { ColorAnimation { duration: 180 } }
                                                Behavior on border.color { ColorAnimation { duration: 180 } }
                                                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                                                onIsExpandedChanged: {
                                                    if (isExpanded) {
                                                        inlineInputField.forceActiveFocus()
                                                    }
                                                }

                                                // 1) Circular (+) Icon (Visible when isAddChip && !isExpanded)
                                                Text {
                                                    visible: chipItem.isAddChip && !chipItem.isExpanded
                                                    anchors.centerIn: parent
                                                    text: "+"
                                                    color: chipHover.containsMouse ? "#121212" : "#FFFFFF"
                                                    font.pixelSize: 18
                                                    font.bold: true
                                                }

                                                // 2) Morphing Stretched Input Form (Visible when isAddChip && isExpanded)
                                                Row {
                                                    visible: chipItem.isAddChip && chipItem.isExpanded
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 10
                                                    anchors.rightMargin: 6
                                                    spacing: 6
                                                    z: 10

                                                    TextField {
                                                        id: inlineInputField
                                                        width: parent.width - 66
                                                        height: parent.height - 8
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        verticalAlignment: TextInput.AlignVCenter
                                                        placeholderText: "카테고리명 입력..."
                                                        placeholderTextColor: "#777777"
                                                        color: "#FFFFFF"
                                                        font.pixelSize: 12
                                                        font.bold: true

                                                        background: Rectangle { color: "transparent" }

                                                        onAccepted: {
                                                            categorysetRoot.addCustomCategoryForType(categoryBlockCard.blockType, text)
                                                        }

                                                        Keys.onReturnPressed: categorysetRoot.addCustomCategoryForType(categoryBlockCard.blockType, text)
                                                        Keys.onEnterPressed: categorysetRoot.addCustomCategoryForType(categoryBlockCard.blockType, text)
                                                    }

                                                    // (+) Add Icon Button (Dark category theme color)
                                                    Rectangle {
                                                        id: inlineAddBtn
                                                        width: 26
                                                        height: 22
                                                        radius: 11
                                                        color: inlineAddHover.containsMouse ? "#FFFFFF" : "#3A3A3A"
                                                        border.width: 1
                                                        border.color: inlineAddHover.containsMouse ? "#FFFFFF" : "#555555"
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        z: 20

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "+"
                                                            color: inlineAddHover.containsMouse ? "#121212" : "#FFFFFF"
                                                            font.pixelSize: 15
                                                            font.bold: true
                                                        }

                                                        MouseArea {
                                                            id: inlineAddHover
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                categorysetRoot.addCustomCategoryForType(categoryBlockCard.blockType, inlineInputField.text)
                                                            }
                                                        }
                                                    }

                                                    // 취소 (Cancel ×) Button
                                                    Rectangle {
                                                        id: inlineCancelBtn
                                                        width: 22
                                                        height: 22
                                                        radius: 11
                                                        color: inlineCancelHover.containsMouse ? "#FF453A" : "#3A3A3A"
                                                        border.width: 1
                                                        border.color: inlineCancelHover.containsMouse ? "#FF453A" : "#555555"
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        z: 20

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "×"
                                                            color: "#FFFFFF"
                                                            font.pixelSize: 13
                                                            font.bold: true
                                                        }

                                                        MouseArea {
                                                            id: inlineCancelHover
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                categorysetRoot.resetActiveStates()
                                                            }
                                                        }
                                                    }
                                                }

                                                // 3) Category Label Text (Implicit Width Measurer)
                                                Text {
                                                    id: chipNameTxt
                                                    visible: false
                                                    text: chipItem.itemText
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                }

                                                // 4) Main Category Text / "삭제" Text (Fixed Width Pill Content)
                                                Text {
                                                    visible: !chipItem.isAddChip
                                                    anchors.centerIn: parent
                                                    text: chipItem.isDeletePending ? "삭제" : chipItem.itemText
                                                    color: chipItem.isDeletePending ? "#FFD6D6" : "#FFFFFF"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    id: chipHover
                                                    anchors.fill: parent
                                                    enabled: !chipItem.isExpanded
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (chipItem.isAddChip) {
                                                            categorysetRoot.addingType = categoryBlockCard.blockType
                                                            categorysetRoot.activeDeleteKey = ""
                                                        } else {
                                                            if (chipItem.isDeletePending) {
                                                                // Second click while showing "삭제" -> Delete category!
                                                                categorysetRoot.deleteCustomCategoryForType(categoryBlockCard.blockType, chipItem.itemText)
                                                            } else {
                                                                // First click -> Show "삭제" on red background!
                                                                categorysetRoot.activeDeleteKey = chipItem.chipKey
                                                                categorysetRoot.addingType = ""
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Action Footer
            Row {
                width: parent.width

                Text {
                    text: "💡 카테고리를 클릭하면 붉은 배경과 함께 '삭제' 텍스트로 바뀌며, 다른 곳을 클릭하면 원상복귀 됩니다."
                    color: "#777777"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Close / Confirm Button
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 100
                    height: 34
                    radius: 10
                    color: okHover.containsMouse ? "#E0E0E0" : "#FFFFFF"

                    Text {
                        anchors.centerIn: parent
                        text: "완료"
                        color: "#121212"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        id: okHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            categorysetRoot.resetActiveStates()
                            categorysetRoot.closeRequested()
                        }
                    }
                }
            }
        }
    }
}
