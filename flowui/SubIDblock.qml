import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int blockIndex: -1
    property string uuid: ""
    property string title: "새 항목"
    property string value: ""
    property Flickable parentFlickable: null

    signal removeRequested(int index)
    signal moveRequested(int fromIndex, int toIndex)
    signal titleEdited(string newTitle)
    signal valueEdited(string newValue)
    signal valueInputRealtime(string newValue)
    signal editingFinished()

    Component.onCompleted: {
        if (root.title === "" || root.title === "새 SubID" || root.title.indexOf("SubID ") === 0) {
            titleInput.forceActiveFocus()
            titleInput.selectAll()
        }
    }

    width: parent ? parent.width : 248
    height: 38
    z: subDragMouseArea.pressed ? 100 : 1

    readonly property bool isB1block: true
    readonly property bool dragActive: subDragMouseArea.pressed
    readonly property real dragYOffset: subContentWrapper.y

    // Tracks if there is currently any dragging sibling item in the column
    readonly property bool parentHasDraggingItem: {
        if (!root.parent) return false
        var siblings = root.parent.children
        for (var i = 0; i < siblings.length; i++) {
            var sib = siblings[i]
            if (sib && typeof sib.isB1block !== "undefined" && sib.isB1block && sib.dragActive) {
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
            if (sib && typeof sib.isB1block !== "undefined" && sib.isB1block && sib.dragActive) {
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
        var rowHeightWithSpacing = root.height + 8

        if (dragIndex < myIndex && dragY > myY - rowHeightWithSpacing / 2) {
            return -rowHeightWithSpacing
        } else if (dragIndex > myIndex && dragY < myY + rowHeightWithSpacing / 2) {
            return rowHeightWithSpacing
        }

        return 0
    }

    // ─── subContentWrapper: wraps ALL visual children ───
    Item {
        id: subContentWrapper
        width: root.width
        height: root.height
        y: 0

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

        HoverHandler {
            id: cardHover
        }

        // ─── Left hover area (Delete button ONLY on the left) ───
        Item {
            id: leftHoverArea
            width: 32
            height: parent.height
            z: 10

            HoverHandler {
                id: leftHoverHandler
            }

            // Hover Delete Button (Red #FF5F57 circle with ×)
            Rectangle {
                id: deleteButton
                width: 16
                height: 16
                radius: 8
                color: "#FF5F57"

                anchors {
                    left: parent.left
                    leftMargin: 8
                    verticalCenter: parent.verticalCenter
                }

                opacity: (leftHoverHandler.hovered || cardHover.hovered) ? 1.0 : 0.0
                visible: opacity > 0.0

                Behavior on opacity { NumberAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: "white"
                    font.pixelSize: 10
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (mouse) => {
                        mouse.accepted = true
                        root.removeRequested(root.blockIndex)
                    }
                    onClicked: {
                        root.removeRequested(root.blockIndex)
                    }
                }
            }
        }

        // ─── Circular Pill Title Container & Category Selector (Left Half) ───
        Rectangle {
            id: titlePillBadge
            anchors {
                left: parent.left
                leftMargin: 32
                right: verticalDivider.left
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            height: 26
            radius: 13
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
                text: root.title
                color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF"
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
                width: Math.min(implicitWidth, parent.width - 12)
                horizontalAlignment: Text.AlignHCenter
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

            // ─── SubID Category Selector Popover Popup ───
            Popup {
                id: titlePopup
                parent: Overlay.overlay
                width: 150
                padding: 8
                modal: false
                focus: true
                closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

                property var categoryItems: ["알바", "근로", "저금", "교통비", "통신비", "음식", "여행"]

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
                    var list = ["알바", "근로", "저금", "교통비", "통신비", "음식", "여행"]
                    if (typeof dbController !== "undefined" && typeof dbController.getCategoryList === "function") {
                        var saved = dbController.getCategoryList("SubID")
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
                    spacing: 6

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
                            spacing: 2

                            Repeater {
                                model: titlePopup.categoryItems

                                delegate: Rectangle {
                                    width: parent.width
                                    height: 28
                                    radius: 6
                                    color: catItemHover.containsMouse ? "#3A3A3A" : "transparent"

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: catItemHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.title = modelData
                                            root.titleEdited(modelData)
                                            root.editingFinished()
                                            titlePopup.close()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#343434"
                    }

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
                            height: 28
                            radius: 6
                            color: "#151515"
                            border.width: 1
                            border.color: directInputField.activeFocus ? "#FFFFFF" : "#343434"

                            TextField {
                                id: directInputField
                                anchors.fill: parent
                                anchors.margins: 2
                                verticalAlignment: TextInput.AlignVCenter
                                placeholderText: "항목명 입력..."
                                placeholderTextColor: "#666666"
                                color: "#FFFFFF"
                                font.pixelSize: 11
                                font.bold: true
                                background: Rectangle { color: "transparent" }

                                onAccepted: {
                                    var trimmed = text.trim()
                                    if (trimmed !== "") {
                                        root.title = trimmed
                                        root.titleEdited(trimmed)
                                        root.editingFinished()
                                    }
                                    titlePopup.close()
                                }

                                Keys.onReturnPressed: {
                                    var trimmed = text.trim()
                                    if (trimmed !== "") {
                                        root.title = trimmed
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

        // ─── Vertical Divider Line (Exact Dead Center) ───
        Rectangle {
            id: verticalDivider
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height - 12
            color: "#3A3A3A"
        }

        // ─── Single Cell / Value Input (Right Half) ───
        Item {
            id: cellArea
            anchors {
                left: verticalDivider.right
                leftMargin: 8
                right: subDragHandle.left
                rightMargin: 4
                top: parent.top
                bottom: parent.bottom
            }

            Item {
                anchors.centerIn: parent
                width: parent.width - 2
                height: parent.height - 8

                TextField {
                    id: valueInput
                    anchors.fill: parent
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter

                    text: root.value
                    color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF"
                    font.pixelSize: 13
                    font.bold: true
                    placeholderText: "-"
                    placeholderTextColor: "#666666"

                    Behavior on color { ColorAnimation { duration: 250 } }

                    selectByMouse: true
                    selectedTextColor: "#202020"
                    selectionColor: "#FFFFFF"

                    background: Rectangle {
                        color: "transparent"
                    }

                    function commitValue() {
                        root.valueEdited(valueInput.text)
                        root.editingFinished()
                        valueInput.focus = false
                    }

                    onTextEdited: {
                        root.value = text
                        root.valueInputRealtime(text)
                    }

                    onAccepted: commitValue()
                    onEditingFinished: commitValue()
                    Keys.onReturnPressed: commitValue()
                    Keys.onEnterPressed: commitValue()
                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            commitValue()
                        }
                    }
                }
            }
        }

        // ─── Right hover area (Drag reorder handle ONLY on the right) ───
        Item {
            id: subDragHandle
            width: 20
            height: 24
            z: 10

            anchors {
                right: parent.right
                rightMargin: 6
                verticalCenter: parent.verticalCenter
            }

            opacity: (cardHover.hovered || subDragMouseArea.containsMouse) ? 1.0 : 0.35
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: 3
                    Row {
                        spacing: 2
                        Repeater {
                            model: 2
                            Rectangle {
                                width: 2.5
                                height: 2.5
                                radius: 1.25
                                color: subDragMouseArea.containsMouse ? "#FFFFFF" : "#777777"
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: subDragMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.OpenHandCursor

                drag.target: subContentWrapper
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

                    var targetIndex = root.blockIndex + Math.round(subContentWrapper.y / (root.height + 8))
                    root.moveRequested(root.blockIndex, targetIndex)

                    subContentWrapper.y = 0
                }
            }
        }
    }
}
