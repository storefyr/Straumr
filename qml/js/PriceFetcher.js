var PRICE_AREA = "DK2"
var API_URL = "https://api.energidataservice.dk/dataset/DayAheadPrices"
var PRICELIST_URL = "https://api.energidataservice.dk/dataset/DatahubPricelist"
var VAT_RATE = 0.25

var GRID_GLN = "5790000705689"
var GRID_NAME = "Radius Elnet"
var ENERGINET_GLN = "5790000432752"

var FALLBACK_NETTARIF_C = {
    ValidFrom: "2026-10-01T00:00:00",
    ValidTo: "2027-04-01T00:00:00",
    Price1: 0.106175, Price2: 0.106175, Price3: 0.106175,
    Price4: 0.106175, Price5: 0.106175, Price6: 0.106175,
    Price7: 0.318524, Price8: 0.318524, Price9: 0.318524,
    Price10: 0.318524, Price11: 0.318524, Price12: 0.318524,
    Price13: 0.318524, Price14: 0.318524, Price15: 0.318524,
    Price16: 0.318524, Price17: 0.318524,
    Price18: 0.955573, Price19: 0.955573, Price20: 0.955573, Price21: 0.955573,
    Price22: 0.318524, Price23: 0.318524, Price24: 0.318524
}

function pad(n) {
    return n < 10 ? "0" + n : "" + n
}

function toLocalISO(date) {
    var d = new Date(date)
    return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) +
           "T" + pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
}

function startOfDayISO(date) {
    var d = new Date(date)
    d.setHours(0, 0, 0, 0)
    return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
}

function endOfTomorrowISO(date) {
    var d = new Date(date)
    d.setDate(d.getDate() + 2)
    d.setHours(0, 0, 0, 0)
    return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
}

function buildUrl() {
    var now = new Date()
    return API_URL +
        "?filter=" + encodeURIComponent(JSON.stringify({"PriceArea": [PRICE_AREA]})) +
        "&start=" + encodeURIComponent(startOfDayISO(now)) +
        "&end=" + encodeURIComponent(endOfTomorrowISO(now)) +
        "&sort=" + encodeURIComponent("TimeUTC asc") +
        "&limit=200" +
        "&columns=" + encodeURIComponent("TimeUTC,TimeDK,PriceArea,DayAheadPriceDKK")
}

function httpGet(url, callback) {
    if (typeof XMLHttpRequest === "undefined") {
        console.error("[Straumr] XMLHttpRequest er ikke defineret!")
        callback(new Error("XMLHttpRequest ikke tilgaengelig"), null)
        return
    }

    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE)
            return

        if (xhr.status === 0) {
            console.error("[Straumr] Ingen forbindelse (status 0) - tjek Internet-permission og netvaerk")
            callback(new Error("Ingen netforbindelse"), null)
            return
        }

        if (xhr.status === 200) {
            try {
                callback(null, JSON.parse(xhr.responseText))
            } catch (e) {
                console.error("[Straumr] JSON parse fejl:", e.message)
                callback(new Error("Ugyldigt svar fra server"), null)
            }
        } else {
            console.error("[Straumr] HTTP fejl:", xhr.status, xhr.statusText)
            callback(new Error("HTTP " + xhr.status), null)
        }
    }
    xhr.open("GET", url, true)
    xhr.timeout = 15000
    xhr.ontimeout = function() {
        console.error("[Straumr] Timeout efter 15 sekunder")
        callback(new Error("Timeout (15s)"), null)
    }
    xhr.onerror = function() {
        console.error("[Straumr] Netvaerksfejl (onerror) - DNS, TLS eller forbindelse")
        callback(new Error("Netvaerksfejl"), null)
    }
    xhr.send()
}

function fetch(callback) {
    var url = buildUrl()
    console.log("[Straumr] fetch URL:", url)
    httpGet(url, function(err, data) {
        if (err) {
            callback(err, null)
            return
        }
        var count = data.records ? data.records.length : 0
        console.log("[Straumr] Modtog", count, "pris-records")
        if (count > 0) {
            callback(null, data.records)
        } else {
            console.warn("[Straumr] Svar uden records")
            callback(new Error("Ingen priser i svaret"), null)
        }
    })
}

function buildTariffUrl(gln, note) {
    var filter = {"GLN_Number": gln, "Note": note}
    return PRICELIST_URL +
        "?filter=" + encodeURIComponent(JSON.stringify(filter)) +
        "&sort=" + encodeURIComponent("ValidFrom desc") +
        "&limit=10"
}

function pickValidRecord(records, date) {
    if (!records || records.length === 0)
        return null
    var target = toLocalISO(date).slice(0, 10)
    for (var i = 0; i < records.length; i++) {
        var from = records[i].ValidFrom ? records[i].ValidFrom.slice(0, 10) : "0000-00-00"
        var to = records[i].ValidTo ? records[i].ValidTo.slice(0, 10) : "9999-99-99"
        if (target >= from && target < to)
            return records[i]
    }
    return records[0]
}

function fetchTariffSequential(tariffName, gln, note, now, cb) {
    var url = buildTariffUrl(gln, note)
    console.log("[Straumr] Henter tarif '" + tariffName + "' fra " + gln + " (" + note + ")")
    httpGet(url, function(err, data) {
        if (err) {
            console.error("[Straumr] Tarif '" + tariffName + "' fejlede: " + err.message)
            cb(null)
            return
        }
        var count = data.records ? data.records.length : 0
        console.log("[Straumr] Tarif '" + tariffName + "': " + count + " records")
        if (count > 0) {
            var r = pickValidRecord(data.records, now)
            if (r) {
                if (note === "Nettarif C") {
                    console.log("[Straumr] Nettarif C: ValidFrom=" + r.ValidFrom +
                                " ValidTo=" + r.ValidTo +
                                " Price1=" + r.Price1 +
                                " Price12=" + r.Price12 +
                                " Price18=" + r.Price18)
                } else {
                    console.log("[Straumr] " + tariffName + ": ValidFrom=" + r.ValidFrom +
                                " Price1=" + r.Price1)
                }
                cb(r)
            } else {
                console.warn("[Straumr] Tarif '" + tariffName + "': pickValidRecord returnerede null")
                cb(null)
            }
        } else {
            console.warn("[Straumr] Tarif '" + tariffName + "': ingen records i svaret")
            cb(null)
        }
    })
}

function fetchTariffs(callback) {
    var tariffs = {
        systemtarif: null,
        transmission: null,
        elafgift: null,
        nettarifC: null
    }
    var now = new Date()

    fetchTariffSequential("Systemtarif", ENERGINET_GLN, "Systemtarif", now, function(r1) {
        if (r1) tariffs.systemtarif = r1.Price1

        fetchTariffSequential("Transmissions nettarif", ENERGINET_GLN, "Transmissions nettarif", now, function(r2) {
            if (r2) tariffs.transmission = r2.Price1

            fetchTariffSequential("Elafgift", ENERGINET_GLN, "Elafgift", now, function(r3) {
                if (r3) tariffs.elafgift = r3.Price1

                fetchTariffSequential("Nettarif C", GRID_GLN, "Nettarif C", now, function(r4) {
                    if (r4) {
                        tariffs.nettarifC = r4
                    } else {
                        console.warn("[Straumr] Nettarif C kunne ikke hentes - bruger fallback vaerdier (Radius vinter 2026)")
                        tariffs.nettarifC = FALLBACK_NETTARIF_C
                    }

                    console.log("[Straumr] Tariffer klar: system=" + tariffs.systemtarif +
                                " transmission=" + tariffs.transmission +
                                " elafgift=" + tariffs.elafgift +
                                " nettarifC=" + (tariffs.nettarifC ? "ja (P1=" + tariffs.nettarifC.Price1 + ")" : "nej"))
                    callback(null, tariffs)
                })
            })
        })
    })
}

function fetchAll(callback) {
    fetch(function(err, prices) {
        if (err) {
            callback(err, null, null)
            return
        }
        fetchTariffs(function(terr, tariffs) {
            if (terr) {
                console.warn("[Straumr] Kunne ikke hente tariffer:", terr.message)
            }
            callback(null, prices, tariffs)
        })
    })
}

function getNettarifForHour(nettarifC, hour) {
    if (!nettarifC)
        return 0
    var priceKey = "Price" + (hour + 1)
    var price = nettarifC[priceKey]
    if (price === null || price === undefined)
        return 0
    return price
}

function calculateTotalPriceKwh(spotDkkMwh, tariffs, hour) {
    var spot = spotDkkMwh / 1000.0
    var nettarif = tariffs && tariffs.nettarifC ? getNettarifForHour(tariffs.nettarifC, hour) : 0
    var system = tariffs && tariffs.systemtarif ? tariffs.systemtarif : 0
    var transmission = tariffs && tariffs.transmission ? tariffs.transmission : 0
    var elafgift = tariffs && tariffs.elafgift ? tariffs.elafgift : 0

    var exclVat = spot + nettarif + system + transmission + elafgift
    return exclVat * (1 + VAT_RATE)
}

function calculateTotalOre(spotDkkMwh, tariffs, hour) {
    return Math.round(calculateTotalPriceKwh(spotDkkMwh, tariffs, hour) * 100)
}

function formatTotalKr(totalKwh) {
    return totalKwh.toFixed(2).replace(".", ",")
}

function findCurrentPrice(records, now) {
    if (!records || records.length === 0)
        return null
    var nowISO = toLocalISO(now).slice(0, 16) + "00"
    var current = null
    for (var i = 0; i < records.length; i++) {
        if (records[i].TimeDK <= nowISO)
            current = records[i]
        else
            break
    }
    return current
}

function dkkPerKwh(priceDkkMwh) {
    return priceDkkMwh / 1000.0
}

function formatOre(priceDkkMwh) {
    return Math.round(dkkPerKwh(priceDkkMwh) * 100).toString()
}

function formatKr(priceDkkMwh) {
    return dkkPerKwh(priceDkkMwh).toFixed(2).replace(".", ",")
}

function priceLevel(priceDkkMwh) {
    var kr = dkkPerKwh(priceDkkMwh)
    if (kr < 0.50) return 0
    if (kr < 1.00) return 1
    if (kr < 2.00) return 2
    return 3
}

function totalPriceLevel(totalKwh) {
    if (totalKwh < 1.00) return 0
    if (totalKwh < 2.00) return 1
    if (totalKwh < 3.00) return 2
    return 3
}
