import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../js/PriceFetcher.js" as PF
import "../components"

Page {
    id: page

    property var currentPrice: null
    property var todayPrices: []
    property bool loading: true

    function refresh() {
        loading = true
        PF.getTodayPrices(function(err, records) {
            loading = false
            if (!err && records) {
                todayPrices = records
                var nowISO = new Date().toISOString().slice(0, 16) + "00"
                for (var i = 0; i < records.length; i++) {
                    if (records[i].TimeDK <= nowISO)
                        currentPrice = records[i]
                    else
                        break
                }
            }
        })
    }

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
                loading: page.loading
                hasError: !page.loading && page.currentPrice === null
                priceDkkMwh: page.currentPrice ? page.currentPrice.DayAheadPriceDKK : 0
                timeLabel: {
                    if (!page.currentPrice)
                        return ""
                    var t = page.currentPrice.TimeDK
                    return qsTr("Aktuel spotpris") + " · " + t.substring(11, 16)
                }
            }

            SectionHeader {
                text: qsTr("I dag (DK2)")
            }

            Repeater {
                model: page.todayPrices
                delegate: BackgroundItem {
                    width: parent.width
                    height: Theme.itemSizeSmall

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
                                var lvl = PF.priceLevel(modelData.DayAheadPriceDKK)
                                if (lvl === 0) return "#4caf50"
                                if (lvl === 1) return "#8bc34a"
                                if (lvl === 2) return "#ff9800"
                                return "#f44336"
                            }
                        }

                        Label {
                            color: Theme.primaryColor
                            text: PF.formatOre(modelData.DayAheadPriceDKK) + " øre"
                        }

                        Label {
                            width: parent.width - 60 - Theme.paddingMedium * 3 - Theme.paddingMedium
                            horizontalAlignment: Text.AlignRight
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: Theme.fontSizeSmall
                            text: PF.formatKr(modelData.DayAheadPriceDKK) + " kr/kWh"
                        }
                    }
                }
            }

            Label {
                visible: !page.loading && page.todayPrices.length === 0
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                text: qsTr("Ingen prisdata. Tjek din internetforbindelse.")
            }

            VerticalScrollDecorator { }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Opdater")
                onClicked: page.refresh()
            }
        }
    }

    Label {
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
        text: qsTr("Spotpriser fra Energinet (energidataservice.dk) · ekskl. moms, afgifter og nettarif")
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        onTriggered: page.refresh()
    }
}
