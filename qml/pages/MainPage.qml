import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/PriceFetcher.js" as PF
import "../components"

Page {
    id: page

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Straumr")
            }

            PriceDisplay {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 2 * Theme.horizontalPageMargin
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
                    return qsTr("Aktuel pris") + " \u00b7 " + t.substring(11, 16)
                }
            }

            SectionHeader {
                text: qsTr("I dag (") + app.priceModel.priceArea + qsTr(") \u00b7 inkl. tariffer og moms")
            }

            PriceList {
                width: parent.width
                height: Math.min(contentHeight, page.height - column.y - footer.height - Theme.paddingLarge)
                prices: app.priceModel.prices
                tariffs: app.priceModel.tariffs
                interactive: false
            }

            Label {
                visible: !app.priceModel.loading && app.priceModel.prices.length === 0
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                text: app.priceModel.errorMessage !== ""
                    ? qsTr("Ingen prisdata: ") + app.priceModel.errorMessage
                    : qsTr("Ingen prisdata. Tjek din internetforbindelse.")
            }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Opdater")
                onClicked: app.priceModel.refresh()
            }
        }
    }

    Label {
        id: footer
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: Theme.paddingSmall
        }
        horizontalAlignment: Text.AlignHCenter
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeExtraSmall
        wrapMode: Text.WordWrap
        text: qsTr("Spotpriser fra Energinet \u00b7 Tariffer fra DatahubPricelist \u00b7 Netselskab: ") + app.priceModel.gridName + qsTr(" \u00b7 ekskl. elselskabstill\u00e6g")
    }
}
