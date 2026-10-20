import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/PriceFetcher.js" as PF
import "../components"

CoverBackground {
    id: cover

    Column {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: footer.top
            margins: Theme.paddingMedium
        }
        spacing: Theme.paddingSmall

        PriceDisplay {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            loading: priceModel.loading
            hasError: priceModel.hasError
            errorText: priceModel.errorMessage
            priceDkkMwh: priceModel.currentPrice["DayAheadPriceDKK"] !== undefined ? priceModel.currentPrice["DayAheadPriceDKK"] : 0
            totalPriceKwh: priceModel.currentTotalKwh
            showTotal: true
            timeLabel: {
                if (!priceModel.currentPrice || priceModel.currentPrice["TimeDK"] === undefined)
                    return ""
                var t = priceModel.currentPrice["TimeDK"]
                return qsTr("Pris lige nu") + " (" + t.substring(11, 16) + ")"
            }
            fontSize: Theme.fontSizeExtraLarge
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            text: qsTr("I dag")
        }

        PriceGraph {
            width: parent.width
            height: cover.height * 0.25
            prices: priceModel.todayPrices
            tariffs: priceModel.tariffs
            showNowLine: true
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            text: qsTr("I morgen")
            visible: priceModel.tomorrowPrices.length > 0
        }

        PriceGraph {
            width: parent.width
            height: cover.height * 0.25
            prices: priceModel.tomorrowPrices
            tariffs: priceModel.tariffs
            showNowLine: false
            visible: priceModel.tomorrowPrices.length > 0
        }
    }

    Label {
        id: footer
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            margins: Theme.paddingSmall
        }
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeExtraSmall
        text: qsTr("Straumr \u00b7 ") + priceModel.priceArea + qsTr(" \u00b7 ") + priceModel.gridName
    }

    onStatusChanged: {
        if (status === Cover.Activating)
            priceModel.refresh()
    }

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: priceModel.refresh()
        }
    }
}
