import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/PriceFetcher.js" as PF

SilicaListView {
    id: list

    property var prices: []
    property var tariffs: null

    function totalForRecord(record) {
        if (!record || !tariffs)
            return 0
        var hour = parseInt(record.TimeDK.substring(11, 13), 10)
        return PF.calculateTotalPriceKwh(record.DayAheadPriceDKK, tariffs, hour)
    }

    model: prices
    delegate: BackgroundItem {
        id: rowItem
        width: list.width
        height: Theme.itemSizeSmall

        property real spotDkkMwh: modelData.DayAheadPriceDKK
        property int hour: parseInt(modelData.TimeDK.substring(11, 13), 10)
        property var t: list.tariffs

        property real totalKwh: {
            if (!t) return 0
            return PF.calculateTotalPriceKwh(spotDkkMwh, t, hour)
        }

        Row {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin
            }
            spacing: Theme.paddingMedium

            Label {
                width: 60
                color: Theme.secondaryColor
                text: modelData.TimeDK.substring(11, 16)
            }

            Rectangle {
                width: Theme.paddingMedium
                height: width
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: {
                    var lvl = PF.totalPriceLevel(rowItem.totalKwh)
                    if (lvl === 0) return "#4caf50"
                    if (lvl === 1) return "#8bc34a"
                    if (lvl === 2) return "#ff9800"
                    return "#f44336"
                }
            }

            Column {
                spacing: 2

                Label {
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: PF.formatTotalKr(rowItem.totalKwh) + " kr"
                }

                Label {
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    text: qsTr("spot: ") + PF.formatKr(modelData.DayAheadPriceDKK) + " kr"
                }
            }
        }
    }

    VerticalScrollDecorator { }
}
