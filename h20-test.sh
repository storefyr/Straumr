#!/bin/sh
# H20 test: Kopier QML til Lipstick's mappe og opdater JSON + dconf
# Kør dette script på telefonen

set -e

echo "=== H20: Kopier QML til Lipstick's eventsview mappe ==="
echo ""

echo "--- 1. Kopier QML-filer ---"
devel-su cp /usr/share/harbour-straumr/qml/eventsview/PriceWidget.qml /usr/share/lipstick-jolla-home-qt5/eventsview/
devel-su cp /usr/share/harbour-straumr/qml/eventsview/PriceWidgetContent.qml /usr/share/lipstick-jolla-home-qt5/eventsview/
echo "QML kopieret"
echo ""

echo "--- 2. Opret ny JSON med Lipstick-sti ---"
devel-su tee /usr/share/lipstick/eventswidgets/harbour-straumr.json > /dev/null << 'EOF'
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
EOF
echo "JSON opdateret"
echo ""

echo "--- 3. Opdater dconf ---"
dconf write /desktop/lipstick-jolla-home/events_screen_widgets "['/usr/share/lipstick-jolla-home-qt5/eventsview/calendar/CalendarWidgetLoader.qml', '/usr/share/lipstick-jolla-home-qt5/eventsview/PriceWidget.qml']"
echo "dconf opdateret"
echo ""

echo "--- 4. Genstart Lipstick ---"
systemctl --user restart lipstick
echo "Lipstick genstartet"
echo ""

echo "=== Færdig! ==="
echo "Stryg til venstre — vises Straumr widget nu?"
