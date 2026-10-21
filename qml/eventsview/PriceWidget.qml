import QtQuick 2.6
import Sailfish.Silica 1.0

Rectangle {
    width: parent ? parent.width : 0
    height: 120
    color: "red"

    Text {
        anchors.centerIn: parent
        text: "STRAUMR DEBUG WIDGET"
        color: "white"
        font.pixelSize: Theme.fontSizeLarge
        font.bold: true
    }
}
