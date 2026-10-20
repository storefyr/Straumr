import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    width: parent ? parent.width : Screen.width
    implicitHeight: 200
    color: "red"

    Label {
        anchors.centerIn: parent
        text: "HEJ VERDEN\nStraumr widget test"
        color: "white"
        font.pixelSize: Theme.fontSizeLarge
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
    }
}
