import QtQuick 2.6
import Sailfish.Silica 1.0

Loader {
    width: parent ? parent.width : 0
    height: Math.max(Theme.paddingLarge, item ? item.implicitHeight : 0)
    source: Qt.resolvedUrl("PriceWidgetContent.qml")
}
