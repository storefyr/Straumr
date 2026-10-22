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
    eventsview/PriceWidget.qml \
    eventsview/harbour-straumr.json \
    rpm/harbour-straumr.spec \
    harbour-straumr.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

HEADERS += src/pricemodel.h

OTHER_FILES += README.md \
    rpm/harbour-straumr.spec \
    rpm/harbour-straumr.yaml

# Events View widget: install QML + JSON in single RPM
# Follows Admirality pattern: eventsview/ at root level (not qml/eventsview/)
# libsailfishapp auto-installs DISTFILES to /usr/share/harbour-straumr/ preserving path
# So eventsview/PriceWidget.qml -> /usr/share/harbour-straumr/eventsview/PriceWidget.qml
# We also install JSON to Lipstick's eventswidgets dir

eventsWidgetJson.files = eventsview/harbour-straumr.json
eventsWidgetJson.path = /usr/share/lipstick/eventswidgets

INSTALLS += eventsWidgetJson
