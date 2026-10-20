import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    width: parent ? parent.width : Screen.width
    implicitHeight: 200

    Rectangle {
        anchors.fill: parent
        color: "red"
    }

    Label {
        anchors.centerIn: parent
        text: "HEJ VERDEN\nStraumr widget test v2"
        color: "white"
        font.pixelSize: Theme.fontSizeLarge
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
    }
}
