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
    widget/eventswidgets/harbour-straumr.json \
    rpm/harbour-straumr.spec \
    harbour-straumr.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

HEADERS += src/pricemodel.h

OTHER_FILES += README.md \
    rpm/harbour-straumr.spec \
    rpm/harbour-straumr.yaml

# Events View widget: install QML + JSON in single RPM
# Follows Admirality pattern exactly: QML to /usr/share/harbour-straumr/eventsview/
# (NOT qml/eventsview/ — Admirality puts widget QML directly in eventsview/)
eventsWidgetQml.files = qml/eventsview/PriceWidget.qml
eventsWidgetQml.path = /usr/share/harbour-straumr/eventsview

eventsWidgetJson.files = widget/eventswidgets/harbour-straumr.json
eventsWidgetJson.path = /usr/share/lipstick/eventswidgets

INSTALLS += eventsWidgetQml eventsWidgetJson
