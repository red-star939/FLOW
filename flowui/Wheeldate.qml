import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int startYear: (typeof dbController !== "undefined" && dbController.startYear >= 0) ? dbController.startYear : 2020
    property int endYear: (typeof dbController !== "undefined" && dbController.endYear >= 0) ? dbController.endYear : 2030
    property int selectedYear: 2026

    signal yearChanged(int year)

    width: 650
    height: 70

    function syncYearRange() {
        if (typeof dbController !== "undefined" && dbController.startYear >= 0 && dbController.endYear >= 0) {
            root.startYear = dbController.startYear
            root.endYear = dbController.endYear
        }

        if (root.selectedYear < root.startYear) {
            root.selectedYear = root.startYear
        } else if (root.selectedYear > root.endYear) {
            root.selectedYear = root.endYear
        }

        var targetIdx = root.selectedYear - root.startYear
        if (targetIdx < 0) targetIdx = 0
        if (targetIdx >= pathView.count) targetIdx = Math.max(0, pathView.count - 1)
        
        if (pathView.currentIndex !== targetIdx) {
            pathView.currentIndex = targetIdx
        }
    }

    onStartYearChanged: syncYearRange()
    onEndYearChanged: syncYearRange()

    Connections {
        target: typeof dbController !== "undefined" ? dbController : null
        function onYearRangeChanged(sYear, eYear) {
            if (sYear >= 0 && eYear >= 0) {
                root.startYear = sYear
                root.endYear = eYear
                root.syncYearRange()
            }
        }
    }

    Component.onCompleted: {
        syncYearRange()
    }

    PathView {
        id: pathView
        anchors.fill: parent
        clip: true

        model: Math.max(1, root.endYear - root.startYear + 1)

        pathItemCount: 3
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        dragMargin: width / 3

        onCurrentIndexChanged: {
            var calculatedYear = root.startYear + currentIndex
            if (root.selectedYear !== calculatedYear) {
                root.selectedYear = calculatedYear
                root.yearChanged(calculatedYear)
            }
        }

        Connections {
            target: root
            function onSelectedYearChanged() {
                var targetIdx = root.selectedYear - root.startYear
                if (targetIdx >= 0 && targetIdx < pathView.count) {
                    if (pathView.currentIndex !== targetIdx) {
                        pathView.currentIndex = targetIdx
                    }
                }
            }
        }

        path: Path {
            startX: 60
            startY: pathView.height / 2

            PathAttribute { name: "itemScale"; value: 0.8 }
            PathAttribute { name: "itemOpacity"; value: 0.35 }
            PathAttribute { name: "itemAngle"; value: 35 }
            PathAttribute { name: "itemZ"; value: 1 }

            PathLine {
                x: pathView.width / 2
                y: pathView.height / 2
            }
            PathAttribute { name: "itemScale"; value: 1.25 }
            PathAttribute { name: "itemOpacity"; value: 1.0 }
            PathAttribute { name: "itemAngle"; value: 0 }
            PathAttribute { name: "itemZ"; value: 10 }

            PathLine {
                x: pathView.width - 60
                y: pathView.height / 2
            }
            PathAttribute { name: "itemScale"; value: 0.8 }
            PathAttribute { name: "itemOpacity"; value: 0.35 }
            PathAttribute { name: "itemAngle"; value: -35 }
            PathAttribute { name: "itemZ"; value: 1 }
        }

        delegate: Item {
            id: delegateItem
            width: 140
            height: 50

            z: PathView.itemZ !== undefined ? PathView.itemZ : 1
            opacity: PathView.itemOpacity !== undefined ? PathView.itemOpacity : 0.35
            scale: PathView.itemScale !== undefined ? PathView.itemScale : 0.8

            transform: Rotation {
                origin.x: delegateItem.width / 2
                origin.y: delegateItem.height / 2
                axis { x: 0; y: 1; z: 0 }
                angle: delegateItem.PathView.itemAngle !== undefined ? delegateItem.PathView.itemAngle : 0
            }

            Text {
                id: yearText
                anchors.centerIn: parent
                text: (root.startYear + index).toString()
                font.pixelSize: 28
                font.bold: true
                color: delegateItem.PathView.isCurrentItem ? (typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF") : ((typeof bgdashRoot !== "undefined" && bgdashRoot.currentThemeIndex === 2) ? "#D8D8D8" : "#555555")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color { ColorAnimation { duration: 250 } }
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
