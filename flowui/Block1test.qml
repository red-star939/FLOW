import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int blockIndex: -1
    property string title: "새 블록"
    property Flickable parentFlickable: null

    signal removeRequested(int index)
    signal moveRequested(int fromIndex, int toIndex)
    signal titleEdited(string newTitle)
    signal editingFinished()
    signal dataChanged()

    property real totalValue: 0
    property var subblocksData: []

    function updateTotal() {
        var sum = 0
        var arr = []
        for (var i = 0; i < subBlockModel.count; i++) {
            var item = subBlockModel.get(i)
            if (item) {
                arr.push({
                    "title": item.title !== undefined ? item.title : "새 항목",
                    "value": item.value !== undefined ? item.value : ""
                })
                if (item.value !== undefined && item.value !== "") {
                    var val = parseFloat(item.value)
                    if (!isNaN(val)) {
                        sum += val
                    }
                }
            }
        }
        totalValue = sum
        subblocksData = arr
    }

    onSubblocksDataChanged: {
        // Prevent infinite feedback loops
        if (subBlockModel.count === subblocksData.length) {
            var identical = true
            for (var i = 0; i < subblocksData.length; i++) {
                var local = subBlockModel.get(i)
                if (!local || local.title !== subblocksData[i].title || local.value !== subblocksData[i].value) {
                    identical = false
                    break
                }
            }
            if (identical) return
        }

        subBlockModel.clear()
        if (subblocksData) {
            for (var i = 0; i < subblocksData.length; i++) {
                subBlockModel.append({
                    "title": subblocksData[i].title !== undefined ? subblocksData[i].title : "새 항목",
                    "value": subblocksData[i].value !== undefined ? subblocksData[i].value : ""
                })
            }
        }

        // Recalculate total sum without re-triggering subblocksData change
        var sum = 0
        for (var i = 0; i < subBlockModel.count; i++) {
            var item = subBlockModel.get(i)
            if (item && item.value !== undefined && item.value !== "") {
                var val = parseFloat(item.value)
                if (!isNaN(val)) {
                    sum += val
                }
            }
        }
        totalValue = sum
    }

    Component.onCompleted: {
        updateTotal()
    }

    width: 280
    height: parent ? parent.height : 180

    z: dragMouseArea.pressed ? 100 : 1

    readonly property bool isBblock: true
    readonly property bool dragActive: dragMouseArea.pressed
    readonly property real dragXOffset: contentWrapper.x

    // Tracks if there is currently any dragging sibling item in the row
    readonly property bool parentHasDraggingItem: {
        if (!root.parent) return false
        var siblings = root.parent.children
        for (var i = 0; i < siblings.length; i++) {
            var sib = siblings[i]
            if (sib && typeof sib.isBblock !== "undefined" && sib.isBblock && sib.dragActive) {
                return true
            }
        }
        return false
    }

    // Visual shift offset for Apple-style placeholder opening (horizontal)
    readonly property real visualShift: {
        if (!root.parent) return 0

        var draggingItem = null
        var siblings = root.parent.children
        for (var i = 0; i < siblings.length; i++) {
            var sib = siblings[i]
            if (sib && typeof sib.isBblock !== "undefined" && sib.isBblock && sib.dragActive) {
                draggingItem = sib
                break
            }
        }

        if (!draggingItem || draggingItem === root) {
            return 0
        }

        var dragIndex = draggingItem.blockIndex
        var myIndex = root.blockIndex
        var dragX = draggingItem.x + draggingItem.dragXOffset
        var myX = root.x
        var colWidthWithSpacing = root.width + 16

        if (dragIndex < myIndex && dragX > myX - colWidthWithSpacing / 2) {
            return -colWidthWithSpacing
        } else if (dragIndex > myIndex && dragX < myX + colWidthWithSpacing / 2) {
            return colWidthWithSpacing
        }

        return 0
    }

    // ─── Internal sub-block data model ───
    ListModel {
        id: subBlockModel
        ListElement { title: "새 항목"; value: "" }
    }

    // Visual card container (drags horizontally)
    Rectangle {
        id: contentWrapper
        width: root.width
        height: root.height
        x: 0

        radius: 18
        color: "#252525"
        border.width: 1
        border.color: "#343434"

        // Smooth translation behavior for sibling items sliding out of the way
        transform: Translate {
            x: root.visualShift
            Behavior on x {
                enabled: root.parentHasDraggingItem
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Background click area to clear focus
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: {
                titleInput.focus = false
            }
        }

        // ─── Header ───
        Rectangle {
            id: header
            width: parent.width
            height: 46
            radius: 18
            color: "transparent"

            // Editable Title TextField centered inside the header
            TextField {
                id: titleInput
                anchors.centerIn: parent
                horizontalAlignment: TextInput.AlignHCenter

                text: root.title
                color: "#FFFFFF"
                font.pixelSize: 18
                font.bold: true
                width: parent.width - 100

                selectByMouse: true
                selectedTextColor: "#202020"
                selectionColor: "#FFFFFF"

                background: Rectangle {
                    color: "transparent"
                    border.width: 0
                }

                onTextEdited: {
                    root.title = text
                    root.titleEdited(text)
                }

                onEditingFinished: {
                    root.editingFinished()
                    titleInput.focus = false
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // ─── Sub-block content area (scrollable) ───
        Flickable {
            id: subFlickable
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: footer.top
                topMargin: 4
                leftMargin: 0
                rightMargin: 0
                bottomMargin: 4
            }
            clip: true
            contentHeight: subColumn.height
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: subColumn
                width: parent.width
                spacing: 8

                Repeater {
                    model: subBlockModel

                    delegate: B1block {
                        blockIndex: index
                        parentFlickable: subFlickable
                        title: model.title !== undefined ? model.title : "새 항목"
                        value: model.value !== undefined ? model.value : ""

                        onTitleEdited: function(newTitle) {
                            subBlockModel.setProperty(index, "title", newTitle)
                            root.updateTotal()
                            root.dataChanged()
                        }
                        onValueEdited: function(newValue) {
                            subBlockModel.setProperty(index, "value", newValue)
                            root.updateTotal()
                            root.dataChanged()
                        }
                        onEditingFinished: {
                            root.dataChanged()
                        }
                        onMoveRequested: function(fromIndex, toIndex) {
                            var clampedTo = Math.max(0, Math.min(subBlockModel.count - 1, toIndex))
                            if (fromIndex !== clampedTo) {
                                subBlockModel.move(fromIndex, clampedTo, 1)
                                root.updateTotal()
                                root.dataChanged()
                            }
                        }
                        onRemoveRequested: {
                            subBlockModel.remove(index)
                            root.updateTotal()
                            root.dataChanged()
                        }
                    }
                }

                // ─── Add sub-block button (localized hover) ───
                Item {
                    id: subAddContainer
                    width: parent.width
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
                        opacity: subAddHoverHandler.hovered ? 1.0 : 0.4

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
                                subBlockModel.append({ "title": "새 항목", "value": "" })
                                root.updateTotal()
                                root.dataChanged()
                            }
                        }
                    }
                }
            }
        }

        // ─── Localized top-left hover area for Bblock delete button ───
        Item {
            id: deleteHoverArea
            width: 50
            height: 50

            HoverHandler {
                id: deleteHoverHandler
            }

            Rectangle {
                id: deleteButton
                width: 18
                height: 18
                radius: 9
                color: "#FF5F57"
                anchors.centerIn: parent

                opacity: deleteHoverHandler.hovered ? 1.0 : 0.0
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
                    onClicked: {
                        root.removeRequested(root.blockIndex)
                    }
                }
            }
        }

        // ─── Localized top-right hover area for Bblock drag reorder handle ───
        Item {
            id: dragHoverArea
            width: 50
            height: 50
            anchors.right: parent.right
            anchors.top: parent.top

            HoverHandler {
                id: dragHoverHandler
            }

            Item {
                id: dragHandle
                width: 20
                height: 24
                anchors.centerIn: parent
                opacity: dragHoverHandler.hovered ? 1 : 0

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
                    drag.axis: Drag.XAxis

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

                        var targetIndex = root.blockIndex + Math.round(contentWrapper.x / (root.width + 16))
                        root.moveRequested(root.blockIndex, targetIndex)

                        contentWrapper.x = 0
                    }
                }
            }
        }

        // ─── Footer for Total Sum ───
        Rectangle {
            id: footer
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 36
            color: "#1E1E1E"
            radius: 18

            border.width: 1
            border.color: "#343434"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 8
                color: "#1E1E1E"
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: "#343434"
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "합계"
                color: "#888888"
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: root.totalValue.toLocaleString()
                color: "#FFFFFF"
                font.pixelSize: 14
                font.bold: true
            }
        }
    }
}