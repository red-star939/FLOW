import QtQuick
import QtQuick.Controls

Item {
    id: yearsetRoot
    anchors.fill: parent

    signal closeRequested()
    signal applied(int startYear, int endYear)

    // ESC Key Shortcut to Close Yearset Menu
    Shortcut {
        sequence: "Esc"
        enabled: yearsetRoot.visible && yearsetRoot.opacity > 0
        onActivated: {
            yearsetRoot.closeRequested()
        }
    }

    property int tempStartYear: (typeof dbController !== "undefined" && dbController.startYear > 0) ? dbController.startYear : 2020
    property int tempEndYear: (typeof dbController !== "undefined" && dbController.endYear > 0) ? dbController.endYear : 2030
    readonly property bool isValidRange: tempStartYear <= tempEndYear

    onVisibleChanged: {
        if (visible) {
            syncFromBackend()
            cardScaleAnim.start()
        }
    }

    Component.onCompleted: {
        syncFromBackend()
    }

    function syncFromBackend() {
        if (typeof dbController !== "undefined") {
            if (dbController.startYear > 0) tempStartYear = dbController.startYear
            if (dbController.endYear > 0) tempEndYear = dbController.endYear
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
                yearsetRoot.closeRequested()
            }
        }
    }

    // ==========================
    // Modal Dialog Card
    // ==========================
    Rectangle {
        id: card
        width: 480
        height: 400
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

        // Prevent mouse clicks inside the card from closing the modal
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            anchors {
                fill: parent
                margins: 32
            }
            spacing: 24

            // Header Section
            Row {
                spacing: 16
                width: parent.width

                Text {
                    text: "01"
                    color: "#555555"
                    font.pixelSize: 18
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Year Setting"
                    color: "#FFFFFF"
                    font.pixelSize: 26
                    font.bold: true
                    font.letterSpacing: 0.5
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: "Specify the starting and ending year range for database operations."
                color: "#888888"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                width: parent.width
            }

            // Year Inputs Section
            Row {
                width: parent.width
                spacing: 20

                // Start Year Input Block
                Column {
                    width: (parent.width - parent.spacing) / 2
                    spacing: 8

                    Text {
                        text: "START YEAR"
                        color: "#AAAAAA"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    Rectangle {
                        width: parent.width
                        height: 52
                        radius: 12
                        color: "#181818"
                        border.width: 1
                        border.color: startInput.activeFocus ? "#FFFFFF" : "#333333"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 6

                            // Decrement Button
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 8
                                color: decStartBtn.containsMouse ? "#323232" : "#222222"
                                Text {
                                    anchors.centerIn: parent
                                    text: "-"
                                    color: "#FFFFFF"
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                                MouseArea {
                                    id: decStartBtn
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (tempStartYear > 1900) tempStartYear--
                                    }
                                }
                            }

                            // Numeric Display / Editable Text
                            TextInput {
                                id: startInput
                                width: parent.width - 80
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: tempStartYear.toString()
                                color: "#FFFFFF"
                                font.pixelSize: 18
                                font.bold: true
                                selectByMouse: true
                                validator: IntValidator { bottom: 1900; top: 2999 }
                                onEditingFinished: {
                                    var val = parseInt(text)
                                    if (!isNaN(val) && val >= 1900 && val <= 2999) {
                                        tempStartYear = val
                                    } else {
                                        text = tempStartYear.toString()
                                    }
                                }
                            }

                            // Increment Button
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 8
                                color: incStartBtn.containsMouse ? "#323232" : "#222222"
                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: "#FFFFFF"
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                MouseArea {
                                    id: incStartBtn
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (tempStartYear < 2999) tempStartYear++
                                    }
                                }
                            }
                        }
                    }
                }

                // End Year Input Block
                Column {
                    width: (parent.width - parent.spacing) / 2
                    spacing: 8

                    Text {
                        text: "END YEAR"
                        color: "#AAAAAA"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    Rectangle {
                        width: parent.width
                        height: 52
                        radius: 12
                        color: "#181818"
                        border.width: 1
                        border.color: endInput.activeFocus ? "#FFFFFF" : "#333333"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 6

                            // Decrement Button
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 8
                                color: decEndBtn.containsMouse ? "#323232" : "#222222"
                                Text {
                                    anchors.centerIn: parent
                                    text: "-"
                                    color: "#FFFFFF"
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                                MouseArea {
                                    id: decEndBtn
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (tempEndYear > 1900) tempEndYear--
                                    }
                                }
                            }

                            // Numeric Display / Editable Text
                            TextInput {
                                id: endInput
                                width: parent.width - 80
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: tempEndYear.toString()
                                color: "#FFFFFF"
                                font.pixelSize: 18
                                font.bold: true
                                selectByMouse: true
                                validator: IntValidator { bottom: 1900; top: 2999 }
                                onEditingFinished: {
                                    var val = parseInt(text)
                                    if (!isNaN(val) && val >= 1900 && val <= 2999) {
                                        tempEndYear = val
                                    } else {
                                        text = tempEndYear.toString()
                                    }
                                }
                            }

                            // Increment Button
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 8
                                color: incEndBtn.containsMouse ? "#323232" : "#222222"
                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: "#FFFFFF"
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                MouseArea {
                                    id: incEndBtn
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (tempEndYear < 2999) tempEndYear++
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Span Info & Validation Message
            Rectangle {
                width: parent.width
                height: 36
                radius: 8
                color: yearsetRoot.isValidRange ? "#1A2A1A" : "#2A1A1A"
                border.width: 1
                border.color: yearsetRoot.isValidRange ? "#2E4E2E" : "#4E2E2E"

                Text {
                    anchors.centerIn: parent
                    text: yearsetRoot.isValidRange
                          ? "Configured Span: " + (tempEndYear - tempStartYear + 1) + " Years (" + tempStartYear + " ~ " + tempEndYear + ")"
                          : "Invalid: Start Year must be less than or equal to End Year"
                    color: yearsetRoot.isValidRange ? "#88E088" : "#E08888"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            // Action Buttons
            Row {
                width: parent.width
                spacing: 12

                // Cancel Button
                Rectangle {
                    width: (parent.width - parent.spacing) / 2
                    height: 46
                    radius: 12
                    color: cancelBtn.containsMouse ? "#2C2C2C" : "#222222"
                    border.width: 1
                    border.color: "#383838"

                    Text {
                        anchors.centerIn: parent
                        text: "CANCEL"
                        color: "#AAAAAA"
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    MouseArea {
                        id: cancelBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            yearsetRoot.closeRequested()
                        }
                    }
                }

                // Apply Button
                Rectangle {
                    width: (parent.width - parent.spacing) / 2
                    height: 46
                    radius: 12
                    color: !yearsetRoot.isValidRange
                           ? "#444444"
                           : (applyBtn.containsMouse ? "#E6E6E6" : "#FFFFFF")
                    opacity: yearsetRoot.isValidRange ? 1.0 : 0.4

                    Text {
                        anchors.centerIn: parent
                        text: "APPLY"
                        color: "#141414"
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    MouseArea {
                        id: applyBtn
                        anchors.fill: parent
                        enabled: yearsetRoot.isValidRange
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        onClicked: {
                            if (typeof dbController !== "undefined") {
                                dbController.configureYearRange(tempStartYear, tempEndYear)
                            }
                            yearsetRoot.applied(tempStartYear, tempEndYear)
                            yearsetRoot.closeRequested()
                        }
                    }
                }
            }
        }
    }
}
