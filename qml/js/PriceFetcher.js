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
    return toLocalISO(d)
}

function endOfTomorrowISO(date) {
    var d = new Date(date)
    d.setDate(d.getDate() + 2)
    d.setHours(0, 0, 0, 0)
    return toLocalISO(d)
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
    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE)
            return
        if (xhr.status === 200) {
            try {
                var data = JSON.parse(xhr.responseText)
                if (data.records && data.records.length > 0) {
                    callback(null, data.records)
                    return
                }
                callback(new Error("Ingen priser i svaret"), null)
            } catch (e) {
                callback(e, null)
            }
        } else {
            callback(new Error("HTTP " + xhr.status), null)
        }
    }
    xhr.open("GET", buildUrl(), true)
    xhr.timeout = 15000
    xhr.ontimeout = function() { callback(new Error("Timeout"), null) }
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
