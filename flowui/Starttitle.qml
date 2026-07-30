import QtQuick
import QtQuick.Controls

Item {
    id: root

    signal startRequested()

    Rectangle {
        anchors.fill: parent
        color: "#141414"
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

            color: "white"

            font.pixelSize: 76
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }

        Text {
            text: "Touch"

            anchors.horizontalCenter: parent.horizontalCenter

            color: "#7A7A7A"

            font.pixelSize: 16
            renderType: Text.NativeRendering
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