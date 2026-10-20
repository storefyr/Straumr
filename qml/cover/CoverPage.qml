import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/PriceFetcher.js" as PF
import "../components"

CoverBackground {
    id: cover

    property var currentPrice: null
    property bool loading: true
    property string errorMessage: ""

    function refresh() {
        loading = true
        errorMessage = ""
        PF.fetch(function(err, records) {
            loading = false
            if (err) {
                console.warn("[Straumr] Cover fetch fejlede:", err.message)
                currentPrice = null
                errorMessage = err.message || "Ukendt fejl"
            } else {
                currentPrice = PF.findCurrentPrice(records, new Date())
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
        text: qsTr("Straumr \u00b7 DK2")
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
