import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/PriceFetcher.js" as PF
import "../components"

CoverBackground {
    id: cover

    property var currentPrice: null
    property var tariffs: null
    property real totalPriceKwh: 0
    property bool loading: true
    property string errorMessage: ""

    function refresh() {
        loading = true
        errorMessage = ""
        PF.fetchAll(function(err, records, t) {
            loading = false
            if (err) {
                console.warn("[Straumr] Cover fetch fejlede:", err.message)
                currentPrice = null
                errorMessage = err.message || "Ukendt fejl"
            } else {
                tariffs = t
                currentPrice = PF.findCurrentPrice(records, new Date())
                if (currentPrice) {
                    var hour = parseInt(currentPrice.TimeDK.substring(11, 13), 10)
                    totalPriceKwh = PF.calculateTotalPriceKwh(currentPrice.DayAheadPriceDKK, tariffs, hour)
                }
            }
        })
    }

    PriceDisplay {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: Theme.paddingMedium
        }
        loading: cover.loading
        hasError: !cover.loading && cover.currentPrice === null
        errorText: cover.errorMessage
        priceDkkMwh: cover.currentPrice ? cover.currentPrice.DayAheadPriceDKK : 0
        totalPriceKwh: cover.totalPriceKwh
        showTotal: true
        timeLabel: {
            if (!cover.currentPrice)
                return ""
            var t = cover.currentPrice.TimeDK
            return qsTr("Pris lige nu") + " (" + t.substring(11, 16) + ")"
        }
        fontSize: Theme.fontSizeHuge
    }

    Label {
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            margins: Theme.paddingSmall
        }
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeExtraSmall
        text: qsTr("Straumr \u00b7 DK2 \u00b7 ") + PF.GRID_NAME
    }

    Component.onCompleted: refresh()

    onStatusChanged: {
        if (status === Cover.Activating)
            refresh()
    }

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: refresh()
        }
    }
}
