import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int blockIndex: -1
    property string uuid: ""
    property string title: "새 블록"
    property Flickable parentFlickable: null

    signal removeRequested(int index)
    signal moveRequested(int fromIndex, int toIndex)
    signal titleEdited(string newTitle)
    signal editingFinished()
    signal dataChanged()

    property int selectedYear: 2026
    property int selectedMonth: 1

    property real totalValue: 0
    property var subblocksData: []

    // Aliases for DBController compatibility
    property alias idName: root.title
    property alias subItems: root.subblocksData

    function updateTotal() {
        var sum = 0
        for (let i = 0; i < subBlockModel.count; i++) {
            var item = subBlockModel.get(i)
            if (item && item.value !== undefined && item.value !== "") {
                var val = parseFloat(item.value)
                if (!isNaN(val)) {
                    sum += val
                }
            }
        }
        totalValue = sum
    }

    property real savedScrollY: 0

    function setScrollY(yVal) {
        if (!subFlickable) return;
        smoothYAnim.enabled = false;
        subFlickable.targetContentY = yVal;
        subFlickable.contentY = yVal;
        smoothYAnim.enabled = true;
    }

    onSubblocksDataChanged: {
        var blockId = (root.uuid && root.uuid !== "") ? root.uuid : root.idName;
        var savedY = root.savedScrollY;
        if (typeof bgdashRoot !== "undefined" && typeof bgdashRoot.getSubScroll === "function") {
            var mapY = bgdashRoot.getSubScroll(blockId);
            if (mapY > 0) savedY = mapY;
        }
        if (subFlickable && subFlickable.contentY > 0) {
            savedY = subFlickable.contentY;
            root.savedScrollY = savedY;
        }
        var oldCount = subBlockModel.count

        if (subblocksData && subBlockModel.count === subblocksData.length) {
            var identical = true
            for (let i = 0; i < subblocksData.length; i++) {
                var local = subBlockModel.get(i)
                var incomingTitle = subblocksData[i].title !== undefined ? subblocksData[i].title : (subblocksData[i].subId !== undefined ? subblocksData[i].subId : "")
                var incomingVal = subblocksData[i].value !== undefined ? subblocksData[i].value.toString() : ""
                var incomingUuid = subblocksData[i].uuid !== undefined ? subblocksData[i].uuid : ""
                if (!local || local.title !== incomingTitle || local.value !== incomingVal || (incomingUuid !== "" && local.uuid !== incomingUuid)) {
                    identical = false
                    break
                }
            }
            if (identical) return
        }

        subBlockModel.clear()
        if (subblocksData) {
            for (let j = 0; j < subblocksData.length; j++) {
                subBlockModel.append({
                    "uuid": subblocksData[j].uuid !== undefined ? subblocksData[j].uuid : "",
                    "title": subblocksData[j].title !== undefined ? subblocksData[j].title : (subblocksData[j].subId !== undefined ? subblocksData[j].subId : "새 항목"),
                    "value": subblocksData[j].value !== undefined ? subblocksData[j].value.toString() : ""
                })
            }
        }

        root.updateTotal()

        Qt.callLater(function() {
            if (!subFlickable) return
            var maxFlickScroll = Math.max(0, subFlickable.contentHeight - subFlickable.height)
            if (subblocksData && subblocksData.length > oldCount) {
                root.setScrollY(maxFlickScroll)
            } else {
                root.setScrollY(Math.max(0, Math.min(maxFlickScroll, savedY)))
            }
        })
    }

    Component.onCompleted: {
        updateTotal()
        if (root.title === "" || root.title === "새 ID" || root.title.indexOf("ID ") === 0) {
            titleInput.forceActiveFocus()
            titleInput.selectAll()
        }
        var blockId = (root.uuid && root.uuid !== "") ? root.uuid : root.idName;
        if (typeof bgdashRoot !== "undefined" && typeof bgdashRoot.getSubScroll === "function") {
            var restoredY = bgdashRoot.getSubScroll(blockId);
            if (restoredY > 0) {
                root.savedScrollY = restoredY;
                Qt.callLater(function() {
                    if (subFlickable) {
                        var maxFlick = Math.max(0, subFlickable.contentHeight - subFlickable.height);
                        root.setScrollY(Math.max(0, Math.min(maxFlick, restoredY)));
                    }
                });
            }
        }
    }

    width: 280
    height: parent ? parent.height : 260

    z: dragMouseArea.pressed ? 100 : 1

    readonly property bool isBblock: true
    readonly property bool dragActive: dragMouseArea.pressed
    readonly property real dragXOffset: contentWrapper.x

    readonly property bool parentHasDraggingItem: {
        if (!root.parent) return false
        var siblings = root.parent.children
        for (let i = 0; i < siblings.length; i++) {
            var sib = siblings[i]
            if (sib && typeof sib.isBblock !== "undefined" && sib.isBblock && sib.dragActive) {
                return true
            }
        }
        return false
    }

    readonly property real visualShift: {
        if (!root.parent) return 0

        var draggingItem = null
        var siblings = root.parent.children
        for (let i = 0; i < siblings.length; i++) {
            var sib = siblings[i]
            if (sib && typeof sib.isBblock !== "undefined" && sib.isBblock && sib.dragActive) {
                draggingItem = sib
                break
            }
        }

        if (!draggingItem || draggingItem === root) {
            return 0
        }

        var dragIndex = draggingItem.blockIndex
        var myIndex = root.blockIndex
        var dragX = draggingItem.x + draggingItem.dragXOffset
        var myX = root.x
        var colWidthWithSpacing = root.width + 16

        if (dragIndex < myIndex && dragX > myX - colWidthWithSpacing / 2) {
            return -colWidthWithSpacing
        } else if (dragIndex > myIndex && dragX < myX + colWidthWithSpacing / 2) {
            return colWidthWithSpacing
        }

        return 0
    }

    // Internal sub-block data model
    ListModel {
        id: subBlockModel
    }

    // Visual card container
    Rectangle {
        id: contentWrapper
        width: root.width
        height: root.height
        x: 0

        radius: 16
        color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeDashBg : "#141414"
        border.width: 1.5
        border.color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeBorderColor : "#343434"

        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }

        transform: Translate {
            x: root.visualShift
            Behavior on x {
                enabled: root.parentHasDraggingItem
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: {
                titleInput.focus = false
            }
        }

        // Header
        Rectangle {
            id: header
            width: parent.width
            height: 46
            radius: 18
            color: "transparent"

            // ─── Circular Pill Title Container & Category Selector ───
            Rectangle {
                id: titlePillBadge
                anchors.centerIn: parent
                height: 32
                width: Math.max(90, titleTxt.implicitWidth + 28)
                radius: 16
                color: titleHover.containsMouse ? (typeof bgdashRoot !== "undefined" && bgdashRoot.currentThemeIndex === 2 ? "#FFFFFF" : "#2A2A2A") : (typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTitleBadgeBg : "#222222")
                border.width: 1.5
                border.color: (typeof bgdashRoot !== "undefined" && bgdashRoot.currentThemeIndex === 2) ? "#FFFFFF" : (titlePopup.visible ? "#FFFFFF" : (titleHover.containsMouse ? "#555555" : "#343434"))
                scale: titleHover.containsMouse ? 1.12 : 1.0
                z: titlePopup.visible ? 10 : 1

                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                Text {
                    id: titleTxt
                    anchors.centerIn: parent
                    text: root.title
                    color: (titleHover.containsMouse && typeof bgdashRoot !== "undefined" && bgdashRoot.currentThemeIndex === 2) ? "#121212" : (typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF")
                    font.pixelSize: 16
                    font.bold: true
                    Behavior on color { ColorAnimation { duration: 250 } }
                }

                MouseArea {
                    id: titleHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        titlePopup.loadCategories()
                        titlePopup.open()
                    }
                }

                // ─── ID Category Selector Popover Popup ───
                Popup {
                    id: titlePopup
                    parent: Overlay.overlay
                    width: 170
                    padding: 10
                    modal: false
                    focus: true
                    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

                    property var categoryItems: ["월급", "고정지출", "당일지출"]

                    function updatePosition() {
                        if (!titlePillBadge.Window || !titlePillBadge.Window.window) return
                        var rootOverlay = titlePillBadge.Window.window.contentItem
                        var globalPos = titlePillBadge.mapToItem(rootOverlay, 0, 0)
                        var winHeight = titlePillBadge.Window.window.height
                        var winWidth = titlePillBadge.Window.window.width
                        var popHeight = titlePopup.implicitHeight
                        var popWidth = titlePopup.width

                        var targetX = globalPos.x
                        if (targetX + popWidth > winWidth - 10) {
                            targetX = winWidth - popWidth - 10
                        }
                        if (targetX < 10) targetX = 10
                        titlePopup.x = targetX

                        if (globalPos.y + titlePillBadge.height + popHeight > winHeight - 20) {
                            titlePopup.y = globalPos.y - popHeight - 6
                        } else {
                            titlePopup.y = globalPos.y + titlePillBadge.height + 6
                        }
                    }

                    onAboutToShow: updatePosition()

                    function loadCategories() {
                        var list = ["월급", "고정지출", "당일지출"]
                        if (typeof dbController !== "undefined" && typeof dbController.getCategoryList === "function") {
                            var saved = dbController.getCategoryList("ID")
                            if (saved && saved.length > 0) {
                                list = saved.filter(function(item) { return item !== "기타"; })
                            }
                        }
                        categoryItems = list
                        updatePosition()
                    }

                    background: Rectangle {
                        radius: 12
                        color: "#1F1F1F"
                        border.width: 1.5
                        border.color: "#343434"
                    }

                    Column {
                        id: popupCol
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "카테고리 선택"
                            color: "#777777"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        // Category Items Scrollable List
                        Flickable {
                            width: parent.width
                            height: Math.min(100, catListCol.height)
                            contentHeight: catListCol.height
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: catListCol
                                width: parent.width
                                spacing: 3

                                Repeater {
                                    model: titlePopup.categoryItems

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 30
                                        radius: 6
                                        color: catItemHover.containsMouse ? "#3A3A3A" : "transparent"

                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData
                                            color: "#FFFFFF"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: catItemHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.title = modelData
                                                root.titleEdited(modelData)
                                                root.editingFinished()
                                                titlePopup.close()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#343434"
                        }

                        Column {
                            width: parent.width
                            spacing: 4

                            Text {
                                text: "직접 입력"
                                color: "#777777"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Rectangle {
                                width: parent.width
                                height: 30
                                radius: 6
                                color: "#151515"
                                border.width: 1
                                border.color: directInputField.activeFocus ? "#FFFFFF" : "#343434"

                                TextField {
                                    id: directInputField
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    verticalAlignment: TextInput.AlignVCenter
                                    placeholderText: "블록명 입력..."
                                    placeholderTextColor: "#666666"
                                    color: "#FFFFFF"
                                    font.pixelSize: 12
                                    font.bold: true
                                    background: Rectangle { color: "transparent" }

                                    onAccepted: {
                                        var trimmed = text.trim()
                                        if (trimmed !== "") {
                                            root.title = trimmed
                                            root.titleEdited(trimmed)
                                            root.editingFinished()
                                        }
                                        titlePopup.close()
                                    }

                                    Keys.onReturnPressed: {
                                        var trimmed = text.trim()
                                        if (trimmed !== "") {
                                            root.title = trimmed
                                            root.titleEdited(trimmed)
                                            root.editingFinished()
                                        }
                                        titlePopup.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Sub-block content area (scrollable)
        Flickable {
            id: subFlickable
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: footer.top
                topMargin: 4
                leftMargin: 0
                rightMargin: 0
                bottomMargin: 4
            }
            clip: true
            contentHeight: subColumn.height
            boundsBehavior: Flickable.DragAndOvershootBounds
            flickDeceleration: 1500
            maximumFlickVelocity: 3000
            flickableDirection: Flickable.VerticalFlick

            property real targetContentY: contentY

            Behavior on targetContentY {
                id: smoothYAnim
                enabled: !subFlickable.moving && !subFlickable.dragging
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutQuad
                }
            }

            onTargetContentYChanged: {
                if (!subFlickable.moving && !subFlickable.dragging) {
                    subFlickable.contentY = targetContentY;
                }
            }

            onContentYChanged: {
                if (subFlickable.moving || subFlickable.flicking || subFlickable.dragging) {
                    subFlickable.targetContentY = subFlickable.contentY;
                    root.savedScrollY = subFlickable.contentY;
                    var blockId = (root.uuid && root.uuid !== "") ? root.uuid : root.idName;
                    if (typeof bgdashRoot !== "undefined" && typeof bgdashRoot.setSubScroll === "function") {
                        bgdashRoot.setSubScroll(blockId, subFlickable.contentY);
                    }
                }
            }

            // Mouse Wheel Smooth iPhone-Style Inertia Scroll
            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.NoButton
                onWheel: (wheel) => {
                    var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                    if (delta !== 0) {
                        var maxFlickScroll = Math.max(0, subFlickable.contentHeight - subFlickable.height)
                        var step = delta * 1.1
                        var newTarget = Math.max(0, Math.min(maxFlickScroll, subFlickable.targetContentY - step))
                        subFlickable.targetContentY = newTarget
                        root.savedScrollY = newTarget
                        var blockId = (root.uuid && root.uuid !== "") ? root.uuid : root.idName
                        if (typeof bgdashRoot !== "undefined" && typeof bgdashRoot.setSubScroll === "function") {
                            bgdashRoot.setSubScroll(blockId, newTarget)
                        }
                    }
                }
            }

            Column {
                id: subColumn
                width: parent.width
                spacing: 8

                Repeater {
                    model: subBlockModel

                    delegate: SubIDblock {
                        blockIndex: index
                        uuid: model.uuid !== undefined ? model.uuid : ""
                        parentFlickable: subFlickable
                        title: model.title !== undefined ? model.title : "새 항목"
                        value: model.value !== undefined ? model.value : ""

                        onTitleEdited: function(newTitle) {
                            var targetSubUuid = (uuid && uuid !== "") ? uuid : (model.uuid !== undefined ? model.uuid : model.title)
                            subBlockModel.setProperty(index, "title", newTitle)
                            root.updateTotal()
                            root.dataChanged()
                            if (typeof dbController !== "undefined" && root.selectedYear > 0) {
                                var val = parseFloat(model.value !== undefined ? model.value : "0")
                                if (isNaN(val)) val = 0.0
                                var parentBlockId = (root.uuid && root.uuid !== "") ? root.uuid : root.idName
                                if (typeof bgdashRoot !== "undefined") bgdashRoot.isInternalEdit = true;
                                dbController.updateSubID(root.selectedYear, root.selectedMonth, parentBlockId, targetSubUuid, newTitle, val)
                                if (typeof bgdashRoot !== "undefined") bgdashRoot.isInternalEdit = false;
                            }
                        }
                        onValueInputRealtime: function(newValue) {
                            var targetSubUuid = (uuid && uuid !== "") ? uuid : (model.uuid !== undefined ? model.uuid : model.title)
                            subBlockModel.setProperty(index, "value", newValue)
                            root.updateTotal()
                            root.dataChanged()
                            if (typeof dbController !== "undefined" && root.selectedYear > 0) {
                                var t = model.title !== undefined ? model.title : "새 항목"
                                var val = parseFloat(newValue)
                                if (isNaN(val)) val = 0.0
                                var parentBlockId = (root.uuid && root.uuid !== "") ? root.uuid : root.idName
                                if (typeof bgdashRoot !== "undefined") bgdashRoot.isInternalEdit = true;
                                dbController.updateSubID(root.selectedYear, root.selectedMonth, parentBlockId, targetSubUuid, t, val)
                            }
                        }
                        onValueEdited: function(newValue) {
                            var targetSubUuid = (uuid && uuid !== "") ? uuid : (model.uuid !== undefined ? model.uuid : model.title)
                            subBlockModel.setProperty(index, "value", newValue)
                            root.updateTotal()
                            root.dataChanged()
                            if (typeof dbController !== "undefined" && root.selectedYear > 0) {
                                var t = model.title !== undefined ? model.title : "새 항목"
                                var val = parseFloat(newValue)
                                if (isNaN(val)) val = 0.0
                                var parentBlockId = (root.uuid && root.uuid !== "") ? root.uuid : root.idName
                                if (typeof bgdashRoot !== "undefined") bgdashRoot.isInternalEdit = true;
                                dbController.updateSubID(root.selectedYear, root.selectedMonth, parentBlockId, targetSubUuid, t, val)
                                if (typeof bgdashRoot !== "undefined") bgdashRoot.isInternalEdit = false;
                            }
                        }
                        onEditingFinished: {
                            root.dataChanged()
                        }
                        onMoveRequested: function(fromIndex, toIndex) {
                            var clampedTo = Math.max(0, Math.min(subBlockModel.count - 1, toIndex))
                            if (fromIndex !== clampedTo) {
                                subBlockModel.move(fromIndex, clampedTo, 1)
                                root.updateTotal()
                                root.dataChanged()
                                if (typeof dbController !== "undefined" && root.selectedYear > 0) {
                                    var parentBlockId = (root.uuid && root.uuid !== "") ? root.uuid : root.idName
                                    dbController.moveSubID(root.selectedYear, root.selectedMonth, parentBlockId, fromIndex, clampedTo)
                                }
                            }
                        }
                        onRemoveRequested: {
                            var targetSubUuid = (uuid && uuid !== "") ? uuid : (model.uuid !== undefined ? model.uuid : model.title)
                            var parentBlockId = (root.uuid && root.uuid !== "") ? root.uuid : root.idName
                            var subIndex = index

                            if (typeof bgdashRoot !== "undefined") bgdashRoot.isInternalEdit = true;

                            if (typeof dbController !== "undefined" && root.selectedYear > 0 && targetSubUuid !== "") {
                                dbController.removeSubID(root.selectedYear, root.selectedMonth, parentBlockId, targetSubUuid)
                            }

                            subBlockModel.remove(subIndex)
                            root.updateTotal()
                            root.dataChanged()

                            if (typeof bgdashRoot !== "undefined") bgdashRoot.isInternalEdit = false;
                        }
                    }
                }

                // Add sub-block button
                Item {
                    id: subAddContainer
                    width: parent.width
                    height: 36

                    HoverHandler {
                        id: subAddHoverHandler
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: 13
                        color: subAddHoverHandler.hovered ? "#FFFFFF" : ((typeof bgdashRoot !== "undefined" && bgdashRoot.currentThemeIndex === 2) ? "#A62B2B" : "#3A3A3A")
                        opacity: subAddHoverHandler.hovered ? 1.0 : 0.0
                        visible: opacity > 0.0

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: subAddHoverHandler.hovered ? "#202020" : "#AAAAAA"
                            font.pixelSize: 16
                            font.bold: true

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var parentBlockId = (root.uuid && root.uuid !== "") ? root.uuid : root.idName
                                var createdUuid = ""
                                if (typeof dbController !== "undefined" && root.selectedYear > 0) {
                                    if (typeof bgdashRoot !== "undefined") bgdashRoot.isInternalEdit = true;
                                    createdUuid = dbController.addSubID(root.selectedYear, root.selectedMonth, parentBlockId, "새 항목", 0.0)
                                    if (typeof bgdashRoot !== "undefined") bgdashRoot.isInternalEdit = false;
                                }
                                subBlockModel.append({ "uuid": createdUuid ? createdUuid : "", "title": "새 항목", "value": "" });
                                root.updateTotal();
                                root.dataChanged();

                                Qt.callLater(function() {
                                    if (!subFlickable) return;
                                    var maxFlickScroll = Math.max(0, subFlickable.contentHeight - subFlickable.height);
                                    root.savedScrollY = maxFlickScroll;
                                    if (typeof bgdashRoot !== "undefined" && typeof bgdashRoot.setSubScroll === "function") {
                                        bgdashRoot.setSubScroll(parentBlockId, maxFlickScroll);
                                    }
                                    root.setScrollY(maxFlickScroll);
                                });
                            }
                        }
                    }
                }
            }
        }

        // Delete button
        Item {
            id: deleteHoverArea
            width: 50
            height: 50

            HoverHandler {
                id: deleteHoverHandler
            }

            Rectangle {
                id: deleteButton
                width: 18
                height: 18
                radius: 9
                color: idDelHover.containsMouse ? "#FF3B30" : "#FF5F57"
                scale: idDelHover.containsMouse ? 1.25 : 1.0
                anchors.centerIn: parent

                opacity: (deleteHoverHandler.hovered || idDelHover.containsMouse) ? 1.0 : 0.0
                visible: opacity > 0.0

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: idDelHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.removeRequested(root.blockIndex)
                    }
                }
            }
        }

        // Drag handle
        Item {
            id: dragHoverArea
            width: 50
            height: 50
            anchors.right: parent.right
            anchors.top: parent.top

            HoverHandler {
                id: dragHoverHandler
            }

            Item {
                id: dragHandle
                width: 20
                height: 24
                anchors.centerIn: parent
                opacity: (dragHoverHandler.hovered || dragMouseArea.containsMouse || dragMouseArea.pressed) ? 1 : 0
                scale: dragMouseArea.containsMouse ? 1.2 : 1.0

                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Repeater {
                        model: 3
                        Row {
                            spacing: 2
                            Repeater {
                                model: 2
                                Rectangle {
                                    width: 3
                                    height: 3
                                    radius: 1.5
                                    color: dragMouseArea.containsMouse ? "#FFFFFF" : "#7A7A7A"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: dragMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.OpenHandCursor

                    drag.target: contentWrapper
                    drag.axis: Drag.XAxis

                    onPressed: {
                        cursorShape = Qt.ClosedHandCursor
                        if (root.parentFlickable) {
                            root.parentFlickable.interactive = false
                        }
                    }
                    onReleased: {
                        cursorShape = Qt.OpenHandCursor
                        if (root.parentFlickable) {
                            root.parentFlickable.interactive = true
                        }

                        var targetIndex = root.blockIndex + Math.round(contentWrapper.x / (root.width + 16))
                        root.moveRequested(root.blockIndex, targetIndex)

                        contentWrapper.x = 0
                    }
                }
            }
        }

        // Footer for Total Sum
        Item {
            id: footer
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 40

            // Horizontal Divider Line right above Total sum section
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                height: 1
                color: (typeof bgdashRoot !== "undefined" && bgdashRoot.currentThemeIndex === 2) ? "#FFFFFF" : "#3A3A3A"
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 2
                text: "합계"
                color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF"
                font.pixelSize: 13
                font.bold: true
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 2
                text: Number(root.totalValue).toLocaleString(Qt.locale("ko_KR"), "f", 0)
                color: typeof bgdashRoot !== "undefined" ? bgdashRoot.themeTextColor : "#FFFFFF"
                font.pixelSize: 14
                font.bold: true
                Behavior on color { ColorAnimation { duration: 250 } }
            }
        }
    }
}
