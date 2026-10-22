import QtQuick 2.6
import Sailfish.Silica 1.0

// ============================================================
// Straumr Events View Widget — v1.9.1 DEBUG
// Log med: journalctl -f | grep "\[Straumr-Widget\]"
// ============================================================

Item {
    id: root

    // ---- DEBUG LOGGING ----
    function log(msg) {
        console.log("[Straumr-Widget] " + msg)
    }

    width: parent ? parent.width : Screen.width
    implicitWidth: width
    height: Math.max(column.height + Theme.paddingMedium * 2, Theme.itemSizeMedium)
    implicitHeight: height

    // Fjernet eventsViewVisible dependency — den kan fejle hvis Lipstick ikke sætter den
    property bool active: visible

    property string statusMsg: "Starter..."
    property real spotPrice: 0
    property real totalPrice: 0
    property string currentTime: ""

    readonly property string GRID_GLN: "5790000705689"
    readonly property string ENERGINET_GLN: "5790000432752"

    // Fallback nettarif values (Radius Elnet, Nettarif C, vinter 2026)
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
        log("httpGet: " + url.substring(0, 80) + "...")
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== 4) return
            log("httpGet response: status=" + xhr.status + " url=" + url.substring(url.lastIndexOf('/')+1, url.indexOf('?')))
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    log("httpGet parsed: records=" + (data.records ? data.records.length : "none"))
                    cb(null, data)
                } catch (e) {
                    log("httpGet PARSE ERROR: " + e.message)
                    cb(e, null)
                }
            } else {
                log("httpGet HTTP ERROR: " + xhr.status + " body=" + xhr.responseText.substring(0, 200))
                cb(new Error("HTTP " + xhr.status), null)
            }
        }
        xhr.onerror = function() {
            log("httpGet NETWORK ERROR for " + url.substring(0, 80))
            cb(new Error("Netvaerk"), null)
        }
        xhr.ontimeout = function() {
            log("httpGet TIMEOUT for " + url.substring(0, 80))
            cb(new Error("Timeout"), null)
        }
        xhr.open("GET", url, true)
        xhr.timeout = 15000
        xhr.send()
    }

    function refresh() {
        log("=== refresh() called ===")
        log("active=" + active + " visible=" + visible + " width=" + width + " height=" + height)
        statusMsg = "Henter..."
        try {
            if (typeof XMLHttpRequest === "undefined") {
                log("FATAL: XMLHttpRequest is undefined!")
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
            log("Fetching spot prices from: " + url.substring(0, 100) + "...")

            var xhr = new XMLHttpRequest()
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== 4) return
                log("Spot response: status=" + xhr.status)
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        log("Spot records: " + (data.records ? data.records.length : 0))
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
                                log("Current spot: " + spotPrice + " kr/kWh at " + currentTime)
                                statusMsg = "Henter tariffer..."
                                fetchTariffs(current["DayAheadPriceDKK"], now.getHours())
                            } else {
                                log("No current price record found (now=" + nowISO + ")")
                                statusMsg = "Ingen nuvaerende"
                            }
                        } else {
                            log("No records in spot response!")
                            statusMsg = "Ingen records"
                        }
                    } catch (e) {
                        log("Spot PARSE ERROR: " + e.message)
                        statusMsg = "Parse: " + e.message
                    }
                } else {
                    log("Spot HTTP ERROR: " + xhr.status + " body=" + xhr.responseText.substring(0, 200))
                    statusMsg = "HTTP " + xhr.status
                }
            }
            xhr.onerror = function() {
                log("Spot NETWORK ERROR")
                statusMsg = "Netvaerksfejl"
            }
            xhr.ontimeout = function() {
                log("Spot TIMEOUT")
                statusMsg = "Timeout"
            }
            xhr.open("GET", url, true)
            xhr.timeout = 15000
            xhr.send()
        } catch (e) {
            log("refresh() EXCEPTION: " + e.message + "\n" + e.stack)
            statusMsg = "Fejl: " + e.message
        }
    }

    function reload() {
        log("reload() called")
        refresh()
    }
    function save() {
        log("save() called")
    }

    function pickValid(records, date) {
        if (!records || records.length === 0) {
            log("pickValid: no records")
            return null
        }
        var target = date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
        for (var i = 0; i < records.length; i++) {
            var from = records[i].ValidFrom ? records[i].ValidFrom.substring(0, 10) : "0000-00-00"
            var to = records[i].ValidTo ? records[i].ValidTo.substring(0, 10) : "9999-99-99"
            if (target >= from && target < to) {
                log("pickValid: found record ValidFrom=" + from + " ValidTo=" + to)
                return records[i]
            }
        }
        log("pickValid: no match for " + target + ", using first record")
        return records[0]
    }

    function fetchTariffs(spotDkkMwh, hour) {
        log("fetchTariffs: spot=" + spotDkkMwh + " hour=" + hour)
        var t = {system: 0, trans: 0, el: 0, nettarifC: null}
        var now = new Date()

        httpGet(buildTariffUrl(ENERGINET_GLN, "Systemtarif"), function(e1, d1) {
            if (!e1 && d1 && d1.records) { var r = pickValid(d1.records, now); if (r) t.system = r.Price1 || 0 }
            log("Tariff system=" + t.system)

            httpGet(buildTariffUrl(ENERGINET_GLN, "Transmissions nettarif"), function(e2, d2) {
                if (!e2 && d2 && d2.records) { var r = pickValid(d2.records, now); if (r) t.trans = r.Price1 || 0 }
                log("Tariff trans=" + t.trans)

                httpGet(buildTariffUrl(ENERGINET_GLN, "Elafgift"), function(e3, d3) {
                    if (!e3 && d3 && d3.records) { var r = pickValid(d3.records, now); if (r) t.el = r.Price1 || 0 }
                    log("Tariff el=" + t.el)

                    httpGet(buildTariffUrl(GRID_GLN, "Nettarif C"), function(e4, d4) {
                        if (!e4 && d4 && d4.records) { var r = pickValid(d4.records, now); if (r) t.nettarifC = r }
                        log("Tariff nettarifC=" + (t.nettarifC ? "OK" : "NULL (using fallback)"))

                        var nettarifSource = t.nettarifC || root.FALLBACK_NETTARIF
                        var p = nettarifSource["Price" + (hour + 1)]
                        var nettarif = (p === null || p === undefined) ? 0 : p

                        totalPrice = (spotDkkMwh / 1000.0 + nettarif + t.system + t.trans + t.el) * 1.25
                        log("TOTAL: spot=" + (spotDkkMwh/1000).toFixed(4) + " nettarif=" + nettarif.toFixed(4) +
                            " system=" + t.system + " trans=" + t.trans + " el=" + t.el +
                            " => " + totalPrice.toFixed(4) + " kr/kWh")
                        statusMsg = "OK"
                    })
                })
            })
        })
    }

    // ---- LIVSCYKLUS LOGGING ----
    Component.onCompleted: {
        log("=== Component.onCompleted ===")
        log("parent=" + (parent ? "yes" : "null"))
        log("width=" + width + " height=" + height)
        log("visible=" + visible + " active=" + active)
        log("eventsViewVisible=" + (typeof eventsViewVisible !== "undefined" ? eventsViewVisible : "UNDEFINED"))
        log("Screen.width=" + Screen.width + " Screen.height=" + Screen.height)
        if (active) {
            log("Starting initial refresh...")
            refresh()
        } else {
            log("NOT active — skipping initial refresh")
        }
    }

    onVisibleChanged: {
        log("visible changed to: " + visible + " (active=" + active + ")")
        if (active) refresh()
    }

    onActiveChanged: {
        log("active changed to: " + active)
        if (active) refresh()
    }

    onWidthChanged: log("width changed to: " + width)
    onHeightChanged: log("height changed to: " + height)

    Timer {
        interval: 300000  // 5 minutes
        repeat: true
        running: root.active
        onTriggered: {
            log("Timer triggered — refreshing")
            root.refresh()
        }
    }

    // ---- DEBUG: Rød kant så vi kan se hvis widget loades ----
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "red"
        border.width: 2
        radius: Theme.paddingSmall
        opacity: 0.5
    }

    // Baggrund
    Rectangle {
        anchors.fill: parent
        color: Theme.highlightBackgroundColor
        opacity: 0.15
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

        // DEBUG: Vis altid en synlig indikator
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
                text: root.totalPrice > 0 ? root.totalPrice.toFixed(2).replace(".", ",") + " kr/kWh"
                    : root.spotPrice > 0 ? root.spotPrice.toFixed(2).replace(".", ",") + " kr spot"
                    : root.statusMsg
                color: root.totalPrice > 0 ? Theme.highlightColor
                    : root.spotPrice > 0 ? Theme.highlightColor
                    : root.statusMsg.indexOf("Fejl") >= 0 || root.statusMsg.indexOf("HTTP") >= 0 ? Theme.errorColor
                    : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }
        }

        Label {
            visible: root.currentTime !== ""
            height: visible ? implicitHeight : 0
            text: "Lige nu: " + root.currentTime + " · inkl. tariffer og moms"
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
        }

        // DEBUG: Vis teknisk info
        Label {
            text: "DEBUG: w=" + Math.round(root.width) + " h=" + Math.round(root.height) +
                  " vis=" + root.visible + " act=" + root.active +
                  " evv=" + (typeof eventsViewVisible !== "undefined" ? eventsViewVisible : "undef")
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            opacity: 0.6
        }
    }
}
