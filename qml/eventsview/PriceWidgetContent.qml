import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: widget

    width: parent ? parent.width : Screen.width
    implicitHeight: Math.max(120, contentColumn.height + 2 * Theme.paddingMedium)

    property var todayPrices: []
    property var currentPrice: null
    property real currentTotal: 0
    property bool loading: true
    property string statusMsg: "Henter..."

    readonly property string API_URL: "https://api.energidataservice.dk/dataset/DayAheadPrices"

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

    function formatKr(v) { return v.toFixed(2).replace(".", ",") }

    function refresh() {
        loading = true
        statusMsg = "Henter..."
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== 4) return
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    if (data.records && data.records.length > 0) {
                        todayPrices = data.records
                        statusMsg = "OK: " + data.records.length + " priser"
                        var now = new Date()
                        var nowISO = now.getFullYear() + "-" + pad(now.getMonth()+1) + "-" + pad(now.getDate()) +
                                     "T" + pad(now.getHours()) + ":" + pad(now.getMinutes()) + ":00"
                        for (var i = 0; i < data.records.length; i++) {
                            if (data.records[i]["TimeDK"] <= nowISO) currentPrice = data.records[i]
                            else break
                        }
                        if (currentPrice) {
                            currentTotal = currentPrice["DayAheadPriceDKK"] / 1000.0
                        }
                    } else {
                        statusMsg = "Ingen data"
                    }
                } catch (e) {
                    statusMsg = "Parse fejl: " + e.message
                }
            } else {
                statusMsg = "HTTP " + xhr.status
            }
            loading = false
        }
        xhr.open("GET", buildSpotUrl(), true)
        xhr.timeout = 15000
        xhr.send()
    }

    Component.onCompleted: refresh()

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
                    : widget.currentTotal > 0 ? formatKr(widget.currentTotal) + " kr spot"
                    : widget.statusMsg
                color: widget.currentTotal > 0 ? Theme.highlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }
        }

        Label {
            visible: widget.currentPrice !== null && !widget.loading
            height: visible ? implicitHeight : 0
            text: widget.currentPrice ? "Lige nu: " + widget.currentPrice["TimeDK"].substring(11, 16) : ""
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
        }

        Label {
            text: "Priser: " + widget.todayPrices.length
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            visible: widget.todayPrices.length > 0
            height: visible ? implicitHeight : 0
        }
    }
}
