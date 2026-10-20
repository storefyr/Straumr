import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/PriceFetcher.js" as PF

Item {
    id: root

    property var prices: []
    property var tariffs: null
    property bool showNowLine: true
    property real barWidth: 0
    property real graphPadding: Theme.paddingMedium

    height: 200

    function totalForRecord(record) {
        if (!record || !tariffs)
            return 0
        var hour = parseInt(record["TimeDK"].substring(11, 13), 10)
        return PF.calculateTotalPriceKwh(record["DayAheadPriceDKK"], tariffs, hour)
    }

    function barColor(total) {
        var lvl = PF.totalPriceLevel(total)
        if (lvl === 0) return "#4caf50"
        if (lvl === 1) return "#8bc34a"
        if (lvl === 2) return "#ff9800"
        return "#f44336"
    }

    function maxPrice() {
        var max = 0
        for (var i = 0; i < prices.length; i++) {
            var t = totalForRecord(prices[i])
            if (t > max) max = t
        }
        return max > 0 ? max : 1
    }

    function currentIndex() {
        if (prices.length === 0)
            return -1
        var firstDate = prices[0]["TimeDK"].substring(0, 10)
        var now = new Date()
        var today = now.getFullYear() + "-" + PF.pad(now.getMonth() + 1) + "-" + PF.pad(now.getDate())
        if (firstDate !== today)
            return -1
        var nowISO = now.getFullYear() + "-" + PF.pad(now.getMonth() + 1) + "-" + PF.pad(now.getDate()) +
                     "T" + PF.pad(now.getHours()) + ":" + PF.pad(now.getMinutes()) + ":00"
        for (var i = 0; i < prices.length; i++) {
            if (prices[i]["TimeDK"] > nowISO)
                return i
        }
        return prices.length - 1
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentWidth: Math.max(root.width, prices.length * root.barWidth + 2 * root.graphPadding)
        flickableDirection: Flickable.HorizontalFlick

        Canvas {
            id: canvas
            width: flickable.contentWidth
            height: root.height - 30
            anchors.top: parent.top

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                if (prices.length === 0)
                    return

                var max = root.maxPrice()
                var chartHeight = height - 10
                var chartTop = 5
                var n = prices.length
                var bw = root.barWidth
                var gap = 1
                var barW = bw - gap

                for (var i = 0; i < n; i++) {
                    var total = root.totalForRecord(prices[i])
                    var barH = (total / max) * chartHeight
                    var x = root.graphPadding + i * bw
                    var y = chartTop + chartHeight - barH

                    ctx.fillStyle = root.barColor(total)
                    ctx.fillRect(x, y, barW, barH)

                    if (barH > 18) {
                        ctx.fillStyle = "white"
                        ctx.font = "10px sans-serif"
                        ctx.textAlign = "center"
                        ctx.fillText(PF.formatTotalKr(total), x + barW / 2, y + 12)
                    }
                }

                if (root.showNowLine) {
                var ci = root.currentIndex()
                if (ci >= 0 && ci < n) {
                    var cx = root.graphPadding + ci * bw + barW / 2
                    ctx.strokeStyle = Theme.highlightColor
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.moveTo(cx, 0)
                    ctx.lineTo(cx, height)
                    ctx.stroke()
                }
                }
            }
        }

        Row {
            id: timeLabels
            y: canvas.height
            x: root.graphPadding
            spacing: 0
            height: 20

            Repeater {
                model: prices.length

                Label {
                    width: root.barWidth
                    font.pixelSize: Theme.fontSizeExtraSmall - 2
                    color: Theme.secondaryColor
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        if (index % 4 !== 0) return ""
                        var t = prices[index]["TimeDK"]
                        return t ? t.substring(11, 13) : ""
                    }
                }
            }
        }
    }

    Label {
        visible: prices.length === 0
        anchors.centerIn: parent
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeSmall
        text: qsTr("Ingen data")
    }

    onPricesChanged: canvas.requestPaint()
    onTariffsChanged: canvas.requestPaint()
    Component.onCompleted: {
        var n = prices.length > 0 ? prices.length : 96
        barWidth = Math.max(8, (root.width - 2 * graphPadding) / n)
        canvas.requestPaint()
    }
}
