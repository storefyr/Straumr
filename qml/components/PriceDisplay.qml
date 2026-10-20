import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/PriceFetcher.js" as PF

Item {
    id: root

    property real priceDkkMwh: 0
    property string timeLabel: ""
    property bool loading: false
    property bool hasError: false
    property int fontSize: Theme.fontSizeExtraLarge

    readonly property int level: PF.priceLevel(priceDkkMwh)
    readonly property color levelColor: {
        switch (level) {
        case 0: return "#4caf50"
        case 1: return "#8bc34a"
        case 2: return "#ff9800"
        default: return "#f44336"
        }
    }
    readonly property string levelText: {
        switch (level) {
        case 0: return qsTr("Billig")
        case 1: return qsTr("Normal")
        case 2: return qsTr("Dyr")
        default: return qsTr("Meget dyr")
        }
    }

    height: column.height

    Column {
        id: column
        width: parent.width
        spacing: Theme.paddingSmall

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            color: root.hasError ? Theme.errorColor
                : root.loading ? Theme.secondaryColor
                : Theme.highlightColor
            font.pixelSize: root.fontSize
            text: {
                if (root.loading)
                    return qsTr("Henter priser…")
                if (root.hasError)
                    return qsTr("Kunne ikke hente priser")
                return PF.formatOre(root.priceDkkMwh) + " øre/kWh"
            }
        }

        Label {
            visible: !root.loading && !root.hasError && root.timeLabel !== ""
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeSmall
            text: root.timeLabel
        }

        Rectangle {
            visible: !root.loading && !root.hasError
            width: Theme.itemSizeSmall
            height: Theme.paddingMedium
            anchors.horizontalCenter: parent.horizontalCenter
            radius: height / 2
            color: root.levelColor
        }

        Label {
            visible: !root.loading && !root.hasError
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            color: root.levelColor
            font.pixelSize: Theme.fontSizeSmall
            text: root.levelText
        }
    }
}
