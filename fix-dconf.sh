#!/bin/sh
# Straumr — rydder op i dconf og genstarter lipstick
# Kør på Sailfish OS telefonen efter installation af v1.9.2
#
# Brug:
#   curl -LO https://raw.githubusercontent.com/storefyr/Straumr/main/fix-dconf.sh && sh fix-dconf.sh

TAG="[Straumr-Fix]"

echo ""
echo "  === Straumr dconf oprydning ==="
echo ""

echo "$TAG Nuværende dconf værdi:"
OLD_VAL=$(dconf read /desktop/lipstick-jolla-home/events_screen_widgets 2>/dev/null)
echo "  $OLD_VAL"
echo ""

# Den korrekte værdi — kun system widgets + Straumr
NEW_VAL="['/usr/share/lipstick-jolla-home-qt5/eventsview/weather/WeatherLoader.qml', '/usr/share/lipstick-jolla-home-qt5/eventsview/calendar/CalendarWidgetLoader.qml', '/usr/share/harbour-straumr/eventsview/PriceWidget.qml']"

echo "$TAG Sætter ny dconf værdi (kun system widgets + Straumr):"
echo "  $NEW_VAL"
echo ""

dconf write /desktop/lipstick-jolla-home/events_screen_widgets "$NEW_VAL"

echo "$TAG Verificerer:"
VERIFY=$(dconf read /desktop/lipstick-jolla-home/events_screen_widgets 2>/dev/null)
echo "  $VERIFY"
echo ""

# Tjek at filerne findes
echo "$TAG Tjekker at widget-filer findes:"
if [ -f /usr/share/harbour-straumr/eventsview/PriceWidget.qml ]; then
    echo "  OK: /usr/share/harbour-straumr/eventsview/PriceWidget.qml"
else
    echo "  FEJL: /usr/share/harbour-straumr/eventsview/PriceWidget.qml findes IKKE!"
fi
if [ -f /usr/share/lipstick/eventswidgets/harbour-straumr.json ]; then
    echo "  OK: /usr/share/lipstick/eventswidgets/harbour-straumr.json"
else
    echo "  FEJL: /usr/share/lipstick/eventswidgets/harbour-straumr.json findes IKKE!"
fi
echo ""

# Fjern gammel QML hvis den findes (fra tidligere versioner)
if [ -f /usr/share/harbour-straumr/qml/eventsview/PriceWidget.qml ]; then
    echo "$TAG ADVARSEL: Gammel QML fundet — fjerner:"
    echo "  /usr/share/harbour-straumr/qml/eventsview/PriceWidget.qml"
    devel-su rm -f /usr/share/harbour-straumr/qml/eventsview/PriceWidget.qml
    devel-su rmdir /usr/share/harbour-straumr/qml/eventsview 2>/dev/null || true
else
    echo "$TAG OK: Ingen gammel QML i qml/eventsview/"
fi
echo ""

# Fjern stray fil fra tidligere tests
if [ -f /usr/share/lipstick-jolla-home-qt5/eventsview/PriceWidget.qml ]; then
    echo "$TAG ADVARSEL: Stray fil fundet — fjerner:"
    echo "  /usr/share/lipstick-jolla-home-qt5/eventsview/PriceWidget.qml"
    devel-su rm -f /usr/share/lipstick-jolla-home-qt5/eventsview/PriceWidget.qml
else
    echo "$TAG OK: Ingen stray fil i lipstick-jolla-home"
fi
echo ""

echo "$TAG Genstarter lipstick..."
systemctl --user restart lipstick 2>/dev/null || {
    echo "  ADVARSEL: Kunne ikke genstarte lipstick."
    echo "  Kør selv: systemctl --user restart lipstick"
}
echo ""

echo "  ╔═══════════════════════════════════════╗"
echo "  ║  ✅ dconf ryddet og lipstick genstartet! ║"
echo "  ╚═══════════════════════════════════════╝"
echo ""
echo "  Næste skridt:"
echo "  1. Gå til: Indstillinger → Begivenhedsvisning"
echo "  2. Tjek at 'Straumr' vises i listen"
echo "  3. Slå Straumr til hvis ikke allerede gjort"
echo "  4. Stryg til venstre — se widgetten! ⚡"
echo ""
echo "  Se logs: devel-su journalctl -f | grep Straumr"
echo ""
