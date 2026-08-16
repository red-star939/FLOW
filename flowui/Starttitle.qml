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
        if (idx === 1) { // Deep Forest (#366256)
            bgColor = "#366256"
            titleColor = "#FFFFFF"
            subtitleColor = "#D5E3DF"
        } else if (idx === 2) { // Classic Carmine (#872115)
            bgColor = "#872115"
            titleColor = "#FFFFFF"
            subtitleColor = "#D8D8D8"
        } else if (idx === 3) { // Midnight Blue
            bgColor = "#253874"
            titleColor = "#FFFFFF"
            subtitleColor = "#A2B5E8"
        } else if (idx === 4) { // Wind Soft (#C3D5D7)
            bgColor = "#C3D5D7"
            titleColor = "#101D20"
            subtitleColor = "#547377"
        } else if (idx === 5) { // Warm Taupe (#B9A69B)
            bgColor = "#B9A69B"
            titleColor = "#FFFFFF"
            subtitleColor = "#EAE3DE"
        } else if (idx === 6) { // Dusty Rose (#C48D8B)
            bgColor = "#C48D8B"
            titleColor = "#FFFFFF"
            subtitleColor = "#F2E1E0"
        } else if (idx === 7) { // Amber Gold (#FFC001)
            bgColor = "#FFC001"
            titleColor = "#1E1A00"
            subtitleColor = "#664F00"
        } else if (idx === 8) { // Twilight Purple (#646289)
            bgColor = "#646289"
            titleColor = "#FFFFFF"
            subtitleColor = "#D2D0E6"
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