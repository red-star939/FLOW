import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int blockIndex: -1
    property string title: "새 항목"
    property string value: ""
    property Flickable parentFlickable: null

    signal removeRequested(int index)
    signal moveRequested(int fromIndex, int toIndex)
    signal titleEdited(string newTitle)
    signal valueEdited(string newValue)
    signal editingFinished()

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

        // ─── Left hover area (delete button + drag handle) ───
        Item {
            id: leftHoverArea
            width: 70
            height: parent.height

            HoverHandler {
                id: leftHoverHandler
            }

            // Drag reorder handle (2x3 dots)
            Item {
                id: subDragHandle
                width: 16
                height: 20

                anchors {
                    left: parent.left
                    leftMargin: 4
                    verticalCenter: parent.verticalCenter
                }

                opacity: leftHoverHandler.hovered ? 1 : 0
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
                                    color: "#666666"
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

            // Hover Delete Button
            Rectangle {
                id: deleteButton
                width: 16
                height: 16
                radius: 8
                color: "#FF5F57"

                anchors {
                    left: subDragHandle.right
                    leftMargin: 6
                    verticalCenter: parent.verticalCenter
                }

                opacity: leftHoverHandler.hovered ? 1.0 : 0.0
                visible: opacity > 0.0

                Behavior on opacity { NumberAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: "white"
                    font.pixelSize: 10
                    font.bold: true
                    y: -1
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.removeRequested(root.blockIndex)
                }
            }
        }

        // ─── Editable Title ───
        TextField {
            id: titleInput
            anchors {
                left: parent.left
                leftMargin: 56
                verticalCenter: parent.verticalCenter
            }

            text: root.title
            color: "#CCCCCC"
            font.pixelSize: 13
            font.bold: false
            width: 70

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

        // ─── Single Cell (Value Input) ───
        Item {
            id: cellArea
            anchors.left: parent.left
            anchors.leftMargin: 130
            anchors.right: parent.right
            anchors.rightMargin: 16
            height: parent.height

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 2
                height: parent.height - 8
                radius: 6
                color: valueInput.activeFocus ? "#2A2A2A" : (valueMouse.containsMouse ? "#303030" : "#222222")
                border.width: valueInput.activeFocus ? 1 : 0
                border.color: "#888888"

                Behavior on color { ColorAnimation { duration: 150 } }

                TextField {
                    id: valueInput
                    anchors.fill: parent
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter

                    text: root.value
                    color: "#FFFFFF"
                    font.pixelSize: 13
                    placeholderText: "-"
                    placeholderTextColor: "#666666"

                    selectByMouse: true
                    selectedTextColor: "#202020"
                    selectionColor: "#FFFFFF"

                    background: Rectangle {
                        color: "transparent"
                    }

                    onTextEdited: {
                        root.value = text
                        root.valueEdited(text)
                    }

                    onEditingFinished: {
                        root.editingFinished()
                        valueInput.focus = false
                    }
                }

                MouseArea {
                    id: valueMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                    cursorShape: Qt.IBeamCursor
                }
            }
        }
    } // end subContentWrapper
} // end root
