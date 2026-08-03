import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int selectedYear: 2026
    property int selectedMonth: 8
    property int selectedDay: 15

    signal dayChanged(int day)

    width: 135
    height: 40

    function getDaysInMonth(year, month) {
        if (month <= 0 || month > 12) return 31
        return new Date(year, month, 0).getDate()
    }

    readonly property int daysCount: getDaysInMonth(selectedYear, selectedMonth)

    function syncDayIndex() {
        var count = daysCount
        if (root.selectedDay < 1) root.selectedDay = 1
        if (root.selectedDay > count) root.selectedDay = count

        var targetIdx = root.selectedDay - 1
        if (targetIdx < 0) targetIdx = 0
        if (targetIdx >= pathView.count) targetIdx = Math.max(0, pathView.count - 1)

        if (pathView.currentIndex !== targetIdx) {
            pathView.currentIndex = targetIdx
        }
    }

    onSelectedYearChanged: syncDayIndex()
    onSelectedMonthChanged: syncDayIndex()

    Component.onCompleted: {
        var d = new Date()
        if (d.getFullYear() === selectedYear && (d.getMonth() + 1) === selectedMonth) {
            selectedDay = d.getDate()
        }
        syncDayIndex()
    }

    PathView {
        id: pathView
        anchors.fill: parent
        clip: true

        model: root.daysCount

        pathItemCount: 3
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        dragMargin: width / 3

        onCurrentIndexChanged: {
            var calcDay = currentIndex + 1
            if (root.selectedDay !== calcDay) {
                root.selectedDay = calcDay
                root.dayChanged(calcDay)
            }
        }

        path: Path {
            startX: 14
            startY: pathView.height / 2

            PathAttribute { name: "itemScale"; value: 0.75 }
            PathAttribute { name: "itemOpacity"; value: 0.35 }
            PathAttribute { name: "itemAngle"; value: 30 }
            PathAttribute { name: "itemZ"; value: 1 }

            PathLine {
                x: pathView.width / 2
                y: pathView.height / 2
            }
            PathAttribute { name: "itemScale"; value: 1.2 }
            PathAttribute { name: "itemOpacity"; value: 1.0 }
            PathAttribute { name: "itemAngle"; value: 0 }
            PathAttribute { name: "itemZ"; value: 10 }

            PathLine {
                x: pathView.width - 14
                y: pathView.height / 2
            }
            PathAttribute { name: "itemScale"; value: 0.75 }
            PathAttribute { name: "itemOpacity"; value: 0.35 }
            PathAttribute { name: "itemAngle"; value: -30 }
            PathAttribute { name: "itemZ"; value: 1 }
        }

        delegate: Item {
            id: delegateItem
            width: 50
            height: 36

            z: PathView.itemZ !== undefined ? PathView.itemZ : 1
            opacity: PathView.itemOpacity !== undefined ? PathView.itemOpacity : 0.35
            scale: PathView.itemScale !== undefined ? PathView.itemScale : 0.75

            transform: Rotation {
                origin.x: delegateItem.width / 2
                origin.y: delegateItem.height / 2
                axis { x: 0; y: 1; z: 0 }
                angle: delegateItem.PathView.itemAngle !== undefined ? delegateItem.PathView.itemAngle : 0
            }

            Text {
                id: dayText
                anchors.centerIn: parent
                text: (index + 1).toString()
                font.pixelSize: delegateItem.PathView.isCurrentItem ? 22 : 16
                font.bold: true
                color: delegateItem.PathView.isCurrentItem ? "#FFFFFF" : "#666666"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: {
                    if (pathView.currentIndex !== index) {
                        pathView.currentIndex = index
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton

        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) {
                pathView.decrementCurrentIndex()
            } else if (wheel.angleDelta.y < 0) {
                pathView.incrementCurrentIndex()
            }
            wheel.accepted = true
        }
    }
}
