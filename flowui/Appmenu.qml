import QtQuick
import QtQuick.Controls

Item {
    id: menuRoot
    signal closeRequested()
    signal optionSelected(string option)
    property bool settingsOpen: false

    // ESC Key Shortcut to Close Menu
    Shortcut {
        sequence: "Esc"
        enabled: menuRoot.visible && menuRoot.opacity > 0
        onActivated: {
            if (menuRoot.settingsOpen) {
                menuRoot.settingsOpen = false
            } else {
                menuRoot.closeRequested()
            }
        }
    }

    // ==========================
    // Entry Animation
    // ==========================

    onVisibleChanged: {
        if (visible) {
            settingsOpen = false
        }
    }

    onOpacityChanged: {
        if (opacity === 1.0) {
            settingsOpen = false
            entryAnimation.start()
        }
        else {
            menuItemsColumn.yOffset = 40
        }
    }

    NumberAnimation {
        id: entryAnimation
        target: menuItemsColumn
        property: "yOffset"
        from: 40
        to: 0
        duration: 350
        easing.type: Easing.OutCubic
    }



    // ==========================
    // Overlay Background
    // ==========================

    Rectangle {
        anchors.fill: parent
        color: "#CC141414"
        MouseArea {
            z: 0
            anchors.fill: parent
            onClicked: {
                menuRoot.settingsOpen = false
                menuRoot.closeRequested()
            }
        }
    }


    // ==========================
    // Menu Items
    // ==========================

    Column {
        id: menuItemsColumn
        anchors.centerIn: parent
        spacing: 32
        property real yOffset: 40

        transform: Translate {
            y: menuItemsColumn.yOffset
        }

        Repeater {
                model: menuRoot.settingsOpen
                ?
                [
                        {
                        num:"01",
                        name:"System Color"
                        },
                        {
                        num:"02",
                        name:"Category"
                        }
                ]
                :
                [
                        {
                        num:"01",
                        name:"Year Setting"
                        },

                        {
                        num:"02",
                        name:"Settings"
                        },
                        {
                        num:"03",
                        name:"Exit"
                        }
                ]


            delegate: Item {
                width: 420
                height: 64

                HoverHandler {
                    id: itemHover
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 24
                    x: itemHover.hovered ? 16 : 0

                    Behavior on x {
                        NumberAnimation {
                            duration: 220
                            easing.type:Easing.OutCubic
                        }
                    }

                    Text {
                        text:modelData.num
                        color:itemHover.hovered
                              ? "#FFFFFF"
                              : "#555555"
                        font.pixelSize:16
                        font.bold:true
                    }

                    Text {
                        id:titleText
                        text:modelData.name
                        color:itemHover.hovered
                              ? "#FFFFFF"
                              : "#888888"

                        font.pixelSize:38
                        font.bold:true
                        font.letterSpacing:1
                        Behavior on color {
                            ColorAnimation {
                                duration:150
                            }
                        }
                    }
                }

                // Hover Indicator
                Rectangle {
                    width:4
                    height:30
                    anchors {
                        left:parent.left
                        verticalCenter:parent.verticalCenter
                    }
                    color:"#FFFFFF"
                    opacity:itemHover.hovered ? 1 : 0
                    scale:itemHover.hovered ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration:150
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration:200
                            easing.type:Easing.OutBack
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if(modelData.name === "Settings") {
                            menuRoot.settingsOpen = true
                        }
                        else {
                            menuRoot.optionSelected(
                                modelData.name
                            )
                        }
                    }
                }
            }
        }
    }
}