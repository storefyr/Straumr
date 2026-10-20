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
        loading: app.priceModel.loading
        hasError: app.priceModel.hasError
        errorText: app.priceModel.errorMessage
        priceDkkMwh: app.priceModel.currentPrice ? app.priceModel.currentPrice.DayAheadPriceDKK : 0
        totalPriceKwh: app.priceModel.currentTotalKwh
        showTotal: true
        timeLabel: {
            if (!app.priceModel.currentPrice)
                return ""
            var t = app.priceModel.currentPrice.TimeDK
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
        text: qsTr("Straumr \u00b7 ") + app.priceModel.priceArea + qsTr(" \u00b7 ") + app.priceModel.gridName
    }

    onStatusChanged: {
        if (status === Cover.Activating)
            app.priceModel.refresh()
    }

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: app.priceModel.refresh()
        }
    }
}
