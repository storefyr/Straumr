#!/bin/sh
# Straumr Widget Debug Script — kør på Sailfish OS telefonen
# Tjekker alt hvad der kan gå galt med Events View widgetten
#
# Brug:
#   curl -LO https://raw.githubusercontent.com/storefyr/Straumr/main/debug-widget.sh && sh debug-widget.sh

TAG="[Straumr-Debug]"

echo ""
echo "========================================"
echo "  Straumr Widget Debug Script"
echo "========================================"
echo ""

echo "$TAG === 1. Tjekker om RPM er installeret ==="
pkcon list 2>/dev/null | grep straumr || echo "  FEJL: Straumr ikke installeret!"
echo ""

echo "$TAG === 2. Tjekker om JSON-deskriptor findes ==="
JSON_PATH="/usr/share/lipstick/eventswidgets/harbour-straumr.json"
if [ -f "$JSON_PATH" ]; then
    echo "  OK: $JSON_PATH findes"
    echo "  Indhold:"
    cat "$JSON_PATH" | sed 's/^/    /'
else
    echo "  FEJL: $JSON_PATH findes IKKE!"
fi
echo ""

echo "$TAG === 3. Tjekker om widget QML findes ==="
QML_PATH="/usr/share/harbour-straumr/eventsview/PriceWidget.qml"
if [ -f "$QML_PATH" ]; then
    echo "  OK: $QML_PATH findes ($(wc -c < "$QML_PATH") bytes)"
else
    echo "  FEJL: $QML_PATH findes IKKE!"
    echo "  Tjekker gamle stier..."
    ls -la /usr/share/harbour-straumr/qml/eventsview/ 2>/dev/null || echo "    (qml/eventsview/ findes heller ikke)"
fi
echo ""

echo "$TAG === 4. Tjekker alle Straumr-filer ==="
echo "  /usr/share/harbour-straumr/:"
ls -la /usr/share/harbour-straumr/ 2>/dev/null | sed 's/^/    /' || echo "    (mappen findes ikke)"
echo "  /usr/share/harbour-straumr/eventsview/:"
ls -la /usr/share/harbour-straumr/eventsview/ 2>/dev/null | sed 's/^/    /' || echo "    (mappen findes ikke)"
echo "  /usr/share/lipstick/eventswidgets/:"
ls -la /usr/share/lipstick/eventswidgets/ 2>/dev/null | sed 's/^/    /' || echo "    (mappen findes ikke)"
echo ""

echo "$TAG === 5. Tjekker dconf widget-indstillinger ==="
echo "  Nuværende værdi af events_screen_widgets:"
dconf read /desktop/lipstick-jolla-home/events_screen_widgets 2>/dev/null | sed 's/^/    /' || echo "    (kunne ikke læse dconf)"
echo ""
echo "  Tjekker om Straumr er i listen..."
DCONF_VAL=$(dconf read /desktop/lipstick-jolla-home/events_screen_widgets 2>/dev/null)
if echo "$DCONF_VAL" | grep -q "straumr"; then
    echo "  OK: Straumr er i dconf-listen"
else
    echo "  ADVARSEL: Straumr IKKE i dconf-listen!"
    echo "  For at tilføje manuelt:"
    echo "    dconf write /desktop/lipstick-jolla-home/events_screen_widgets \"['/usr/share/harbour-straumr/eventsview/PriceWidget.qml']\""
fi
echo ""

echo "$TAG === 6. Tjekker om gammel widget-RPM er installeret ==="
if pkcon list 2>/dev/null | grep -q "harbour-straumr-widget"; then
    echo "  ADVARSEL: Gammel harbour-straumr-widget er stadig installeret!"
    echo "  Fjern den med: pkcon remove harbour-straumr-widget"
else
    echo "  OK: Ingen gammel widget-RPM"
fi
echo ""

echo "$TAG === 7. Tjekker om JSON er valid ==="
if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json; json.load(open('$JSON_PATH')); print('  OK: JSON er valid')" 2>&1 || echo "  FEJL: JSON er ugyldig!"
else
    echo "  (python3 ikke tilgængelig — springer over)"
fi
echo ""

echo "$TAG === 8. Seneste Straumr logs fra journalctl ==="
echo "  Kører: journalctl --no-pager -n 30 | grep -i straumr"
echo "  ---"
journalctl --no-pager -n 30 2>/dev/null | grep -i "straumr" | tail -20 | sed 's/^/    /'
echo "  ---"
echo ""

echo "$TAG === 9. Seneste lipstick logs (widget-relateret) ==="
echo "  Kører: journalctl --no-pager -n 30 -u lipstick | grep -iE 'widget|eventsview|error|fail'"
echo "  ---"
journalctl --no-pager -n 30 -u lipstick 2>/dev/null | grep -iE "widget|eventsview|error|fail" | tail -20 | sed 's/^/    /'
echo "  ---"
echo ""

echo "$TAG === 10. Lipstick proces status ==="
ps aux 2>/dev/null | grep -i lipstick | grep -v grep | sed 's/^/    /' || echo "  (lipstick ikke fundet i ps)"
echo ""

echo "$TAG === 11. Netværkstest fra telefonen ==="
echo "  Tester forbindelse til Energinet API..."
curl -s -o /dev/null -w "  HTTP status: %{http_code}, tid: %{time_total}s\n" \
    "https://api.energidataservice.dk/dataset/DayAheadPrices?filter=%7B%22PriceArea%22%3A%5B%22DK2%22%5D%7D&start=$(date +%Y-%m-%d)&end=$(date -d tomorrow +%Y-%m-%d 2>/dev/null || date -v+1d +%Y-%m-%d)&sort=TimeUTC%20asc&limit=5" 2>&1 || echo "  FEJL: Kunne ikke nå API'et"
echo ""

echo "========================================"
echo "  Debug færdig!"
echo "========================================"
echo ""
echo "  Næste skridt:"
echo "  1. Kør: journalctl -f | grep '\[Straumr-Widget\]'"
echo "  2. Stryg til venstre (Events View)"
echo "  3. Se hvad der logges"
echo "  4. Del outputtet med mig"
echo ""
echo "  Hvis JSON mangler, kør:"
echo "    devel-su"
echo "    cp /usr/share/harbour-straumr/eventsview/PriceWidget.qml /tmp/test.qml  # tjek sti"
echo ""
