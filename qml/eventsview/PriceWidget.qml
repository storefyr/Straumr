import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: root

    width: parent ? parent.width : Screen.width
    implicitWidth: width
    height: content.implicitHeight
    implicitHeight: height

    // Lipstick sets visibility; treat visible && on Events View as "active".
    property bool active: visible && (typeof eventsViewVisible !== "undefined" ? eventsViewVisible : true)

    function refresh() { content.refresh() }
    function reload() { content.refresh() }
    function save() {}

    Component.onCompleted: if (active) refresh()
    onActiveChanged: if (active) refresh()

    Loader {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        source: Qt.resolvedUrl("PriceWidgetContent.qml")
    }
}
