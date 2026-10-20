#include <QtQuick>
#include <sailfishapp.h>
#include "pricemodel.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    PriceModel priceModel;
    view->rootContext()->setContextProperty("priceModel", &priceModel);

    view->setSource(SailfishApp::pathTo(QStringLiteral("qml/harbour-straumr.qml")));
    view->show();

    return app->exec();
}
