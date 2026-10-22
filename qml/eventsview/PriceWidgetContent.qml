import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: widget

    width: parent ? parent.width : Screen.width
    implicitWidth: width
    implicitHeight: column.height
    height: implicitHeight

    property string statusMsg: "Starter..."
    property real spotPrice: 0
    property real totalPrice: 0
    property string currentTime: ""

    readonly property string GRID_GLN: "5790000705689"
    readonly property string ENERGINET_GLN: "5790000432752"

    // Fallback nettarif values (Radius Elnet, Nettarif C, vinter 2026-10-01 to 2027-04-01)
    readonly property var FALLBACK_NETTARIF: {
        "Price1": 0.106175, "Price2": 0.106175, "Price3": 0.106175,
        "Price4": 0.106175, "Price5": 0.106175, "Price6": 0.106175,
        "Price7": 0.318524, "Price8": 0.318524, "Price9": 0.318524,
        "Price10": 0.318524, "Price11": 0.318524, "Price12": 0.318524,
        "Price13": 0.318524, "Price14": 0.318524, "Price15": 0.318524,
        "Price16": 0.318524, "Price17": 0.318524,
        "Price18": 0.955573, "Price19": 0.955573, "Price20": 0.955573, "Price21": 0.955573,
        "Price22": 0.318524, "Price23": 0.318524, "Price24": 0.318524
    }

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
        return "https://api.energidataservice.dk/dataset/DatahubPricelist?filter=" + filter +
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
        xhr.onerror = function() { cb(new Error("Netvaerk"), null) }
        xhr.open("GET", url, true)
        xhr.timeout = 15000
        xhr.ontimeout = function() { cb(new Error("Timeout"), null) }
        xhr.send()
    }

    function refresh() {
        statusMsg = "Henter..."
        try {
            if (typeof XMLHttpRequest === "undefined") {
                statusMsg = "Ingen XMLHttpRequest!"
                return
            }
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
                                statusMsg = "Ingen nuvaerende"
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
                statusMsg = "Netvaerksfejl"
            }
            xhr.open("GET", url, true)
            xhr.timeout = 15000
            xhr.send()
        } catch (e) {
            statusMsg = "Fejl: " + e.message
        }
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

    function fetchTariffs(spotDkkMwh, hour) {
        var t = {system: 0, trans: 0, el: 0, nettarifC: null}
        var now = new Date()

        // Sequential fetch to avoid rate limiting in Lipstick process
        httpGet(buildTariffUrl(ENERGINET_GLN, "Systemtarif"), function(e1, d1) {
            if (!e1 && d1 && d1.records) { var r = pickValid(d1.records, now); if (r) t.system = r.Price1 || 0 }

            httpGet(buildTariffUrl(ENERGINET_GLN, "Transmissions nettarif"), function(e2, d2) {
                if (!e2 && d2 && d2.records) { var r = pickValid(d2.records, now); if (r) t.trans = r.Price1 || 0 }

                httpGet(buildTariffUrl(ENERGINET_GLN, "Elafgift"), function(e3, d3) {
                    if (!e3 && d3 && d3.records) { var r = pickValid(d3.records, now); if (r) t.el = r.Price1 || 0 }

                    httpGet(buildTariffUrl(GRID_GLN, "Nettarif C"), function(e4, d4) {
                        if (!e4 && d4 && d4.records) { var r = pickValid(d4.records, now); if (r) t.nettarifC = r }

                        // Use fallback if Nettarif C fetch failed
                        var nettarifSource = t.nettarifC || widget.FALLBACK_NETTARIF
                        var p = nettarifSource["Price" + (hour + 1)]
                        var nettarif = (p === null || p === undefined) ? 0 : p

                        totalPrice = (spotDkkMwh / 1000.0 + nettarif + t.system + t.trans + t.el) * 1.25
                        statusMsg = "OK"
                    })
                })
            })
        })
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.highlightBackgroundColor
        opacity: 0.4
        radius: Theme.paddingSmall
    }

    Column {
        id: column
        width: parent.width
        spacing: Theme.paddingSmall
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
            topMargin: Theme.paddingMedium
            bottomMargin: Theme.paddingMedium
        }

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
                text: widget.totalPrice > 0 ? widget.totalPrice.toFixed(2).replace(".", ",") + " kr/kWh"
                    : widget.spotPrice > 0 ? widget.spotPrice.toFixed(2).replace(".", ",") + " kr spot"
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
