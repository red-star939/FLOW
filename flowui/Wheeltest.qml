import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int startYear: 2002
    property int endYear: 2200
    property int selectedYear: 2026

    signal yearChanged(int year)

    // Increased width for even wider spacing, no capsule background container
    width: 500
    height: 70

    PathView {
        id: pathView
        anchors.fill: parent
        clip: true

        model: root.endYear - root.startYear + 1

        // Map selectedYear to currentIndex and vice versa
        currentIndex: root.selectedYear - root.startYear

        // Determine how many items are visible on the path at once
        pathItemCount: 3

        // Keep highlights centered and snap to items
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

        // Handle external changes to selectedYear
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

        // Horizontal path creating a 3D cylinder side projection (with even wider spacing)
        path: Path {
            // Start of path (left side) - moved further outward to 100
            startX: 100
            startY: pathView.height / 2

            PathAttribute { name: "itemScale"; value: 0.8 }
            PathAttribute { name: "itemOpacity"; value: 0.35 }
            PathAttribute { name: "itemAngle"; value: 35 } // Rotated towards center
            PathAttribute { name: "itemZ"; value: 1 }

            // Peak of path (center)
            PathLine {
                x: pathView.width / 2
                y: pathView.height / 2
            }
            PathAttribute { name: "itemScale"; value: 1.25 }
            PathAttribute { name: "itemOpacity"; value: 1.0 }
            PathAttribute { name: "itemAngle"; value: 0 } // Flat facing user
            PathAttribute { name: "itemZ"; value: 10 }

            // End of path (right side) - moved further outward to width - 100
            PathLine {
                x: pathView.width - 100
                y: pathView.height / 2
            }
            PathAttribute { name: "itemScale"; value: 0.8 }
            PathAttribute { name: "itemOpacity"; value: 0.35 }
            PathAttribute { name: "itemAngle"; value: -35 } // Rotated towards center
            PathAttribute { name: "itemZ"; value: 1 }
        }

        delegate: Item {
            id: delegateItem
            width: 120
            height: 50

            // Apply 3D-like values attached by PathView
            z: PathView.itemZ !== undefined ? PathView.itemZ : 1
            opacity: PathView.itemOpacity !== undefined ? PathView.itemOpacity : 0.35
            scale: PathView.itemScale !== undefined ? PathView.itemScale : 0.8

            transform: Rotation {
                origin.x: delegateItem.width / 2
                origin.y: delegateItem.height / 2
                axis { x: 0; y: 1; z: 0 } // Rotate around the Y axis for cylinder curvature
                angle: delegateItem.PathView.itemAngle !== undefined ? delegateItem.PathView.itemAngle : 0
            }

            Text {
                id: yearText
                anchors.centerIn: parent
                text: root.startYear + index
                font.pixelSize: 26 // Increased from 22 to 26
                font.bold: true // Always bold as requested
                color: delegateItem.PathView.isCurrentItem ? "#FFFFFF" : "#555555" // Sleeker contrast
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                // Simple color animation transition for active state changes
                Behavior on color { ColorAnimation { duration: 150 } }
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

    // Scroll wheel input support (with acceptedButtons: Qt.NoButton)
    // This allows mouse drag and swipe gestures to pass through to the PathView
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
