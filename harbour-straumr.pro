TARGET = harbour-straumr

CONFIG += sailfishapp

SOURCES += src/harbour-straumr.cpp \
    src/pricemodel.cpp

DISTFILES += qml/harbour-straumr.qml \
    qml/cover/CoverPage.qml \
    qml/pages/MainPage.qml \
    qml/js/PriceFetcher.js \
    qml/components/PriceDisplay.qml \
    qml/components/PriceGraph.qml \
    qml/eventsview/PriceWidget.qml \
    qml/eventsview/PriceWidgetContent.qml \
    rpm/harbour-straumr.spec \
    harbour-straumr.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

HEADERS += src/pricemodel.h

OTHER_FILES += README.md \
    rpm/harbour-straumr.spec \
    rpm/harbour-straumr.yaml

# Events View widget: install QML to app dir + JSON to Lipstick's eventswidgets dir
# This follows the Admirality pattern (single RPM, no separate widget package)
eventsWidgetQml.files = qml/eventsview/PriceWidget.qml \
                        qml/eventsview/PriceWidgetContent.qml
eventsWidgetQml.path = /usr/share/harbour-straumr/qml/eventsview

eventsWidgetJson.files = widget/eventswidgets/harbour-straumr.json
eventsWidgetJson.path = /usr/share/lipstick/eventswidgets

INSTALLS += eventsWidgetQml eventsWidgetJson
