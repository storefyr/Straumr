import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "models"

ApplicationWindow
{
    id: app

    property var priceModel: PriceModel {}

    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
}
