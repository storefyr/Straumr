import QtQuick 2.6
import Sailfish.Silica 1.0

Loader {
    id: root

    property var item: null

    width: parent ? parent.width : Screen.width
    height: Math.max(Theme.paddingLarge, item ? item.implicitHeight : 0)
    source: "PriceWidgetContent.qml"

    onLoaded: {
        item = root.item
    }
}
