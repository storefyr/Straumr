import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/PriceFetcher.js" as PF
import "../components"

CoverBackground {
    id: cover

    PriceDisplay {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: Theme.paddingMedium
        }
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
