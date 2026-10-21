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
    rpm/harbour-straumr.spec \
    harbour-straumr.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

HEADERS += src/pricemodel.h

OTHER_FILES += README.md \
    rpm/harbour-straumr.spec \
    rpm/harbour-straumr.yaml \
    widget/eventswidgets/harbour-straumr.json \
    widget/qml/eventsview/PriceWidget.qml \
    widget/qml/eventsview/PriceWidgetContent.qml \
    widget/icons/harbour-straumr.png \
    widget/rpm/harbour-straumr-widget.spec \
    widget/rpm/harbour-straumr-widget.yaml
