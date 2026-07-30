import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int blockIndex: -1
    property string uuid: ""
    property string midName: "MID 블록"
    property var monthsData: []
    property real totalValue: 0
    property int selectedYear: 2026
    property int selectedMonth: 1
    property Flickable parentFlickable: null

    signal removeRequested(int index)
    signal moveRequested(int fromIndex, int toIndex)
    signal titleEdited(string newTitle)
    signal editingFinished()
    signal formulaRequested(string midUuid, string midName, Item buttonItem)

    Component.onCompleted: {
        if (root.midName === "" || root.midName === "새 MID" || root.midName.indexOf("MID ") === 0) {
            titleInput.forceActiveFocus()
            titleInput.selectAll()
        }
    }

    // Make width responsive to parent, fallback to 1200
    width: parent ? parent.width : 1200
    height: 46
    z: dragMouseArea.pressed ? 100 : 1

    readonly property bool isMIDblock: true
    readonly property bool dragActive: dragMouseArea.pressed
    readonly property real dragYOffset: contentWrapper.y

    // Math for precise layout matching Selectdate / MonthSelector
    readonly property real gap: 20
    readonly property real availableWidth: Math.max(300, root.width - 160 - 60)
    readonly property real cellWidth: (availableWidth - gap) / 13

    // Tracks if there is currently any dragging sibling item in the column
    readonly property bool parentHasDraggingItem: {
        if (!root.parent) return false
        var siblings = root.parent.children
        for (var i = 0; i < siblings.length; i++) {
            var sib = siblings[i]
            if (sib && typeof sib.isMIDblock !== "undefined" && sib.isMIDblock && sib.dragActive) {
                return true
            }
        }
        return false
    }

    // Visual shift offset for Apple-style placeholder opening
    readonly property real visualShift: {
        if (!root.parent) return 0

        var draggingItem = null
        var siblings = root.parent.children
        for (var i = 0; i < siblings.length; i++) {
            var sib = siblings[i]
            if (sib && typeof sib.isMIDblock !== "undefined" && sib.isMIDblock && sib.dragActive) {
                draggingItem = sib
                break
            }
        }

        if (!draggingItem || draggingItem === root) {
            return 0
        }

        var dragIndex = draggingItem.blockIndex
        var myIndex = root.blockIndex
        var dragY = draggingItem.y + draggingItem.dragYOffset
        var myY = root.y
        var rowHeightWithSpacing = root.height + 16

        if (dragIndex < myIndex && dragY > myY - rowHeightWithSpacing / 2) {
            return -rowHeightWithSpacing
        } else if (dragIndex > myIndex && dragY < myY + rowHeightWithSpacing / 2) {
            return rowHeightWithSpacing
        }

        return 0
    }

    // ─── contentWrapper: wraps ALL visual children so drag + shift works ───
    Item {
        id: contentWrapper
        width: root.width
        height: root.height
        y: 0

        // Smooth translation behavior for sibling items sliding out of the way
        transform: Translate {
            y: root.visualShift
            Behavior on y {
                enabled: root.parentHasDraggingItem
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }

        // ─── Left hover area (delete button + drag handle) ───
        Item {
            id: leftHoverArea
            width: 150
            height: parent.height

            HoverHandler {
                id: leftHoverHandler
            }

            // Hover Delete Button
            Rectangle {
                id: deleteButton
                width: 18
                height: 18
                radius: 9
                color: "#FF5F57"

                anchors {
                    left: dragHandle.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                opacity: leftHoverHandler.hovered ? 1.0 : 0.0
                visible: opacity > 0.0

                Behavior on opacity { NumberAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    y: -1
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.removeRequested(root.blockIndex)
                }
            }

            // Drag reorder handle (2x3 dots)
            Item {
                id: dragHandle
                width: 20
                height: 24

                anchors {
                    left: parent.left
                    leftMargin: 6
                    verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    opacity: leftHoverHandler.hovered || dragMouseArea.pressed ? 1.0 : 0.0
                    visible: opacity > 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Repeater {
                        model: 3
                        Row {
                            spacing: 2
                            Repeater {
                                model: 2
                                Rectangle {
                                    width: 3
                                    height: 3
                                    radius: 1.5
                                    color: "#7A7A7A"
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: dragMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.OpenHandCursor

                    drag.target: contentWrapper
                    drag.axis: Drag.YAxis

                    onPressed: {
                        cursorShape = Qt.ClosedHandCursor
                        if (root.parentFlickable) {
                            root.parentFlickable.interactive = false
                        }
                    }
                    onReleased: {
                        cursorShape = Qt.OpenHandCursor
                        if (root.parentFlickable) {
                            root.parentFlickable.interactive = true
                        }

                        var targetIndex = root.blockIndex + Math.round(contentWrapper.y / (root.height + 16))
                        root.moveRequested(root.blockIndex, targetIndex)

                        contentWrapper.y = 0
                    }
                }
            }
        }

        // ─── Circular Pill Title Container & Category Selector ───
        Rectangle {
            id: titlePillBadge
            anchors {
                left: parent.left
                leftMargin: 65
                verticalCenter: parent.verticalCenter
            }
            height: 32
            width: titleTxt.implicitWidth + 26
            radius: 16
            color: titleHover.containsMouse ? "#2A2A2A" : (typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTitleBadgeBg : "#222222")
            border.width: 1.5
            border.color: titlePopup.visible ? "#FFFFFF" : (titleHover.containsMouse ? "#555555" : "#343434")
            scale: titleHover.containsMouse ? 1.12 : 1.0
            z: titlePopup.visible ? 10 : 1

            Behavior on color { ColorAnimation { duration: 250 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

            Text {
                id: titleTxt
                anchors.centerIn: parent
                text: root.midName
                color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF"
                font.pixelSize: 15
                font.bold: true
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            MouseArea {
                id: titleHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    titlePopup.loadCategories()
                    titlePopup.open()
                }
            }

            // ─── MID Category Selector Popover Popup ───
            Popup {
                id: titlePopup
                parent: Overlay.overlay
                width: 170
                padding: 10
                modal: false
                focus: true
                closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

                property var categoryItems: ["수입금액", "지출금액"]

                function updatePosition() {
                    if (!titlePillBadge.Window || !titlePillBadge.Window.window) return
                    var rootOverlay = titlePillBadge.Window.window.contentItem
                    var globalPos = titlePillBadge.mapToItem(rootOverlay, 0, 0)
                    var winHeight = titlePillBadge.Window.window.height
                    var winWidth = titlePillBadge.Window.window.width
                    var popHeight = titlePopup.implicitHeight
                    var popWidth = titlePopup.width

                    var targetX = globalPos.x
                    if (targetX + popWidth > winWidth - 10) {
                        targetX = winWidth - popWidth - 10
                    }
                    if (targetX < 10) targetX = 10
                    titlePopup.x = targetX

                    if (globalPos.y + titlePillBadge.height + popHeight > winHeight - 20) {
                        titlePopup.y = globalPos.y - popHeight - 6
                    } else {
                        titlePopup.y = globalPos.y + titlePillBadge.height + 6
                    }
                }

                onAboutToShow: updatePosition()

                function loadCategories() {
                    var list = ["수입금액", "지출금액"]
                    if (typeof dbController !== "undefined" && typeof dbController.getCategoryList === "function") {
                        var saved = dbController.getCategoryList("MID")
                        if (saved && saved.length > 0) {
                            list = saved.filter(function(item) { return item !== "기타"; })
                        }
                    }
                    categoryItems = list
                    updatePosition()
                }

                background: Rectangle {
                    radius: 12
                    color: "#1F1F1F"
                    border.width: 1.5
                    border.color: "#343434"
                }

                Column {
                    id: popupCol
                    width: parent.width
                    spacing: 8

                    // Section Header Label
                    Text {
                        text: "카테고리 선택"
                        color: "#777777"
                        font.pixelSize: 11
                        font.bold: true
                    }

                    // Category Items Scrollable List
                    Flickable {
                        width: parent.width
                        height: Math.min(100, catListCol.height)
                        contentHeight: catListCol.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: catListCol
                            width: parent.width
                            spacing: 3

                            Repeater {
                                model: titlePopup.categoryItems

                                delegate: Rectangle {
                                    width: parent.width
                                    height: 30
                                    radius: 6
                                    color: catItemHover.containsMouse ? "#3A3A3A" : "transparent"

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        color: "#FFFFFF"
                                        font.pixelSize: 12
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: catItemHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.midName = modelData
                                            root.titleEdited(modelData)
                                            root.editingFinished()
                                            titlePopup.close()
                                        }
                                    }
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

                    // Direct Input Section
                    Column {
                        width: parent.width
                        spacing: 4

                        Text {
                            text: "직접 입력"
                            color: "#777777"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Rectangle {
                            width: parent.width
                            height: 30
                            radius: 6
                            color: "#151515"
                            border.width: 1
                            border.color: directInputField.activeFocus ? "#FFFFFF" : "#343434"

                            TextField {
                                id: directInputField
                                anchors.fill: parent
                                anchors.margins: 2
                                verticalAlignment: TextInput.AlignVCenter
                                placeholderText: "블록명 입력..."
                                placeholderTextColor: "#666666"
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.bold: true
                                background: Rectangle { color: "transparent" }

                                onAccepted: {
                                    var trimmed = text.trim()
                                    if (trimmed !== "") {
                                        root.midName = trimmed
                                        root.titleEdited(trimmed)
                                        root.editingFinished()
                                    }
                                    titlePopup.close()
                                }

                                Keys.onReturnPressed: {
                                    var trimmed = text.trim()
                                    if (trimmed !== "") {
                                        root.midName = trimmed
                                        root.titleEdited(trimmed)
                                        root.editingFinished()
                                    }
                                    titlePopup.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─── 12 Month Cells Row ───
        Row {
            id: cellsRow
            anchors.left: parent.left
            anchors.leftMargin: 160
            width: root.cellWidth * 12
            height: parent.height
            spacing: 0

            Repeater {
                model: 12

                delegate: Item {
                    width: root.cellWidth
                    height: cellsRow.height

                    property var monthData: (root.monthsData && root.monthsData.length > index)
                                             ? root.monthsData[index]
                                             : null
                    property real val: monthData && monthData.value !== undefined ? monthData.value : 0.0

                    TextField {
                        id: cellInput
                        anchors.centerIn: parent
                        width: parent.width - 2
                        height: parent.height - 8
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 15
                        font.bold: true

                        readOnly: true
                        selectByMouse: false

                        text: parent.val !== 0
                              ? Number(parent.val).toLocaleString(Qt.locale("ko_KR"), "f", 0)
                              : "-"

                        color: parent.val !== 0 ? (typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF") : "#B0B0B0"

                        scale: cellHoverHandler.hovered ? 1.18 : 1.0
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 250 } }

                        background: Rectangle {
                            color: "transparent"
                            radius: 6
                            border.width: 0
                            border.color: "transparent"
                        }

                        HoverHandler {
                            id: cellHoverHandler
                        }
                    }

                    // Vertical separator line between month cells
                    Rectangle {
                        visible: index < 11
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 20
                        color: "#3A3A3A"
                    }
                }
            }
        }

        // ─── 13th Sum Cell ───
        Item {
            id: sumCell
            anchors.right: parent.right
            anchors.rightMargin: 65
            width: root.cellWidth
            height: parent.height

            HoverHandler {
                id: sumHoverHandler
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 2
                height: parent.height - 8
                radius: 6
                color: "transparent"
                border.width: 0

                Text {
                    anchors.centerIn: parent
                    text: Number(root.totalValue).toLocaleString(Qt.locale("ko_KR"), "f", 0)
                    color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF"
                    font.pixelSize: 16
                    font.bold: true
                    scale: sumHoverHandler.hovered ? 1.18 : 1.0
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
            }
        }

        // ─── Circular Formula (f) Button with Hover Mode ───
        Item {
            id: funcButtonContainer
            width: 26
            height: 26
            anchors.left: sumCell.right
            anchors.leftMargin: 12
            anchors.verticalCenter: sumCell.verticalCenter

            HoverHandler {
                id: funcHoverHandler
            }

            Rectangle {
                anchors.fill: parent
                radius: 13
                color: funcMouseArea.containsMouse ? "#FFFFFF" : "#3A3A3A"
                opacity: (funcHoverHandler.hovered || funcMouseArea.containsMouse) ? 1.0 : 0.0
                visible: opacity > 0.0

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "f"
                    color: funcMouseArea.containsMouse ? "#202020" : "#CCCCCC"
                    font.pixelSize: 14
                    font.bold: true
                    font.italic: true
                }

                MouseArea {
                    id: funcMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.formulaRequested(root.uuid, root.midName, funcButtonContainer)
                    }
                }
            }
        }
    }
}
