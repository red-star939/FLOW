import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int blockIndex: -1
    property string title: "새 항목"
    property Flickable parentFlickable: null

    signal removeRequested(int index)
    signal moveRequested(int fromIndex, int toIndex)
    signal titleEdited(string newTitle)
    signal editingFinished()
    signal functionRequested(int index)
    signal monthValueEdited(int month, string newValue)

    property string formula: ""
    property var monthValues: ({})
    property var bblockSums: ({})
    property int bblockUpdateTrigger: 0
    property ListModel bBlockModel: null
    property int currentMonth: 1

    // Make width responsive to parent, fallback to 1200
    width: parent ? parent.width : 1200
    height: 46
    z: dragMouseArea.pressed ? 100 : 1

    readonly property bool isAblock: true
    readonly property bool dragActive: dragMouseArea.pressed
    readonly property real dragYOffset: contentWrapper.y

    // Math for precise layout matching MonthSelector (on root for clean scope)
    readonly property real gap: 20
    readonly property real availableWidth: root.width - 160 - 60
    readonly property real cellWidth: (availableWidth - gap) / 13

    // Tracks if there is currently any dragging sibling item in the column
    readonly property bool parentHasDraggingItem: {
        if (!root.parent) return false
        var siblings = root.parent.children
        for (var i = 0; i < siblings.length; i++) {
            var sib = siblings[i]
            if (sib && typeof sib.isAblock !== "undefined" && sib.isAblock && sib.dragActive) {
                return true
            }
        }
        return false
    }

    // Visual shift offset for Apple-style placeholder opening
    readonly property real visualShift: {
        if (!root.parent) return 0

        var draggingItem = null
        var siblings = root.parent.children
        for (var i = 0; i < siblings.length; i++) {
            var sib = siblings[i]
            if (sib && typeof sib.isAblock !== "undefined" && sib.isAblock && sib.dragActive) {
                draggingItem = sib
                break
            }
        }

        if (!draggingItem || draggingItem === root) {
            return 0
        }

        var dragIndex = draggingItem.blockIndex
        var myIndex = root.blockIndex
        var dragY = draggingItem.y + draggingItem.dragYOffset
        var myY = root.y
        var rowHeightWithSpacing = root.height + 16

        if (dragIndex < myIndex && dragY > myY - rowHeightWithSpacing / 2) {
            return -rowHeightWithSpacing
        } else if (dragIndex > myIndex && dragY < myY + rowHeightWithSpacing / 2) {
            return rowHeightWithSpacing
        }

        return 0
    }

    // ─── contentWrapper: wraps ALL visual children so drag + shift works ───
    Item {
        id: contentWrapper
        width: root.width
        height: root.height
        y: 0

        // Smooth translation behavior for sibling items sliding out of the way
        transform: Translate {
            y: root.visualShift
            Behavior on y {
                enabled: root.parentHasDraggingItem
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }

        // ─── Left hover area (delete button + drag handle) ───
        Item {
            id: leftHoverArea
            width: 150
            height: parent.height

            HoverHandler {
                id: leftHoverHandler
            }

            // Hover Delete Button
            Rectangle {
                id: deleteButton
                width: 18
                height: 18
                radius: 9
                color: "#FF5F57"

                anchors {
                    left: dragHandle.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                opacity: leftHoverHandler.hovered ? 1.0 : 0.0
                visible: opacity > 0.0

                Behavior on opacity { NumberAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    y: -1
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.removeRequested(root.blockIndex)
                }
            }

            // Drag reorder handle (2x3 dots)
            Item {
                id: dragHandle
                width: 20
                height: 24

                anchors {
                    left: parent.left
                    leftMargin: 8
                    verticalCenter: parent.verticalCenter
                }

                opacity: leftHoverHandler.hovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }

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
                                    color: "#7A7A7A"
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
                    drag.axis: Drag.YAxis

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

                        var targetIndex = root.blockIndex + Math.round(contentWrapper.y / (root.height + 16))
                        root.moveRequested(root.blockIndex, targetIndex)

                        contentWrapper.y = 0
                    }
                }
            }
        }

        // ─── Editable Title TextField ───
        TextField {
            id: titleInput
            anchors {
                left: parent.left
                leftMargin: 82
                verticalCenter: parent.verticalCenter
            }

            text: root.title
            color: "#FFFFFF"
            font.pixelSize: 16
            font.bold: true
            width: 95

            selectByMouse: true
            selectedTextColor: "#202020"
            selectionColor: "#FFFFFF"

            background: Rectangle {
                color: "transparent"
                border.width: 0
            }

            onTextEdited: {
                root.title = text
                root.titleEdited(text)
            }

            onEditingFinished: {
                root.editingFinished()
                titleInput.focus = false
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: Qt.PointingHandCursor
            }
        }

        // ─── 12 Month Cells Row (Direct User Input + Formula Evaluation) ───
        Row {
            id: cellsRow
            anchors.left: parent.left
            anchors.leftMargin: 160
            width: root.cellWidth * 12
            height: parent.height
            spacing: 0

            Repeater {
                model: 12

                delegate: Item {
                    width: root.cellWidth
                    height: cellsRow.height

                    TextField {
                        id: cellInput
                        anchors.centerIn: parent
                        width: parent.width - 2
                        height: parent.height - 8
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 15
                        font.bold: true

                        selectByMouse: true
                        selectedTextColor: "#202020"
                        selectionColor: "#FFFFFF"
                        color: text === "-" ? "#B0B0B0" : "#FFFFFF"

                        background: Rectangle {
                            color: cellInput.activeFocus ? "#2C2C2E" : (cellHoverHandler.hovered ? "#202020" : "transparent")
                            radius: 6
                            border.color: cellInput.activeFocus ? "#007AFF" : "transparent"
                            border.width: cellInput.activeFocus ? 1 : 0
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        HoverHandler {
                            id: cellHoverHandler
                        }

                        // Computed display value — always re-evaluated as a binding
                        readonly property string computedText: {
                            var trigger = root.bblockUpdateTrigger;
                            var formulaStr = root.formula;  // explicit dependency
                            var mvs = root.monthValues;     // explicit dependency
                            var m = index + 1;
                            var monthFormula = root.getFormulaForMonth(formulaStr, m);
                            if (monthFormula !== "") {
                                var sumsForMonth = root.getSumsForMonth(m);
                                var val = root.evaluateFormula(monthFormula, sumsForMonth);
                                console.log("[Ablock] month=" + m + " formula='" + monthFormula + "' sums=" + JSON.stringify(sumsForMonth) + " result=" + val);
                                if (val !== "-") {
                                    return val.toLocaleString(undefined, {minimumFractionDigits: 0, maximumFractionDigits: 2});
                                }
                            }
                            var savedVal = (mvs && mvs[String(m)] !== undefined) ? mvs[String(m)] : "";
                            if (savedVal !== "" && savedVal !== "-") {
                                var n = parseFloat(savedVal);
                                if (!isNaN(n)) return n.toLocaleString(undefined, {minimumFractionDigits: 0, maximumFractionDigits: 2});
                                return savedVal;
                            }
                            return "-";
                        }

                        // Sync computed text → TextField when not editing
                        onComputedTextChanged: {
                            if (!cellInput.activeFocus) {
                                cellInput.text = computedText;
                            }
                        }

                        Component.onCompleted: {
                            cellInput.text = computedText;
                        }

                        onActiveFocusChanged: {
                            if (!activeFocus) {
                                // Restore computed display when focus is lost
                                cellInput.text = computedText;
                            }
                        }

                        onEditingFinished: {
                            var m = index + 1;
                            var valStr = cellInput.text.trim();
                            var currentMap = Object.assign({}, root.monthValues || {});
                            currentMap[String(m)] = valStr;
                            root.monthValues = currentMap;
                            root.monthValueEdited(m, valStr);
                            root.editingFinished();
                            cellInput.focus = false;
                        }
                    }

                    // Vertical separator line between month cells
                    Rectangle {
                        visible: index < 11
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 20
                        color: "#3A3A3A"
                    }
                }
            }
        }

        // ─── 13th Sum Cell ───
        Item {
            id: sumCell
            anchors.right: parent.right
            anchors.rightMargin: 65
            width: root.cellWidth
            height: parent.height

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 2
                height: parent.height - 8
                radius: 6
                color: "transparent"
                border.width: 0

                Text {
                    anchors.centerIn: parent
                    text: {
                        var trigger = root.bblockUpdateTrigger;
                        var sum = 0;
                        for (var m = 1; m <= 12; m++) {
                            var val = null;
                            var monthFormula = root.getFormulaForMonth(root.formula, m);
                            if (monthFormula !== "") {
                                var sumsForMonth = root.getSumsForMonth(m);
                                val = root.evaluateFormula(monthFormula, sumsForMonth);
                            }
                            if (val === null || val === "-") {
                                var savedVal = (root.monthValues && root.monthValues[String(m)] !== undefined) ? root.monthValues[String(m)] : "";
                                if (savedVal !== "") {
                                    val = parseFloat(savedVal);
                                }
                            }
                            if (typeof val === "number" && !isNaN(val)) {
                                sum += val;
                            }
                        }
                        return sum.toLocaleString(undefined, {minimumFractionDigits: 0, maximumFractionDigits: 2});
                    }
                    color: "#FFFFFF"
                    font.pixelSize: 16
                    font.bold: true
                }
            }
        }

        // ─── Newly Redesigned Function Button (ƒ) ───
        Rectangle {
            id: funcButton
            width: 32
            height: 26
            radius: 8
            color: buttonHoverHandler.hovered ? "#007AFF" : "#2C2C2E"
            border.color: buttonHoverHandler.hovered ? "#66B2FF" : "#FF9F0A"
            border.width: 1.5

            anchors.left: sumCell.right
            anchors.leftMargin: 12
            anchors.verticalCenter: sumCell.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            HoverHandler {
                id: buttonHoverHandler
            }

            Text {
                anchors.centerIn: parent
                text: "ƒ"
                color: buttonHoverHandler.hovered ? "#FFFFFF" : "#FF9F0A"
                font.pixelSize: 15
                font.bold: true
            }

            MouseArea {
                id: funcMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.functionRequested(root.blockIndex)
                }
            }
        }
    } // end contentWrapper

    function getSumsForMonth(month) {
        var sumsForMonth = {};

        function extractTotal(subblocksRaw) {
            var total = 0.0;
            var list = [];
            if (typeof subblocksRaw === "string") {
                try { list = JSON.parse(subblocksRaw || "[]"); } catch (e) { list = []; }
            } else if (Array.isArray(subblocksRaw)) {
                list = subblocksRaw;
            } else if (subblocksRaw && typeof subblocksRaw === "object") {
                if (subblocksRaw.count !== undefined) {
                    for (var c = 0; c < subblocksRaw.count; c++) {
                        list.push(subblocksRaw.get(c));
                    }
                }
            }
            for (var j = 0; j < list.length; j++) {
                var item = list[j];
                if (!item) continue;
                var valStr = item.value !== undefined ? item.value : "";
                var val = parseFloat(valStr);
                if (!isNaN(val)) {
                    total += val;
                }
            }
            return total;
        }

        if (month === root.currentMonth && root.bBlockModel) {
            for (var i = 0; i < root.bBlockModel.count; i++) {
                var bblock = root.bBlockModel.get(i);
                if (bblock) {
                    var title = bblock.title || "새 블록";
                    var total = extractTotal(bblock.subblocks);
                    sumsForMonth[title] = total;
                    sumsForMonth["Bblock" + (i + 1)] = total;
                    sumsForMonth["bblock" + (i + 1)] = total;
                    sumsForMonth["Bbox" + (i + 1)] = total;
                    sumsForMonth["bbox" + (i + 1)] = total;
                    sumsForMonth["B" + (i + 1)] = total;
                    sumsForMonth["b" + (i + 1)] = total;
                }
            }
        } else {
            sumsForMonth = (root.bblockSums && root.bblockSums[String(month)]) ? Object.assign({}, root.bblockSums[String(month)]) : {};
            if (Object.keys(sumsForMonth).length === 0 && root.bBlockModel) {
                for (var k = 0; k < root.bBlockModel.count; k++) {
                    var bb = root.bBlockModel.get(k);
                    if (bb) {
                        var t = bb.title || "새 블록";
                        var tot = extractTotal(bb.subblocks);
                        sumsForMonth[t] = tot;
                        sumsForMonth["Bblock" + (k + 1)] = tot;
                        sumsForMonth["bblock" + (k + 1)] = tot;
                        sumsForMonth["Bbox" + (k + 1)] = tot;
                        sumsForMonth["bbox" + (k + 1)] = tot;
                        sumsForMonth["B" + (k + 1)] = tot;
                        sumsForMonth["b" + (k + 1)] = tot;
                    }
                }
            }
        }
        return sumsForMonth;
    }

    function getFormulaForMonth(formulaData, month) {
        if (!formulaData) return "";
        formulaData = formulaData.trim();
        if (formulaData.startsWith("{") && formulaData.endsWith("}")) {
            try {
                var map = JSON.parse(formulaData);
                var mKey = String(month);
                if (map[mKey] !== undefined && map[mKey] !== null && map[mKey] !== "") return map[mKey];
                if (map["0"] !== undefined && map["0"] !== null && map["0"] !== "") return map["0"];
                if (map["default"] !== undefined && map["default"] !== null && map["default"] !== "") return map["default"];
                return "";
            } catch (e) {
                return formulaData;
            }
        }
        return formulaData;
    }

    function evaluateFormula(formulaStr, sums) {
        if (!formulaStr || formulaStr.trim() === "") return "-";
        sums = sums || {};

        var expr = formulaStr.trim();
        if (expr.startsWith("=")) {
            expr = expr.substring(1).trim();
        }
        if (expr === "") return "-";

        // 1. Primary: Use C++ FormulaEngine (sys/engine) if available in QML context
        if (typeof formulaEngine !== "undefined" && formulaEngine !== null) {
            try {
                console.log("[evaluateFormula] C++ engine available. expr='" + expr + "' sums keys=" + JSON.stringify(Object.keys(sums)));
                for (var k in sums) {
                    if (sums[k] !== undefined && sums[k] !== null) {
                        var valNum = parseFloat(sums[k]);
                        formulaEngine.setCellValue(k, isNaN(valNum) ? 0 : valNum);
                        console.log("[evaluateFormula] setCellValue('" + k + "', " + (isNaN(valNum) ? 0 : valNum) + ")");
                    }
                }
                for (var idx = 1; idx <= 50; idx++) {
                    var bKey = "Bblock" + idx;
                    var bShort = "B" + idx;
                    var bboxKey = "Bbox" + idx;
                    if (sums[bKey] !== undefined) {
                        var v = parseFloat(sums[bKey]) || 0;
                        formulaEngine.setCellValue(bKey, v);
                        formulaEngine.setCellValue(bShort, v);
                        formulaEngine.setCellValue(bboxKey, v);
                    } else if (sums[bShort] !== undefined) {
                        var v = parseFloat(sums[bShort]) || 0;
                        formulaEngine.setCellValue(bKey, v);
                        formulaEngine.setCellValue(bShort, v);
                        formulaEngine.setCellValue(bboxKey, v);
                    }
                }
                var cppResult = formulaEngine.evaluate(expr);
                console.log("[evaluateFormula] C++ result: '" + cppResult + "'");
                if (cppResult && !cppResult.startsWith("#ERROR") && cppResult !== "#REF!" && cppResult !== "#NAME?" && cppResult !== "#VALUE!" && cppResult !== "#DIV/0!") {
                    var parsedVal = parseFloat(cppResult);
                    if (!isNaN(parsedVal)) {
                        return parsedVal;
                    }
                }
                console.log("[evaluateFormula] C++ returned error/non-numeric, falling back to JS");
            } catch (err) {
                console.log("C++ Engine Evaluation error, using JS fallback:", err);
            }
        }

        // 2. Fallback: JavaScript Formula Evaluator
        var valMap = {};
        for (var k in sums) {
            valMap[k.toUpperCase()] = parseFloat(sums[k]) || 0;
        }

        // Auto-alias BBLOCK / BBOX / B keys
        for (var idx = 1; idx <= 50; idx++) {
            var bKey = "BBLOCK" + idx;
            var boxKey = "BBOX" + idx;
            var bShortKey = "B" + idx;
            var foundVal = valMap[bKey] !== undefined ? valMap[bKey] : (valMap[boxKey] !== undefined ? valMap[boxKey] : valMap[bShortKey]);
            if (foundVal !== undefined) {
                valMap[bKey] = foundVal;
                valMap[boxKey] = foundVal;
                valMap[bShortKey] = foundVal;
            }
        }

        // Normalize function names to uppercase
        expr = expr.replace(/\b(sum|average|min|max|count|if|round|abs|intup|intdown)\b/gi, function(m) {
            return m.toUpperCase();
        });

        // Expand ranges like Bblock1:Bblock3 or Bbox1:Bbox3
        expr = expr.replace(/([A-Za-z0-9가-힣_]+)\s*:\s*([A-Za-z0-9가-힣_]+)/g, function(match, start, end) {
            var mStart = start.match(/^(?:Bblock|Bbox|B)(\d+)$/i);
            var mEnd = end.match(/^(?:Bblock|Bbox|B)(\d+)$/i);
            if (mStart && mEnd) {
                var iStart = parseInt(mStart[1]);
                var iEnd = parseInt(mEnd[1]);
                var list = [];
                var step = iStart <= iEnd ? 1 : -1;
                for (var i = iStart; step > 0 ? i <= iEnd : i >= iEnd; i += step) {
                    var key = "BBLOCK" + i;
                    var val = valMap[key] !== undefined ? valMap[key] : 0;
                    list.push(val);
                }
                return list.join(", ");
            }
            return match;
        });

        // Substitute variable names
        var sortedKeys = Object.keys(valMap).sort(function(a, b) { return b.length - a.length; });
        for (var i = 0; i < sortedKeys.length; i++) {
            var key = sortedKeys[i];
            if (!key) continue;
            var val = valMap[key];
            var escaped = key.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
            var reg = new RegExp("(^|[^A-Za-z0-9가-힣_])" + escaped + "(?![A-Za-z0-9가-힣_])", "gi");
            expr = expr.replace(reg, "$1" + val);
        }

        // Percentage operator: 10% -> (10/100)
        expr = expr.replace(/([0-9\.]+|[A-Za-z0-9가-힣_]+|\))\s*%/g, "($1/100)");

        // Comparison operators: <> -> != , = -> ==
        expr = expr.replace(/<>/g, "!=");
        expr = expr.replace(/([^=<>]|^)=([^=]|$)/g, "$1==$2");

        var helpers = `
            function SUM() {
                var s = 0;
                for (var i = 0; i < arguments.length; i++) {
                    var v = parseFloat(arguments[i]);
                    if (!isNaN(v)) s += v;
                }
                return s;
            }
            function AVERAGE() {
                var s = 0, c = 0;
                for (var i = 0; i < arguments.length; i++) {
                    var v = parseFloat(arguments[i]);
                    if (!isNaN(v)) { s += v; c++; }
                }
                return c > 0 ? s / c : 0;
            }
            function MIN() {
                var vals = [];
                for (var i = 0; i < arguments.length; i++) {
                    var v = parseFloat(arguments[i]);
                    if (!isNaN(v)) vals.push(v);
                }
                return vals.length > 0 ? Math.min.apply(null, vals) : 0;
            }
            function MAX() {
                var vals = [];
                for (var i = 0; i < arguments.length; i++) {
                    var v = parseFloat(arguments[i]);
                    if (!isNaN(v)) vals.push(v);
                }
                return vals.length > 0 ? Math.max.apply(null, vals) : 0;
            }
            function COUNT() {
                var c = 0;
                for (var i = 0; i < arguments.length; i++) {
                    var v = parseFloat(arguments[i]);
                    if (!isNaN(v)) c++;
                }
                return c;
            }
            function IF(cond, tVal, fVal) {
                return cond ? (tVal !== undefined ? tVal : true) : (fVal !== undefined ? fVal : false);
            }
            function ROUND(v, d) {
                d = d || 0;
                var f = Math.pow(10, d);
                return Math.round(v * f) / f;
            }
            function ABS(v) {
                return Math.abs(v);
            }
            function INTUP(v, n) {
                v = parseFloat(v) || 0;
                n = parseInt(n) || 0;
                var f = Math.pow(10, n);
                return Math.round(v / f) * f;
            }
            function INTDOWN(v, n) {
                v = parseFloat(v) || 0;
                n = parseInt(n) || 0;
                var f = Math.pow(10, Math.max(0, n - 1));
                return Math.floor(v / f) * f;
            }
        `;

        expr = expr.replace(/(^|[^A-Za-z0-9_가-힣])([A-Za-z_가-힣][A-Za-z0-9_가-힣]*)(?!\s*\()/gi, function(m, p1, p2) {
            var u = p2.toUpperCase();
            if (u === "SUM" || u === "AVERAGE" || u === "MIN" || u === "MAX" || u === "COUNT" || u === "IF" || u === "ROUND" || u === "ABS" || u === "INTUP" || u === "INTDOWN" || u === "TRUE" || u === "FALSE") return m;
            return p1 + "0";
        });

        try {
            var fn = new Function(helpers + " return (" + expr + ");");
            var res = fn();
            return (res === null || res === undefined || isNaN(res)) ? 0 : res;
        } catch (e) {
            return 0;
        }
    }
} // end root