#!/bin/sh
# H20 test part 2: Opret ny JSON med Lipstick-sti og opdater dconf
# QML-filer er allerede kopieret
# Kør dette script på telefonen

echo "=== H20 del 2: Opdater JSON + dconf ==="
echo ""

echo "--- Opret backup af gammel JSON ---"
devel-su cp /usr/share/lipstick/eventswidgets/harbour-straumr.json /usr/share/lipstick/eventswidgets/harbour-straumr.json.bak
echo ""

echo "--- Opret ny JSON ---"
devel-su sh -c 'cat > /usr/share/lipstick/eventswidgets/harbour-straumr.json << "JSONEOF"
{
    "widgets": [
        {
            "title": "Straumr",
            "icon": "/usr/share/icons/hicolor/86x86/apps/harbour-straumr.png",
            "order": 3,
            "path": "/usr/share/lipstick-jolla-home-qt5/eventsview/PriceWidget.qml",
            "available_path": "/usr/share/lipstick-jolla-home-qt5/eventsview/PriceWidget.qml",
            "default_enabled": true
        }
    ]
}
JSONEOF'
echo "JSON oprettet"
echo ""

echo "--- Verificer JSON ---"
cat /usr/share/lipstick/eventswidgets/harbour-straumr.json
echo ""

echo "--- Opdater dconf ---"
dconf write /desktop/lipstick-jolla-home/events_screen_widgets "['/usr/share/lipstick-jolla-home-qt5/eventsview/calendar/CalendarWidgetLoader.qml', '/usr/share/lipstick-jolla-home-qt5/eventsview/PriceWidget.qml']"
echo "dconf opdateret"
echo ""

echo "--- Genstart Lipstick ---"
systemctl --user restart lipstick
echo "Lipstick genstartet"
echo ""

echo "=== Færdig! ==="
echo "Stryg til venstre — vises Straumr widget nu?"
