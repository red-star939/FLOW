import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int selectedMonth: 1
    property int selectedYear: 2026

    signal monthChanged(int month)

    height: 60
    width: parent ? parent.width : 1000

    // Math for precise layout matching grid alignment
    readonly property real gap: 20
    readonly property real availableWidth: Math.max(300, width - 160 - 60)
    readonly property real cellWidth: (availableWidth - gap) / 13

    // Mouse Wheel Scroll Handler for Month selection (0 = 합계, 1~12 = 1월~12월)
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
            if (delta < 0) {
                // Scroll down: move forward (1 -> 2 -> ... -> 12 -> 0 -> 1)
                var nextM = root.selectedMonth + 1
                if (nextM > 12) nextM = 0
                if (nextM !== root.selectedMonth) {
                    root.selectedMonth = nextM
                    root.monthChanged(root.selectedMonth)
                }
            } else if (delta > 0) {
                // Scroll up: move backward (1 -> 0 -> 12 -> 11 -> ... -> 1)
                var prevM = root.selectedMonth - 1
                if (prevM < 0) prevM = 12
                if (prevM !== root.selectedMonth) {
                    root.selectedMonth = prevM
                    root.monthChanged(root.selectedMonth)
                }
            }
        }
    }

    // 1~12 Months Row
    Row {
        id: monthsRow
        anchors.left: parent.left
        anchors.leftMargin: 160
        width: cellWidth * 12
        height: parent.height
        spacing: 0

        Repeater {
            model: 12

            delegate: Item {
                width: root.cellWidth
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: index + 1

                    // Size transition matching active states
                    font.pixelSize: root.selectedMonth === index + 1 ? 28 : 22
                    font.bold: true

                    color: root.selectedMonth === index + 1 ? (typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF") : "#555555"

                    Behavior on color { ColorAnimation { duration: 250 } }
                    Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.selectedMonth = index + 1
                        root.monthChanged(root.selectedMonth)
                    }
                }
            }
        }
    }

    // Sum Header Cell (separated by a gap of 20px)
    Item {
        id: sumHeader
        anchors.right: parent.right
        anchors.rightMargin: 60
        width: root.cellWidth
        height: parent.height

        Text {
            anchors.centerIn: parent
            text: "합계"
            font.pixelSize: root.selectedMonth === 0 ? 26 : 22
            font.bold: true
            color: root.selectedMonth === 0 ? (typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF") : "#8E8E93"

            Behavior on color { ColorAnimation { duration: 250 } }
            Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                root.selectedMonth = 0 // 0 represents 'Total / 합계'
                root.monthChanged(0)
            }
        }
    }
}
