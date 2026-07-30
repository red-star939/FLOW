import QtQuick
import QtQuick.Controls

Item {
    id: colorsetRoot
    anchors.fill: parent

    signal closeRequested()

    // ESC Key Shortcut to Close Colorset Menu
    Shortcut {
        sequence: "Esc"
        enabled: colorsetRoot.visible && colorsetRoot.opacity > 0
        onActivated: {
            colorsetRoot.closeRequested()
        }
    }
    signal colorSelected(string mainColor, string accentColor)
    signal themeSelected(string mainBg, string cardBg, string borderCol, string textCol, string badgeBg, string dashBg, string idCardBg)

    property string currentSystemColor: "#141414"
    property string currentAccentColor: "#00E5FF"
    property int selectedCardIndex: 0

    Component.onCompleted: {
        if (typeof dbController !== "undefined" && typeof dbController.getSavedThemeIndex === "function") {
            selectedCardIndex = dbController.getSavedThemeIndex();
        }
    }

    onVisibleChanged: {
        if (visible) {
            cardScaleAnim.start()
        }
    }

    // ==========================
    // Overlay Background
    // ==========================
    Rectangle {
        anchors.fill: parent
        color: "#CC141414"

        MouseArea {
            anchors.fill: parent
            onClicked: {
                colorsetRoot.closeRequested()
            }
        }
    }

    // ==========================
    // Modal Dialog Card
    // ==========================
    Rectangle {
        id: card
        width: 580
        height: 620
        anchors.centerIn: parent
        radius: 24
        color: "#202020"
        border.width: 1
        border.color: "#303030"

        scale: 0.95

        NumberAnimation on scale {
            id: cardScaleAnim
            from: 0.92
            to: 1.0
            duration: 250
            easing.type: Easing.OutCubic
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            anchors {
                fill: parent
                margins: 28
            }
            spacing: 20

            // Header Section
            Row {
                width: parent.width

                Row {
                    spacing: 14
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "01"
                        color: "#555555"
                        font.pixelSize: 18
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "System Color"
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.bold: true
                        font.letterSpacing: 1
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Close Button (×)
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 14
                    color: closeHover.containsMouse ? "#3A3A3A" : "#282828"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: closeHover.containsMouse ? "#FFFFFF" : "#AAAAAA"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: colorsetRoot.closeRequested()
                    }
                }
            }

            // Divider Line
            Rectangle {
                width: parent.width
                height: 1
                color: "#333333"
            }

            // 6 Cards Section (Card 1: Original System Color, Cards 2~6: Empty)
            Column {
                width: parent.width
                spacing: 14

                Text {
                    text: "시스템 테마 색상 카드 (Theme Cards)"
                    color: "#8E8E93"
                    font.pixelSize: 12
                    font.bold: true
                }

                // 6 Cards Grid (3 Columns x 2 Rows, Height 175)
                Grid {
                    columns: 3
                    spacing: 14
                    width: parent.width

                    Repeater {
                        model: 6

                        delegate: Rectangle {
                            id: themeCard
                            width: (parent.width - 28) / 3
                            height: 175
                            radius: 16
                             color: index === 0 ? "#141414" : (index === 1 ? "#578679" : (cardHover.containsMouse ? "#2A2A2A" : (colorsetRoot.selectedCardIndex === index ? "#262626" : "#1A1A1A")))
                             border.width: colorsetRoot.selectedCardIndex === index ? 2 : 1
                             border.color: colorsetRoot.selectedCardIndex === index ? "#FFFFFF" : (cardHover.containsMouse ? "#666666" : "#303030")

                             Behavior on color { ColorAnimation { duration: 150 } }
                             Behavior on border.color { ColorAnimation { duration: 150 } }

                             // Card 1 Content (Original System Color Preview)
                             Column {
                                 anchors.centerIn: parent
                                 spacing: 12
                                 visible: index === 0

                                 // 5 Color Circles (1. 카드 배경색, 2. 테두리색, 3. 글자색, 4. 블록명 뱃지색, 5. 대시보드 메인색)
                                 Row {
                                     anchors.horizontalCenter: parent.horizontalCenter
                                     spacing: 5

                                     // 1. 카드 배경색 (#1F1F1F)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#1F1F1F"
                                         border.width: 1
                                         border.color: "#444444"
                                     }

                                     // 2. 테두리색 (#343434)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#343434"
                                         border.width: 1
                                         border.color: "#555555"
                                     }

                                     // 3. 글자색 (#FFFFFF)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#FFFFFF"
                                     }

                                     // 4. 블록명 뱃지색 (#222222)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#222222"
                                         border.width: 1
                                         border.color: "#555555"
                                     }

                                     // 5. 상/하단 대시보드 색 (#141414)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#141414"
                                         border.width: 1
                                         border.color: "#555555"
                                     }
                                 }

                                 Column {
                                     spacing: 3
                                     anchors.horizontalCenter: parent.horizontalCenter

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "Original Dark"
                                         color: "#FFFFFF"
                                         font.pixelSize: 13
                                         font.bold: true
                                     }

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "(기본 시스템 색상)"
                                         color: "#888888"
                                         font.pixelSize: 10
                                     }
                                 }
                             }

                             // Card 2 Content (Sage Green Theme Preview)
                             Column {
                                 anchors.centerIn: parent
                                 spacing: 12
                                 visible: index === 1

                                 // 5 Color Circles (1. #E0D9CF, 2. #C2A17B, 3. #090A0B, 4. #819E8A, 5. #578679)
                                 Row {
                                     anchors.horizontalCenter: parent.horizontalCenter
                                     spacing: 5

                                     // 1. 카드 배경색 (#E0D9CF)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#E0D9CF"
                                         border.width: 1
                                         border.color: "#C8C0B5"
                                     }

                                     // 2. 테두리색 (#C2A17B)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#C2A17B"
                                     }

                                     // 3. 글자색 (#090A0B)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#090A0B"
                                     }

                                     // 4. 블록명 뱃지색 (#819E8A)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#819E8A"
                                     }

                                     // 5. 상/하단 대시보드 색 (#578679)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#578679"
                                         border.width: 1
                                         border.color: "#4A7367"
                                     }
                                 }

                                 Column {
                                     spacing: 3
                                     anchors.horizontalCenter: parent.horizontalCenter

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "Sage Green"
                                         color: "#FFFFFF"
                                         font.pixelSize: 13
                                         font.bold: true
                                     }

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "(내추럴 세이지 테마)"
                                         color: "#E0D9CF"
                                         font.pixelSize: 10
                                     }
                                 }
                             }

                             MouseArea {
                                 id: cardHover
                                 anchors.fill: parent
                                 hoverEnabled: true
                                 cursorShape: Qt.PointingHandCursor
                                 onClicked: {
                                     colorsetRoot.selectedCardIndex = index
                                     if (typeof dbController !== "undefined" && typeof dbController.saveThemeIndex === "function") {
                                         dbController.saveThemeIndex(index)
                                     }
                                     if (index === 0) {
                                         colorsetRoot.currentSystemColor = "#141414"
                                         colorsetRoot.currentAccentColor = "#00E5FF"
                                         colorsetRoot.themeSelected("#141414", "#1F1F1F", "#343434", "#FFFFFF", "#222222", "#141414", "#1F1F1F")
                                     } else if (index === 1) {
                                         colorsetRoot.currentSystemColor = "#578679"
                                         colorsetRoot.currentAccentColor = "#819E8A"
                                         colorsetRoot.themeSelected("#578679", "#E0D9CF", "#C2A17B", "#090A0B", "#819E8A", "#578679", "#819E8A")
                                     }
                                 }
                             }
                        }
                    }
                }
            }

            // Bottom Action Footer
            Row {
                width: parent.width

                Text {
                    text: "💡 원하시는 색상 카드를 선택하면 테마가 적용됩니다."
                    color: "#777777"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Close / Confirm Button
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 110
                    height: 36
                    radius: 10
                    color: okHover.containsMouse ? "#E0E0E0" : "#FFFFFF"

                    Text {
                        anchors.centerIn: parent
                        text: "완료"
                        color: "#121212"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        id: okHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: colorsetRoot.closeRequested()
                    }
                }
            }
        }
    }
}
