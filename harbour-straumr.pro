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
    eventsview/harbour-straumr.ts \
    rpm/harbour-straumr.spec \
    harbour-straumr.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

HEADERS += src/pricemodel.h

OTHER_FILES += README.md \
    rpm/harbour-straumr.spec \
    rpm/harbour-straumr.yaml

# Events View widget: install JSON to Lipstick's eventswidgets dir
# QML is installed by libsailfishapp via DISTFILES to /usr/share/harbour-straumr/eventsview/
eventsWidgetJson.files = eventsview/harbour-straumr.json
eventsWidgetJson.path = /usr/share/lipstick/eventswidgets

# Translation: compile .ts to .qm and install to /usr/share/translations/
# Settings → Events view shows the description only when qtTrId() resolves
# description_id. The catalog is /usr/share/translations/harbour-straumr_eng_en.qm.
EVENT_WIDGET_TS = $$PWD/eventsview/harbour-straumr.ts
EVENT_WIDGET_QM = $$OUT_PWD/harbour-straumr_eng_en.qm
eventswidget_qm.target = $$EVENT_WIDGET_QM
eventswidget_qm.depends = $$EVENT_WIDGET_TS
eventswidget_qm.commands = $$[QT_INSTALL_BINS]/lrelease -idbased $$EVENT_WIDGET_TS -qm $$EVENT_WIDGET_QM
QMAKE_EXTRA_TARGETS += eventswidget_qm
PRE_TARGETDEPS += $$EVENT_WIDGET_QM

eventsWidgetQm.files = $$EVENT_WIDGET_QM
eventsWidgetQm.path = /usr/share/translations
eventsWidgetQm.CONFIG += no_check_exist

INSTALLS += eventsWidgetJson eventsWidgetQm
