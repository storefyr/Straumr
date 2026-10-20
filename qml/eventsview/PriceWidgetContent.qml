import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: widget

    width: parent ? parent.width : Screen.width
    implicitHeight: Math.max(150, contentColumn.height + 2 * Theme.paddingMedium)

    property var todayPrices: []
    property var tomorrowPrices: []
    property var tariffs: null
    property var currentPrice: null
    property real currentTotal: 0
    property bool loading: false
    property string statusMsg: "Starter..."

    readonly property string API_URL: "https://api.energidataservice.dk/dataset/DayAheadPrices"
    readonly property string PRICELIST_URL: "https://api.energidataservice.dk/dataset/DatahubPricelist"
    readonly property string GRID_GLN: "5790000705689"
    readonly property string ENERGINET_GLN: "5790000432752"

    function pad(n) { return n < 10 ? "0" + n : "" + n }

    function todayISO() {
        var d = new Date()
        return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
    }

    function tomorrowISO() {
        var d = new Date()
        d.setDate(d.getDate() + 2)
        return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
    }

    function buildSpotUrl() {
        var filter = encodeURIComponent(JSON.stringify({"PriceArea": ["DK2"]}))
        return API_URL + "?filter=" + filter +
            "&start=" + todayISO() +
            "&end=" + tomorrowISO() +
            "&sort=" + encodeURIComponent("TimeUTC asc") +
            "&limit=200" +
            "&columns=" + encodeURIComponent("TimeUTC,TimeDK,PriceArea,DayAheadPriceDKK")
    }

    function buildTariffUrl(gln, note) {
        var filter = encodeURIComponent(JSON.stringify({"GLN_Number": gln, "Note": note}))
        return PRICELIST_URL + "?filter=" + filter +
            "&sort=" + encodeURIComponent("ValidFrom desc") +
            "&limit=10"
    }

    function httpGet(url, callback) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== 4) return
            if (xhr.status === 200) {
                try { callback(null, JSON.parse(xhr.responseText)) }
                catch (e) { callback(e, null) }
            } else {
                callback(new Error("HTTP " + xhr.status), null)
            }
        }
        xhr.open("GET", url, true)
        xhr.timeout = 15000
        xhr.send()
    }

    function pickValidRecord(records, date) {
        if (!records || records.length === 0) return null
        var target = date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
        for (var i = 0; i < records.length; i++) {
            var from = records[i].ValidFrom ? records[i].ValidFrom.substring(0, 10) : "0000-00-00"
            var to = records[i].ValidTo ? records[i].ValidTo.substring(0, 10) : "9999-99-99"
            if (target >= from && target < to) return records[i]
        }
        return records[0]
    }

    function getNettarifForHour(nettarifC, hour) {
        if (!nettarifC) return 0
        var p = nettarifC["Price" + (hour + 1)]
        return (p === null || p === undefined) ? 0 : p
    }

    function calcTotal(spotDkkMwh, hour) {
        if (!tariffs) return 0
        var spot = spotDkkMwh / 1000.0
        var nettarif = getNettarifForHour(tariffs.nettarifC, hour)
        var system = tariffs.systemtarif || 0
        var trans = tariffs.transmission || 0
        var el = tariffs.elafgift || 0
        return (spot + nettarif + system + trans + el) * 1.25
    }

    function totalForRecord(record) {
        if (!record) return 0
        var hour = parseInt(record["TimeDK"].substring(11, 13), 10)
        return calcTotal(record["DayAheadPriceDKK"], hour)
    }

    function barColor(total) {
        if (total < 1.00) return "#4caf50"
        if (total < 2.00) return "#8bc34a"
        if (total < 3.00) return "#ff9800"
        return "#f44336"
    }

    function formatKr(v) { return v.toFixed(2).replace(".", ",") }

    function splitPrices(records) {
        var today = []
        var tomorrow = []
        var todayStr = todayISO()
        var d = new Date()
        d.setDate(d.getDate() + 1)
        var tomorrowStr = d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
        for (var i = 0; i < records.length; i++) {
            var date = records[i]["TimeDK"].substring(0, 10)
            if (date === todayStr) today.push(records[i])
            else if (date === tomorrowStr) tomorrow.push(records[i])
        }
        return {today: today, tomorrow: tomorrow}
    }

    function findCurrent(records) {
        var now = new Date()
        var nowISO = now.getFullYear() + "-" + pad(now.getMonth() + 1) + "-" + pad(now.getDate()) +
                     "T" + pad(now.getHours()) + ":" + pad(now.getMinutes()) + ":00"
        var current = null
        for (var i = 0; i < records.length; i++) {
            if (records[i]["TimeDK"] <= nowISO) current = records[i]
            else break
        }
        return current
    }

    function refresh() {
        statusMsg = "Henter..."
        loading = true
        try {
            httpGet(buildSpotUrl(), function(err, data) {
                if (err) {
                    statusMsg = "Fejl: " + err.message
                    loading = false
                    return
                }
                if (!data || !data.records || data.records.length === 0) {
                    statusMsg = "Ingen data"
                    loading = false
                    return
                }
                var split = splitPrices(data.records)
                todayPrices = split.today
                tomorrowPrices = split.tomorrow
                currentPrice = findCurrent(split.today)
                statusMsg = "OK"
                fetchTariffs()
            })
        } catch (e) {
            statusMsg = "Exception: " + e.message
            loading = false
        }
    }

    function fetchTariffs() {
        var t = {systemtarif: null, transmission: null, elafgift: null, nettarifC: null}
        var done = 0
        var now = new Date()

        function checkDone() {
            done++
            if (done === 4) {
                tariffs = t
                if (currentPrice) {
                    var hour = parseInt(currentPrice["TimeDK"].substring(11, 13), 10)
                    currentTotal = calcTotal(currentPrice["DayAheadPriceDKK"], hour)
                }
                loading = false
                todayCanvas.requestPaint()
                tomorrowCanvas.requestPaint()
            }
        }

        httpGet(buildTariffUrl(ENERGINET_GLN, "Systemtarif"), function(e, d) {
            if (!e && d && d.records) { var r = pickValidRecord(d.records, now); if (r) t.systemtarif = r.Price1 }
            checkDone()
        })
        httpGet(buildTariffUrl(ENERGINET_GLN, "Transmissions nettarif"), function(e, d) {
            if (!e && d && d.records) { var r = pickValidRecord(d.records, now); if (r) t.transmission = r.Price1 }
            checkDone()
        })
        httpGet(buildTariffUrl(ENERGINET_GLN, "Elafgift"), function(e, d) {
            if (!e && d && d.records) { var r = pickValidRecord(d.records, now); if (r) t.elafgift = r.Price1 }
            checkDone()
        })
        httpGet(buildTariffUrl(GRID_GLN, "Nettarif C"), function(e, d) {
            if (!e && d && d.records) { var r = pickValidRecord(d.records, now); if (r) t.nettarifC = r }
            checkDone()
        })
    }

    Component.onCompleted: {
        statusMsg = "Component klar"
        refresh()
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        onTriggered: widget.refresh()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.highlightBackgroundColor
        opacity: 0.4
        radius: Theme.paddingSmall
    }

    Column {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
            topMargin: Theme.paddingMedium
        }
        spacing: Theme.paddingSmall

        Row {
            width: parent.width
            spacing: Theme.paddingMedium

            Label {
                text: "Straumr"
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
            }

            Label {
                text: "DK2"
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: Theme.paddingLarge
                height: 1
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                text: widget.loading ? "..."
                    : widget.currentTotal > 0 ? formatKr(widget.currentTotal) + " kr/kWh"
                    : widget.statusMsg
                color: widget.currentTotal > 0 ? Theme.highlightColor
                    : widget.statusMsg.indexOf("Fejl") >= 0 || widget.statusMsg.indexOf("Exception") >= 0 ? Theme.errorColor
                    : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }
        }

        Label {
            visible: widget.currentPrice !== null && !widget.loading
            height: visible ? implicitHeight : 0
            text: widget.currentPrice ? "Spot: " + formatKr(widget.currentPrice["DayAheadPriceDKK"] / 1000.0) + " kr" : ""
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
        }

        Label {
            text: "I dag: " + widget.todayPrices.length
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            visible: widget.todayPrices.length > 0
            height: visible ? implicitHeight : 0
        }

        Canvas {
            id: todayCanvas
            visible: widget.todayPrices.length > 0
            height: visible ? 60 : 0
            width: parent.width

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var prices = widget.todayPrices
                if (prices.length === 0) return

                var max = 0
                for (var i = 0; i < prices.length; i++) {
                    var t = widget.totalForRecord(prices[i])
                    if (t > max) max = t
                }
                if (max <= 0) max = 1

                var bw = width / prices.length
                var now = new Date()
                var nowISO = now.getFullYear() + "-" + widget.pad(now.getMonth() + 1) + "-" + widget.pad(now.getDate()) +
                             "T" + widget.pad(now.getHours()) + ":" + widget.pad(now.getMinutes()) + ":00"

                for (var i = 0; i < prices.length; i++) {
                    var total = widget.totalForRecord(prices[i])
                    var barH = (total / max) * (height - 4)
                    ctx.fillStyle = widget.barColor(total)
                    ctx.fillRect(i * bw, height - barH, Math.max(bw - 1, 1), barH)

                    if (prices[i]["TimeDK"] === nowISO ||
                        (i > 0 && prices[i-1]["TimeDK"] < nowISO && prices[i]["TimeDK"] > nowISO)) {
                        ctx.strokeStyle = Theme.highlightColor
                        ctx.lineWidth = 2
                        ctx.beginPath()
                        ctx.moveTo(i * bw, 0)
                        ctx.lineTo(i * bw, height)
                        ctx.stroke()
                    }
                }
            }
        }

        Label {
            text: "I morgen: " + widget.tomorrowPrices.length
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            visible: widget.tomorrowPrices.length > 0
            height: visible ? implicitHeight : 0
        }

        Canvas {
            id: tomorrowCanvas
            visible: widget.tomorrowPrices.length > 0
            height: visible ? 60 : 0
            width: parent.width

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var prices = widget.tomorrowPrices
                if (prices.length === 0) return

                var max = 0
                for (var i = 0; i < prices.length; i++) {
                    var t = widget.totalForRecord(prices[i])
                    if (t > max) max = t
                }
                if (max <= 0) max = 1

                var bw = width / prices.length

                for (var i = 0; i < prices.length; i++) {
                    var total = widget.totalForRecord(prices[i])
                    var barH = (total / max) * (height - 4)
                    ctx.fillStyle = widget.barColor(total)
                    ctx.fillRect(i * bw, height - barH, Math.max(bw - 1, 1), barH)
                }
            }
        }
    }

    onTodayPricesChanged: todayCanvas.requestPaint()
    onTomorrowPricesChanged: tomorrowCanvas.requestPaint()
    onTariffsChanged: {
        todayCanvas.requestPaint()
        tomorrowCanvas.requestPaint()
    }
}
