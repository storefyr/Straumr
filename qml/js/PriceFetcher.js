var PRICE_AREA = "DK2"
var API_URL = "https://api.energidataservice.dk/dataset/DayAheadPrices"

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

function fetch(callback) {
    var url = buildUrl()
    console.log("[Straumr] fetch URL:", url)

    if (typeof XMLHttpRequest === "undefined") {
        console.error("[Straumr] XMLHttpRequest er ikke defineret!")
        callback(new Error("XMLHttpRequest ikke tilgængelig"), null)
        return
    }

    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE)
            return
        console.log("[Straumr] HTTP status:", xhr.status, xhr.statusText)

        if (xhr.status === 0) {
            console.error("[Straumr] Ingen forbindelse (status 0) — tjek Internet-permission og netværk")
            callback(new Error("Ingen netforbindelse"), null)
            return
        }

        if (xhr.status === 200) {
            try {
                var data = JSON.parse(xhr.responseText)
                var count = data.records ? data.records.length : 0
                console.log("[Straumr] Modtog", count, "records")
                if (count > 0) {
                    callback(null, data.records)
                    return
                }
                console.warn("[Straumr] Svar uden records")
                callback(new Error("Ingen priser i svaret"), null)
            } catch (e) {
                console.error("[Straumr] JSON parse fejl:", e.message)
                console.error("[Straumr] Response (500 tegn):", xhr.responseText.substring(0, 500))
                callback(new Error("Ugyldigt svar fra server"), null)
            }
        } else {
            console.error("[Straumr] HTTP fejl:", xhr.status, xhr.statusText)
            console.error("[Straumr] Response (500 tegn):",
                          xhr.responseText ? xhr.responseText.substring(0, 500) : "(tom)")
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
