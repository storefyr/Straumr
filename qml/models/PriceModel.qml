import QtQuick 2.0
import "../js/PriceFetcher.js" as PF

QtObject {
    id: model

    property var prices: []
    property var tariffs: null
    property var currentPrice: null
    property real currentTotalKwh: 0
    property bool loading: true
    property bool hasError: false
    property string errorMessage: ""
    property string gridName: PF.GRID_NAME
    property string priceArea: PF.PRICE_AREA

    signal refreshed()

    function refresh() {
        loading = true
        hasError = false
        errorMessage = ""
        PF.fetchAll(function(err, records, t) {
            loading = false
            if (err) {
                console.warn("[Straumr] PriceModel fetch fejlede:", err.message)
                hasError = true
                errorMessage = err.message || "Ukendt fejl"
                prices = []
                tariffs = null
                currentPrice = null
                currentTotalKwh = 0
            } else {
                prices = records
                tariffs = t
                currentPrice = PF.findCurrentPrice(records, new Date())
                if (currentPrice) {
                    var hour = parseInt(currentPrice.TimeDK.substring(11, 13), 10)
                    currentTotalKwh = PF.calculateTotalPriceKwh(currentPrice.DayAheadPriceDKK, tariffs, hour)
                } else {
                    currentTotalKwh = 0
                }
            }
            refreshed()
        })
    }

    function totalForRecord(record) {
        if (!record || !tariffs)
            return 0
        var hour = parseInt(record.TimeDK.substring(11, 13), 10)
        return PF.calculateTotalPriceKwh(record.DayAheadPriceDKK, tariffs, hour)
    }

    function timeLabel(record) {
        if (!record)
            return ""
        return record.TimeDK.substring(11, 16)
    }

    function hourOfRecord(record) {
        if (!record)
            return 0
        return parseInt(record.TimeDK.substring(11, 13), 10)
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        onTriggered: model.refresh()
    }
}
