import QtQuick
import QtQuick.Controls

Item {
    id: root

    signal startRequested()

    property color bgColor: "#141414"
    property color titleColor: "#FFFFFF"
    property color subtitleColor: "#7A7A7A"

    function updateTheme() {
        var themeIdx = 0
        if (typeof dbController !== "undefined" && typeof dbController.getSavedThemeIndex === "function") {
            themeIdx = dbController.getSavedThemeIndex()
        }
        setTheme(themeIdx)
    }

    function setTheme(idx) {
        if (idx === 1) { // Sage Green
            bgColor = "#E0D9CF"
            titleColor = "#578679"
            subtitleColor = "#819E8A"
        } else if (idx === 2) { // Carmine Red
            bgColor = "#A62B2B"
            titleColor = "#FFFFFF"
            subtitleColor = "#D8D8D8"
        } else { // Dark (Default)
            bgColor = "#141414"
            titleColor = "#FFFFFF"
            subtitleColor = "#7A7A7A"
        }
    }

    Component.onCompleted: {
        updateTheme()
    }

    Rectangle {
        anchors.fill: parent
        color: root.bgColor
        Behavior on color { ColorAnimation { duration: 250 } }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            fadeOut.start()
        }
    }

    Column {
        id: logoArea

        anchors.centerIn: parent
        spacing: 18

        scale: clickArea.containsMouse ? 1.04 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Text {
            text: "Flow"

            anchors.horizontalCenter: parent.horizontalCenter

            color: root.titleColor

            font.pixelSize: 76
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering

            Behavior on color { ColorAnimation { duration: 250 } }
        }

        Text {
            text: "Touch"

            anchors.horizontalCenter: parent.horizontalCenter

            color: root.subtitleColor

            font.pixelSize: 16
            renderType: Text.NativeRendering

            Behavior on color { ColorAnimation { duration: 250 } }
        }
    }

    OpacityAnimator {
        id: fadeOut

        target: root
        from: 1
        to: 0
        duration: 500

        onFinished: {
            root.startRequested()
        }
    }
}