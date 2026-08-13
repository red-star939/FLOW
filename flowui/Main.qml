import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

ApplicationWindow {
    id: window

    visible: true

    width: 1180
    height: 820

    minimumWidth: 980
    minimumHeight: 700

    color: "#141414"
    title: "Flow"

    Bgdash {
        id: bgdash
        anchors.fill: parent
        onCurrentThemeIndexChanged: {
            if (startTitle) {
                startTitle.setTheme(bgdash.currentThemeIndex)
            }
        }
    }

    Starttitle {
        id: startTitle
        anchors.fill: parent
        z: 9999

        onStartRequested: {
            startTitle.visible = false
        }
    }
}