import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    width: parent ? parent.width : 0
    implicitHeight: content ? content.implicitHeight : 120

    property var content: null

    Component.onCompleted: {
        var comp = Qt.createComponent(Qt.resolvedUrl("PriceWidgetContent.qml"))
        if (comp.status === Component.Ready) {
            content = comp.createObject(this, {})
        } else {
            console.log("[Straumr] Failed to load PriceWidgetContent:", comp.errorString())
        }
    }
}
