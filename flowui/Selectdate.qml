import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int selectedMonth: 1 // 0 = 합계, 1~12 = 1월~12월
    property int selectedYear: 2026
    property int lastValidMonth: (selectedMonth > 0 && selectedMonth <= 12) ? selectedMonth : 1
    readonly property int activeMonth: selectedMonth > 0 ? selectedMonth : (lastValidMonth > 0 ? lastValidMonth : 1)

    signal monthChanged(int month)

    height: 60
    width: parent ? parent.width : 1000

    readonly property real gap: 20
    readonly property real availableWidth: Math.max(300, width - 160 - 60)
    readonly property real cellWidth: (availableWidth - gap) / 13

    readonly property var monthNames: ["1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"]

    onSelectedMonthChanged: {
        if (selectedMonth > 0) {
            lastValidMonth = selectedMonth
            var targetIdx = selectedMonth - 1
            if (pathView.currentIndex !== targetIdx) {
                pathView.currentIndex = targetIdx
            }
        }
    }

    // ─── 3D Horizontal Month Wheel Cylinder (1월 ~ 12월) ───
    PathView {
        id: pathView
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.min(800, parent.width - 120)

        model: 12
        currentIndex: Math.max(0, Math.min(11, root.activeMonth - 1))
        pathItemCount: 3
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        dragMargin: width / 3

        onCurrentIndexChanged: {
            var m = currentIndex + 1
            if (root.selectedMonth !== m) {
                root.selectedMonth = m
                root.monthChanged(m)
            }
        }

        path: Path {
            startX: 80
            startY: pathView.height / 2

            PathAttribute { name: "itemScale"; value: 0.75 }
            PathAttribute { name: "itemOpacity"; value: 0.35 }
            PathAttribute { name: "itemAngle"; value: 30 }
            PathAttribute { name: "itemZ"; value: 1 }

            PathLine {
                x: pathView.width / 2
                y: pathView.height / 2
            }

            PathAttribute { name: "itemScale"; value: 1.0 }
            PathAttribute { name: "itemOpacity"; value: 1.0 }
            PathAttribute { name: "itemAngle"; value: 0 }
            PathAttribute { name: "itemZ"; value: 10 }

            PathLine {
                x: pathView.width - 80
                y: pathView.height / 2
            }

            PathAttribute { name: "itemScale"; value: 0.75 }
            PathAttribute { name: "itemOpacity"; value: 0.35 }
            PathAttribute { name: "itemAngle"; value: -30 }
            PathAttribute { name: "itemZ"; value: 1 }
        }

        delegate: Item {
            width: 100
            height: 50
            scale: PathView.itemScale ? PathView.itemScale : 1.0
            opacity: PathView.itemOpacity ? PathView.itemOpacity : 1.0
            z: PathView.itemZ ? PathView.itemZ : 1

            transform: Rotation {
                origin.x: 50
                origin.y: 25
                axis { x: 0; y: 1; z: 0 }
                angle: PathView.itemAngle ? PathView.itemAngle : 0
            }

            Text {
                anchors.centerIn: parent
                text: root.monthNames[index]
                font.pixelSize: (index === (root.activeMonth - 1)) ? 32 : 22
                font.bold: true
                color: (index === (root.activeMonth - 1)) ? (typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF") : "#666666"

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var clickedMonth = index + 1
                    if (root.selectedMonth !== clickedMonth) {
                        root.selectedMonth = clickedMonth
                        root.monthChanged(clickedMonth)
                    }
                    if (pathView.currentIndex !== index) {
                        pathView.currentIndex = index
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                if (delta < 0) {
                    pathView.incrementCurrentIndex()
                } else if (delta > 0) {
                    pathView.decrementCurrentIndex()
                }
            }
        }
    }

    // ─── 기존 디자인 유지: 우측 고정 합계 헤더 ───
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
