import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: widget

    width: parent ? parent.width : Screen.width
    implicitHeight: 120

    property string statusMsg: "Starter..."
    property real spotPrice: 0
    property real totalPrice: 0
    property string currentTime: ""

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

    function buildTariffUrl(gln, note) {
        var filter = encodeURIComponent(JSON.stringify({"GLN_Number": gln, "Note": note}))
        return PRICELIST_URL + "?filter=" + filter +
            "&sort=" + encodeURIComponent("ValidFrom desc") + "&limit=10"
    }

    function httpGet(url, cb) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== 4) return
            if (xhr.status === 200) {
                try { cb(null, JSON.parse(xhr.responseText)) }
                catch (e) { cb(e, null) }
            } else {
                cb(new Error("HTTP " + xhr.status), null)
            }
        }
        xhr.onerror = function() { cb(new Error("Netværk"), null) }
        xhr.open("GET", url, true)
        xhr.timeout = 15000
        xhr.send()
    }

    function pickValid(records, date) {
        if (!records || records.length === 0) return null
        var target = date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
        for (var i = 0; i < records.length; i++) {
            var from = records[i].ValidFrom ? records[i].ValidFrom.substring(0, 10) : "0000-00-00"
            var to = records[i].ValidTo ? records[i].ValidTo.substring(0, 10) : "9999-99-99"
            if (target >= from && target < to) return records[i]
        }
        return records[0]
    }

    function formatKr(v) { return v.toFixed(2).replace(".", ",") }

    function refresh() {
        statusMsg = "Tjekker XHR..."
        try {
            if (typeof XMLHttpRequest === "undefined") {
                statusMsg = "Ingen XMLHttpRequest!"
                return
            }
            statusMsg = "Henter..."
            var filter = encodeURIComponent(JSON.stringify({"PriceArea": ["DK2"]}))
            var url = "https://api.energidataservice.dk/dataset/DayAheadPrices?filter=" + filter +
                "&start=" + todayISO() +
                "&end=" + tomorrowISO() +
                "&sort=" + encodeURIComponent("TimeUTC asc") +
                "&limit=200" +
                "&columns=" + encodeURIComponent("TimeUTC,TimeDK,PriceArea,DayAheadPriceDKK")

            var xhr = new XMLHttpRequest()
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== 4) return
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        if (data.records && data.records.length > 0) {
                            var now = new Date()
                            var nowISO = now.getFullYear() + "-" + pad(now.getMonth()+1) + "-" + pad(now.getDate()) +
                                         "T" + pad(now.getHours()) + ":" + pad(now.getMinutes()) + ":00"
                            var current = null
                            for (var i = 0; i < data.records.length; i++) {
                                if (data.records[i]["TimeDK"] <= nowISO) current = data.records[i]
                                else break
                            }
                            if (current) {
                                spotPrice = current["DayAheadPriceDKK"] / 1000.0
                                currentTime = current["TimeDK"].substring(11, 16)
                                statusMsg = "Henter tariffer..."
                                fetchTariffs(current["DayAheadPriceDKK"], now.getHours())
                            } else {
                                statusMsg = "Ingen nuværende"
                            }
                        } else {
                            statusMsg = "Ingen records"
                        }
                    } catch (e) {
                        statusMsg = "Parse: " + e.message
                    }
                } else {
                    statusMsg = "HTTP " + xhr.status
                }
            }
            xhr.onerror = function() {
                statusMsg = "Netværksfejl"
            }
            xhr.open("GET", url, true)
            xhr.timeout = 15000
            xhr.send()
        } catch (e) {
            statusMsg = "Fejl: " + e.message
        }
    }

    function fetchTariffs(spotDkkMwh, hour) {
        var t = {system: 0, trans: 0, el: 0, nettarif: 0}
        var done = 0
        var now = new Date()

        function checkDone() {
            done++
            if (done === 4) {
                var nettarifC = t.nettarifC
                var nettarif = 0
                if (nettarifC) {
                    var p = nettarifC["Price" + (hour + 1)]
                    nettarif = (p === null || p === undefined) ? 0 : p
                }
                totalPrice = (spotDkkMwh / 1000.0 + nettarif + t.system + t.trans + t.el) * 1.25
                statusMsg = "OK"
            }
        }

        httpGet(buildTariffUrl(ENERGINET_GLN, "Systemtarif"), function(e, d) {
            if (!e && d && d.records) { var r = pickValid(d.records, now); if (r) t.system = r.Price1 || 0 }
            checkDone()
        })
        httpGet(buildTariffUrl(ENERGINET_GLN, "Transmissions nettarif"), function(e, d) {
            if (!e && d && d.records) { var r = pickValid(d.records, now); if (r) t.trans = r.Price1 || 0 }
            checkDone()
        })
        httpGet(buildTariffUrl(ENERGINET_GLN, "Elafgift"), function(e, d) {
            if (!e && d && d.records) { var r = pickValid(d.records, now); if (r) t.el = r.Price1 || 0 }
            checkDone()
        })
        httpGet(buildTariffUrl(GRID_GLN, "Nettarif C"), function(e, d) {
            if (!e && d && d.records) { var r = pickValid(d.records, now); if (r) t.nettarifC = r }
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
                text: "DK2 \u00b7 Radius Elnet"
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
                text: widget.totalPrice > 0 ? formatKr(widget.totalPrice) + " kr/kWh"
                    : widget.spotPrice > 0 ? formatKr(widget.spotPrice) + " kr spot"
                    : widget.statusMsg
                color: widget.totalPrice > 0 ? Theme.highlightColor
                    : widget.spotPrice > 0 ? Theme.highlightColor
                    : widget.statusMsg.indexOf("Fejl") >= 0 || widget.statusMsg.indexOf("HTTP") >= 0 ? Theme.errorColor
                    : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }
        }

        Label {
            visible: widget.currentTime !== ""
            height: visible ? implicitHeight : 0
            text: "Lige nu: " + widget.currentTime + " \u00b7 inkl. tariffer og moms"
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
