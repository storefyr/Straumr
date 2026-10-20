import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/PriceFetcher.js" as PF
import "../components"

Page {
    id: page

    property var currentPrice: null
    property var todayPrices: []
    property var tariffs: null
    property bool loading: true
    property string errorMessage: ""

    function refresh() {
        loading = true
        errorMessage = ""
        PF.fetchAll(function(err, records, t) {
            loading = false
            if (err) {
                console.warn("[Straumr] Page fetch fejlede:", err.message)
                errorMessage = err.message || "Ukendt fejl"
            } else if (records) {
                tariffs = t
                todayPrices = records
                currentPrice = PF.findCurrentPrice(records, new Date())
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
                errorText: page.errorMessage
                priceDkkMwh: page.currentPrice ? page.currentPrice.DayAheadPriceDKK : 0
                totalPriceKwh: {
                    if (!page.currentPrice || !page.tariffs)
                        return 0
                    var hour = parseInt(page.currentPrice.TimeDK.substring(11, 13), 10)
                    return PF.calculateTotalPriceKwh(page.currentPrice.DayAheadPriceDKK, page.tariffs, hour)
                }
                showTotal: true
                timeLabel: {
                    if (!page.currentPrice)
                        return ""
                    var t = page.currentPrice.TimeDK
                    return qsTr("Aktuel pris") + " \u00b7 " + t.substring(11, 16)
                }
            }

            SectionHeader {
                text: qsTr("I dag (DK2) \u00b7 inkl. tariffer og moms")
            }

            Repeater {
                model: page.todayPrices
                delegate: BackgroundItem {
                    id: rowItem
                    width: parent.width
                    height: Theme.itemSizeSmall

                    property real spotDkkMwh: modelData.DayAheadPriceDKK
                    property int hour: parseInt(modelData.TimeDK.substring(11, 13), 10)
                    property var t: page.tariffs

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
            }

            Label {
                visible: !page.loading && page.todayPrices.length === 0
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                text: page.errorMessage !== ""
                    ? qsTr("Ingen prisdata: ") + page.errorMessage
                    : qsTr("Ingen prisdata. Tjek din internetforbindelse.")
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
        text: qsTr("Spotpriser fra Energinet \u00b7 Tariffer fra DatahubPricelist \u00b7 Netselskab: ") + PF.GRID_NAME + qsTr(" \u00b7 ekskl. elselskabstillæg")
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        onTriggered: page.refresh()
    }
}
