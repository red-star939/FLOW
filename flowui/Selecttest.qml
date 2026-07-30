import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int selectedMonth: 1

    signal monthChanged(int month)

    // Height stays 60
    height: 60

    // Math for precise layout matching Ablock
    readonly property real gap: 20
    readonly property real availableWidth: width - 160 - 60
    readonly property real cellWidth: (availableWidth - gap) / 13

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
                width: cellWidth
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: index + 1

                    // Size transition matching active states
                    font.pixelSize: root.selectedMonth === index + 1 ? 28 : 22
                    font.bold: true

                    color: root.selectedMonth === index + 1 ? "#FFFFFF" : "#555555"

                    Behavior on color { ColorAnimation { duration: 150 } }
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
        width: cellWidth
        height: parent.height

        Text {
            anchors.centerIn: parent
            text: "합계"
            font.pixelSize: 22
            font.bold: true
            color: "#8E8E93" // Muted gray header label
        }
    }
}