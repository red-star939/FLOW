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
    signal themeSelected(string mainBg, string cardBg, string borderCol, string textCol, string badgeBg, string dashBg, string idCardBg, int themeIdx)

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
        height: 660
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

            // 9 Cards Section (Card 1: Original Dark, Cards 2~9: System Colors)
            Column {
                width: parent.width
                spacing: 14

                Text {
                    text: "시스템 테마 색상 카드 (Theme Cards)"
                    color: "#8E8E93"
                    font.pixelSize: 12
                    font.bold: true
                }

                // 9 Cards Grid (3 Columns x 3 Rows, Height 145)
                Grid {
                    columns: 3
                    spacing: 14
                    width: parent.width

                    Repeater {
                        model: 9

                        delegate: Rectangle {
                            id: themeCard
                            width: (parent.width - 28) / 3
                            height: 145
                            radius: 16
                             color: index === 0 ? "#141414" : (index === 1 ? "#366256" : (index === 2 ? "#872115" : (index === 3 ? "#253874" : (index === 4 ? "#C3D5D7" : (index === 5 ? "#B9A69B" : (index === 6 ? "#C48D8B" : (index === 7 ? "#FFC001" : (index === 8 ? "#646289" : (cardHover.containsMouse ? "#2A2A2A" : (colorsetRoot.selectedCardIndex === index ? "#262626" : "#1A1A1A"))))))))))
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

                             // Card 2 Content (Deep Forest Theme Preview #366256)
                             Column {
                                 anchors.centerIn: parent
                                 spacing: 12
                                 visible: index === 1

                                 // 5 Color Circles (1. #E6ECE9, 2. #527E72, 3. #090A0B, 4. #527E72, 5. #366256)
                                 Row {
                                     anchors.horizontalCenter: parent.horizontalCenter
                                     spacing: 5

                                     // 1. 카드 배경색 (#E6ECE9)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#E6ECE9"
                                         border.width: 1
                                         border.color: "#C5D4CE"
                                     }

                                     // 2. 테두리색 (#527E72)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#527E72"
                                     }

                                     // 3. 글자색 (#090A0B)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#090A0B"
                                     }

                                     // 4. 블록명 뱃지색 (#527E72)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#527E72"
                                     }

                                     // 5. 상/하단 대시보드 색 (#366256)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#366256"
                                         border.width: 1
                                         border.color: "#284A41"
                                     }
                                 }

                                 Column {
                                     spacing: 3
                                     anchors.horizontalCenter: parent.horizontalCenter

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "Deep Forest"
                                         color: "#FFFFFF"
                                         font.pixelSize: 13
                                         font.bold: true
                                     }

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "(딥 포레스트 테마)"
                                         color: "#D5E3DF"
                                         font.pixelSize: 10
                                     }
                                 }
                             }

                             // Card 3 Content (Carmine Red Theme Preview)
                             Column {
                                 anchors.centerIn: parent
                                 spacing: 12
                                 visible: index === 2

                                 // 5 Color Circles (1. #221616, 2. #B83E3E, 3. #FFFFFF, 4. #B83E3E, 5. #A62B2B)
                                 Row {
                                     anchors.horizontalCenter: parent.horizontalCenter
                                     spacing: 5

                                     // 1. 카드 배경색 (#221616)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#221616"
                                         border.width: 1
                                         border.color: "#552222"
                                     }

                                     // 2. 테두리색 (#B83E3E)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#B83E3E"
                                     }

                                     // 3. 글자색 (#FFFFFF)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#FFFFFF"
                                     }

                                     // 4. 블록명 뱃지색 (#B83E3E)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#B83E3E"
                                     }

                                     // 5. 상/하단 대시보드 색 (#872115)
                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#872115"
                                         border.width: 1
                                         border.color: "#5C150D"
                                     }
                                 }

                                 Column {
                                     spacing: 3
                                     anchors.horizontalCenter: parent.horizontalCenter

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "Classic Carmine"
                                         color: "#FFFFFF"
                                         font.pixelSize: 13
                                         font.bold: true
                                     }

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "(클래식 카민 테마)"
                                         color: "#D8D8D8"
                                         font.pixelSize: 10
                                     }
                                 }
                             }

                             // Card 4 Content (Deep Navy Theme Preview #253874)
                             Column {
                                 anchors.centerIn: parent
                                 spacing: 12
                                 visible: index === 3

                                 // 5 Color Circles (1. #161F38, 2. #3B5295, 3. #FFFFFF, 4. #3B5295, 5. #253874)
                                 Row {
                                     anchors.horizontalCenter: parent.horizontalCenter
                                     spacing: 5

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#161F38"
                                         border.width: 1
                                         border.color: "#3B5295"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#3B5295"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#FFFFFF"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#3B5295"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#253874"
                                         border.width: 1
                                         border.color: "#4A68BD"
                                     }
                                 }

                                 Column {
                                     spacing: 3
                                     anchors.horizontalCenter: parent.horizontalCenter

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "Midnight Blue"
                                         color: "#FFFFFF"
                                         font.pixelSize: 13
                                         font.bold: true
                                     }

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "(미드나이트 블루 테마)"
                                         color: "#A2B5E8"
                                         font.pixelSize: 10
                                     }
                                 }
                             }

                             // Card 5 Content (Ice Blue Theme Preview #C3D5D7)
                             Column {
                                 anchors.centerIn: parent
                                 spacing: 12
                                 visible: index === 4

                                 // 5 Color Circles (1. #EAF1F2, 2. #9BB6B9, 3. #101D20, 4. #7A9EA3, 5. #C3D5D7)
                                 Row {
                                     anchors.horizontalCenter: parent.horizontalCenter
                                     spacing: 5

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#EAF1F2"
                                         border.width: 1
                                         border.color: "#9BB6B9"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#9BB6B9"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#101D20"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#7A9EA3"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#C3D5D7"
                                         border.width: 1
                                         border.color: "#A0B8BB"
                                     }
                                 }

                                 Column {
                                     spacing: 3
                                     anchors.horizontalCenter: parent.horizontalCenter

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "Wind Soft"
                                         color: "#101D20"
                                         font.pixelSize: 13
                                         font.bold: true
                                     }

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "(윈드 소프트 테마)"
                                         color: "#547377"
                                         font.pixelSize: 10
                                     }
                                 }
                             }

                             // Card 6 Content (Warm Taupe Theme Preview #B9A69B)
                             Column {
                                 anchors.centerIn: parent
                                 spacing: 12
                                 visible: index === 5

                                 // 5 Color Circles (1. #F5F0ED, 2. #968378, 3. #221A16, 4. #968378, 5. #B9A69B)
                                 Row {
                                     anchors.horizontalCenter: parent.horizontalCenter
                                     spacing: 5

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#F5F0ED"
                                         border.width: 1
                                         border.color: "#968378"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#968378"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#221A16"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#968378"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#B9A69B"
                                         border.width: 1
                                         border.color: "#857369"
                                     }
                                 }

                                 Column {
                                     spacing: 3
                                     anchors.horizontalCenter: parent.horizontalCenter

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "Warm Taupe"
                                         color: "#FFFFFF"
                                         font.pixelSize: 13
                                         font.bold: true
                                     }

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "(웜 토프 테마)"
                                         color: "#EAE3DE"
                                         font.pixelSize: 10
                                     }
                                 }
                             }

                             // Card 7 Content (Dusty Rose Theme Preview #C48D8B)
                             Column {
                                 anchors.centerIn: parent
                                 spacing: 12
                                 visible: index === 6

                                 // 5 Color Circles (1. #F7EFEB, 2. #A66E6C, 3. #261817, 4. #A66E6C, 5. #C48D8B)
                                 Row {
                                     anchors.horizontalCenter: parent.horizontalCenter
                                     spacing: 5

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#F7EFEB"
                                         border.width: 1
                                         border.color: "#A66E6C"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#A66E6C"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#261817"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#A66E6C"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#C48D8B"
                                         border.width: 1
                                         border.color: "#965E5C"
                                     }
                                 }

                                 Column {
                                     spacing: 3
                                     anchors.horizontalCenter: parent.horizontalCenter

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "Dusty Rose"
                                         color: "#FFFFFF"
                                         font.pixelSize: 13
                                         font.bold: true
                                     }

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "(더스티 로즈 테마)"
                                         color: "#F2E1E0"
                                         font.pixelSize: 10
                                     }
                                 }
                             }

                             // Card 8 Content (Amber Gold Theme Preview #FFC001)
                             Column {
                                 anchors.centerIn: parent
                                 spacing: 12
                                 visible: index === 7

                                 // 5 Color Circles (1. #FFFBF0, 2. #D9A300, 3. #1E1A00, 4. #D9A300, 5. #FFC001)
                                 Row {
                                     anchors.horizontalCenter: parent.horizontalCenter
                                     spacing: 5

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#FFFBF0"
                                         border.width: 1
                                         border.color: "#D9A300"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#D9A300"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#1E1A00"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#D9A300"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#FFC001"
                                         border.width: 1
                                         border.color: "#C99700"
                                     }
                                 }

                                 Column {
                                     spacing: 3
                                     anchors.horizontalCenter: parent.horizontalCenter

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "Amber Gold"
                                         color: "#1E1A00"
                                         font.pixelSize: 13
                                         font.bold: true
                                     }

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "(엠버 골드 테마)"
                                         color: "#664F00"
                                         font.pixelSize: 10
                                     }
                                 }
                             }

                             // Card 9 Content (Twilight Purple Theme Preview #646289)
                             Column {
                                 anchors.centerIn: parent
                                 spacing: 12
                                 visible: index === 8

                                 // 5 Color Circles (1. #1E1C2E, 2. #8A87B3, 3. #FFFFFF, 4. #8A87B3, 5. #646289)
                                 Row {
                                     anchors.horizontalCenter: parent.horizontalCenter
                                     spacing: 5

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#1E1C2E"
                                         border.width: 1
                                         border.color: "#8A87B3"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#8A87B3"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#FFFFFF"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#8A87B3"
                                     }

                                     Rectangle {
                                         width: 20
                                         height: 20
                                         radius: 10
                                         color: "#646289"
                                         border.width: 1
                                         border.color: "#4C4A6E"
                                     }
                                 }

                                 Column {
                                     spacing: 3
                                     anchors.horizontalCenter: parent.horizontalCenter

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "Twilight Purple"
                                         color: "#FFFFFF"
                                         font.pixelSize: 13
                                         font.bold: true
                                     }

                                     Text {
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         text: "(트와일라잇 퍼플 테마)"
                                         color: "#D2D0E6"
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
                                         colorsetRoot.themeSelected("#141414", "#1F1F1F", "#343434", "#FFFFFF", "#222222", "#141414", "#1F1F1F", 0)
                                     } else if (index === 1) {
                                         colorsetRoot.currentSystemColor = "#366256"
                                         colorsetRoot.currentAccentColor = "#527E72"
                                         colorsetRoot.themeSelected("#366256", "#E6ECE9", "#527E72", "#090A0B", "#527E72", "#366256", "#527E72", 1)
                                     } else if (index === 2) {
                                         colorsetRoot.currentSystemColor = "#872115"
                                         colorsetRoot.currentAccentColor = "#A83223"
                                         colorsetRoot.themeSelected("#872115", "#221616", "#FFFFFF", "#FFFFFF", "#A83223", "#872115", "#331E1E", 2)
                                     } else if (index === 3) {
                                         colorsetRoot.currentSystemColor = "#253874"
                                         colorsetRoot.currentAccentColor = "#3B5295"
                                         colorsetRoot.themeSelected("#253874", "#161F38", "#FFFFFF", "#FFFFFF", "#3B5295", "#253874", "#1A2544", 3)
                                     } else if (index === 4) {
                                         colorsetRoot.currentSystemColor = "#C3D5D7"
                                         colorsetRoot.currentAccentColor = "#7A9EA3"
                                         colorsetRoot.themeSelected("#C3D5D7", "#EAF1F2", "#9BB6B9", "#101D20", "#7A9EA3", "#C3D5D7", "#D4E3E5", 4)
                                     } else if (index === 5) {
                                         colorsetRoot.currentSystemColor = "#B9A69B"
                                         colorsetRoot.currentAccentColor = "#968378"
                                         colorsetRoot.themeSelected("#B9A69B", "#F5F0ED", "#968378", "#221A16", "#968378", "#B9A69B", "#968378", 5)
                                     } else if (index === 6) {
                                         colorsetRoot.currentSystemColor = "#C48D8B"
                                         colorsetRoot.currentAccentColor = "#A66E6C"
                                         colorsetRoot.themeSelected("#C48D8B", "#F7EFEB", "#A66E6C", "#261817", "#A66E6C", "#C48D8B", "#A66E6C", 6)
                                     } else if (index === 7) {
                                         colorsetRoot.currentSystemColor = "#FFC001"
                                         colorsetRoot.currentAccentColor = "#D9A300"
                                         colorsetRoot.themeSelected("#FFC001", "#FFFBF0", "#D9A300", "#1E1A00", "#D9A300", "#FFC001", "#E5AD00", 7)
                                     } else if (index === 8) {
                                         colorsetRoot.currentSystemColor = "#646289"
                                         colorsetRoot.currentAccentColor = "#8A87B3"
                                         colorsetRoot.themeSelected("#646289", "#1E1C2E", "#8A87B3", "#FFFFFF", "#8A87B3", "#646289", "#29263D", 8)
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
