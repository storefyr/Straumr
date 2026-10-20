var PRICE_AREA = "DK2"
var API_URL = "https://api.energidataservice.dk/dataset/DayAheadPrices"
var PRICELIST_URL = "https://api.energidataservice.dk/dataset/DatahubPricelist"
var VAT_RATE = 0.25

var GRID_GLN = "5790000705689"
var GRID_NAME = "Radius Elnet"
var ENERGINET_GLN = "5790000432752"

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
        callback(new Error("XMLHttpRequest ikke tilgængelig"), null)
        return
    }

    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE)
            return

        if (xhr.status === 0) {
            console.error("[Straumr] Ingen forbindelse (status 0) — tjek Internet-permission og netværk")
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
        console.error("[Straumr] Netværksfejl (onerror) — DNS, TLS eller forbindelse")
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

function fetchTariffs(callback) {
    var tariffs = {
        systemtarif: null,
        transmission: null,
        elafgift: null,
        nettarifC: null,
        loaded: 0,
        total: 4
    }

    function done() {
        tariffs.loaded++
        if (tariffs.loaded === tariffs.total) {
            console.log("[Straumr] Tariffer: system=" + tariffs.systemtarif +
                        " transmission=" + tariffs.transmission +
                        " elafgift=" + tariffs.elafgift +
                        " nettarifC=" + (tariffs.nettarifC ? "ja" : "nej"))
            callback(null, tariffs)
        }
    }

    var now = new Date()

    httpGet(buildTariffUrl(ENERGINET_GLN, "Systemtarif"), function(err, data) {
        if (!err && data.records) {
            var r = pickValidRecord(data.records, now)
            if (r) tariffs.systemtarif = r.Price1
        }
        done()
    })

    httpGet(buildTariffUrl(ENERGINET_GLN, "Transmissions nettarif"), function(err, data) {
        if (!err && data.records) {
            var r = pickValidRecord(data.records, now)
            if (r) tariffs.transmission = r.Price1
        }
        done()
    })

    httpGet(buildTariffUrl(ENERGINET_GLN, "Elafgift"), function(err, data) {
        if (!err && data.records) {
            var r = pickValidRecord(data.records, now)
            if (r) tariffs.elafgift = r.Price1
        }
        done()
    })

    httpGet(buildTariffUrl(GRID_GLN, "Nettarif C"), function(err, data) {
        if (!err && data.records) {
            var r = pickValidRecord(data.records, now)
            if (r) tariffs.nettarifC = r
        }
        done()
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
