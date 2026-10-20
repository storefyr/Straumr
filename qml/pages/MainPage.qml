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
                    return qsTr("Aktuel pris") + " \u00b7 " + t.substring(11, 16)
                }
            }

            SectionHeader {
                text: qsTr("I dag (") + priceModel.priceArea + qsTr(") \u00b7 inkl. tariffer og moms")
            }

            PriceGraph {
                width: parent.width
                height: 180
                prices: priceModel.prices
                tariffs: priceModel.tariffs
            }

            PriceList {
                width: parent.width
                height: Math.min(contentHeight, page.height - column.y - footer.height - Theme.paddingLarge)
                prices: priceModel.prices
                tariffs: priceModel.tariffs
                interactive: false
            }

            Label {
                visible: !priceModel.loading && priceModel.prices.length === 0
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                text: priceModel.errorMessage !== ""
                    ? qsTr("Ingen prisdata: ") + priceModel.errorMessage
                    : qsTr("Ingen prisdata. Tjek din internetforbindelse.")
            }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Opdater")
                onClicked: priceModel.refresh()
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
        text: qsTr("Spotpriser fra Energinet \u00b7 Tariffer fra DatahubPricelist \u00b7 Netselskab: ") + priceModel.gridName + qsTr(" \u00b7 ekskl. elselskabstill\u00e6g")
    }
}
