import QtQuick 2.6

// MINIMAL TEST WIDGET — kun en rød boks
// Hvis denne vises: problemet er i PriceWidget.qml's kode (imports, syntax, etc.)
// Hvis denne IKKE vises: problemet er i JSON/packaging/registrering

Rectangle {
    id: root

    width: parent ? parent.width : 360
    height: 80
    implicitWidth: width
    implicitHeight: height
    color: "red"

    property bool active: visible

    function refresh() {
        console.log("[Straumr-Widget] MINIMAL TEST: refresh() called! visible=" + visible)
    }
    function reload() { refresh() }
    function save() {}

    Component.onCompleted: {
        console.log("[Straumr-Widget] MINIMAL TEST: Component.onCompleted! visible=" + visible + " width=" + width + " height=" + height)
        refresh()
    }
    onVisibleChanged: {
        console.log("[Straumr-Widget] MINIMAL TEST: visible changed to " + visible)
        if (visible) refresh()
    }

    Text {
        anchors.centerIn: parent
        text: "STRAUMR TEST — HVIS DU SER DETTE, VIRKER WIDGET!"
        color: "white"
        font.pixelSize: 16
        font.bold: true
        wrapMode: Text.Wrap
        width: parent.width - 20
        horizontalAlignment: Text.AlignHCenter
    }
}
