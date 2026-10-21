import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: widget

    width: parent ? parent.width : Screen.width
    implicitHeight: 120

    property string statusMsg: "Starter..."
    property real spotPrice: 0
    property string currentTime: ""

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
                                statusMsg = "OK (" + data.records.length + ")"
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

    Component.onCompleted: {
        statusMsg = "Component klar"
        refresh()
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
                text: widget.spotPrice > 0 ? widget.spotPrice.toFixed(2).replace(".", ",") + " kr spot"
                    : widget.statusMsg
                color: widget.spotPrice > 0 ? Theme.highlightColor
                    : widget.statusMsg.indexOf("Fejl") >= 0 || widget.statusMsg.indexOf("HTTP") >= 0 ? Theme.errorColor
                    : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }
        }

        Label {
            visible: widget.currentTime !== ""
            height: visible ? implicitHeight : 0
            text: "Lige nu: " + widget.currentTime
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
