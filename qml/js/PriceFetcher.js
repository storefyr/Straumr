.pragma library

var PRICE_AREA = "DK2"
var API_URL = "https://api.energidataservice.dk/dataset/DayAheadPrices"
var CACHE_MAX_AGE_MS = 30 * 60 * 1000

var db = null

function openDb() {
    if (db !== null)
        return db
    db = LocalStorage.openDatabaseSync("Straumr", "1.0", "Straumr elpriser", 1000000)
    db.transaction(function(tx) {
        tx.executeSql("CREATE TABLE IF NOT EXISTS prices (" +
                      "timeDK TEXT PRIMARY KEY, " +
                      "priceDkkMwh REAL NOT NULL)")
        tx.executeSql("CREATE TABLE IF NOT EXISTS meta (" +
                      "key TEXT PRIMARY KEY, " +
                      "value TEXT NOT NULL)")
    })
    return db
}

function cachePrices(records) {
    var d = openDb()
    d.transaction(function(tx) {
        for (var i = 0; i < records.length; i++) {
            tx.executeSql("INSERT OR REPLACE INTO prices (timeDK, priceDkkMwh) VALUES (?, ?)",
                          [records[i].TimeDK, records[i].DayAheadPriceDKK])
        }
        tx.executeSql("INSERT OR REPLACE INTO meta (key, value) VALUES ('lastFetch', ?)",
                      [new Date().toISOString()])
    })
}

function getCachedLastFetch() {
    var d = openDb()
    var result = null
    d.transaction(function(tx) {
        var rs = tx.executeSql("SELECT value FROM meta WHERE key = 'lastFetch'")
        if (rs.rows.length > 0)
            result = rs.rows.item(0).value
    })
    return result
}

function getCachedPrices(fromTimeDK, toTimeDK) {
    var d = openDb()
    var prices = []
    d.transaction(function(tx) {
        var rs = tx.executeSql(
            "SELECT timeDK, priceDkkMwh FROM prices " +
            "WHERE timeDK >= ? AND timeDK < ? ORDER BY timeDK ASC",
            [fromTimeDK, toTimeDK])
        for (var i = 0; i < rs.rows.length; i++)
            prices.push(rs.rows.item(i))
    })
    return prices
}

function isCacheFresh() {
    var last = getCachedLastFetch()
    if (!last)
        return false
    var age = Date.now() - new Date(last).getTime()
    return age < CACHE_MAX_AGE_MS
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

function startOfDayISO(date) {
    var d = new Date(date)
    d.setHours(0, 0, 0, 0)
    return d.toISOString().slice(0, 19)
}

function endOfTomorrowISO(date) {
    var d = new Date(date)
    d.setDate(d.getDate() + 2)
    d.setHours(0, 0, 0, 0)
    return d.toISOString().slice(0, 19)
}

function fetch(callback) {
    var now = new Date()
    var url = API_URL +
        "?filter=" + encodeURIComponent(JSON.stringify({"PriceArea": [PRICE_AREA]})) +
        "&start=" + encodeURIComponent(startOfDayISO(now)) +
        "&end=" + encodeURIComponent(endOfTomorrowISO(now)) +
        "&sort=" + encodeURIComponent("TimeUTC asc") +
        "&limit=200" +
        "&columns=" + encodeURIComponent("TimeUTC,TimeDK,PriceArea,DayAheadPriceDKK")

    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE)
            return
        if (xhr.status === 200) {
            try {
                var data = JSON.parse(xhr.responseText)
                if (data.records && data.records.length > 0) {
                    cachePrices(data.records)
                    callback(null, data.records)
                    return
                }
            } catch (e) {
                callback(e, null)
                return
            }
            callback(new Error("Ingen priser i svaret"), null)
        } else {
            callback(new Error("HTTP " + xhr.status), null)
        }
    }
    xhr.open("GET", url, true)
    xhr.timeout = 15000
    xhr.ontimeout = function() { callback(new Error("Timeout"), null) }
    xhr.send()
}

function getCurrentPrice(callback) {
    var now = new Date()
    var nowISO = now.toISOString().slice(0, 16) + "00"

    var cached = getCachedPrices(startOfDayISO(now), endOfTomorrowISO(now))
    var current = null
    for (var i = 0; i < cached.length; i++) {
        if (cached[i].timeDK <= nowISO)
            current = cached[i]
        else
            break
    }

    if (current && isCacheFresh()) {
        callback(null, current)
        return
    }

    fetch(function(err, records) {
        if (err) {
            if (current) {
                callback(null, current)
            } else {
                callback(err, null)
            }
            return
        }
        var found = null
        for (var j = 0; j < records.length; j++) {
            if (records[j].TimeDK <= nowISO)
                found = records[j]
            else
                break
        }
        callback(null, found)
    })
}

function getTodayPrices(callback) {
    var now = new Date()
    var from = startOfDayISO(now)
    var to = endOfTomorrowISO(now)

    if (isCacheFresh()) {
        var cached = getCachedPrices(from, to)
        if (cached.length > 0) {
            callback(null, cached)
            return
        }
    }

    fetch(function(err, records) {
        if (err) {
            var cached = getCachedPrices(from, to)
            if (cached.length > 0)
                callback(null, cached)
            else
                callback(err, null)
            return
        }
        callback(null, records)
    })
}

function priceLevel(priceDkkMwh) {
    var kr = dkkPerKwh(priceDkkMwh)
    if (kr < 0.50) return 0
    if (kr < 1.00) return 1
    if (kr < 2.00) return 2
    return 3
}
