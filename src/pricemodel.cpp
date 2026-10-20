#include "pricemodel.h"

static QString pad(int n) {
    return QStringLiteral("%1").arg(n, 2, 10, QChar('0'));
}

static QString startOfDayISO(const QDate &date) {
    return date.toString(QStringLiteral("yyyy-MM-dd"));
}

static QString endOfTomorrowISO(const QDate &date) {
    return date.addDays(2).toString(QStringLiteral("yyyy-MM-dd"));
}

PriceModel::PriceModel(QObject *parent)
    : QObject(parent)
    , m_gridName(QStringLiteral(GRID_NAME))
    , m_priceArea(QStringLiteral(PRICE_AREA))
{
    m_autoRefresh.setInterval(15 * 60 * 1000);
    m_autoRefresh.setSingleShot(false);
    connect(&m_autoRefresh, &QTimer::timeout, this, &PriceModel::refresh);
    m_autoRefresh.start();

    QTimer::singleShot(0, this, &PriceModel::refresh);
}

QString PriceModel::gridName() const { return m_gridName; }
QString PriceModel::priceArea() const { return m_priceArea; }

void PriceModel::setLoading(bool v) { if (m_loading != v) { m_loading = v; emit loadingChanged(); } }
void PriceModel::setHasError(bool v) { if (m_hasError != v) { m_hasError = v; emit hasErrorChanged(); } }
void PriceModel::setErrorMessage(const QString &v) { if (m_errorMessage != v) { m_errorMessage = v; emit errorMessageChanged(); } }
void PriceModel::setPrices(const QVariantList &v) { m_prices = v; emit pricesChanged(); }
void PriceModel::setTariffs(const QVariantMap &v) { m_tariffs = v; emit tariffsChanged(); }
void PriceModel::setCurrentPrice(const QVariantMap &v) { m_currentPrice = v; emit currentPriceChanged(); }
void PriceModel::setCurrentTotalKwh(qreal v) { if (!qFuzzyCompare(m_currentTotalKwh, v)) { m_currentTotalKwh = v; emit currentTotalKwhChanged(); } }

QString PriceModel::buildSpotUrl() const {
    QDate today = QDate::currentDate();
    QJsonObject filter;
    filter[QStringLiteral("PriceArea")] = QJsonArray{QStringLiteral(PRICE_AREA)};
    QString url = QStringLiteral(API_URL);
    url += QStringLiteral("?filter=") + QString::fromUtf8(QUrl::toPercentEncoding(QString::fromUtf8(QJsonDocument(filter).toJson(QJsonDocument::Compact))));
    url += QStringLiteral("&start=") + QString::fromUtf8(QUrl::toPercentEncoding(startOfDayISO(today)));
    url += QStringLiteral("&end=") + QString::fromUtf8(QUrl::toPercentEncoding(endOfTomorrowISO(today)));
    url += QStringLiteral("&sort=") + QString::fromUtf8(QUrl::toPercentEncoding(QStringLiteral("TimeUTC asc")));
    url += QStringLiteral("&limit=200");
    url += QStringLiteral("&columns=") + QString::fromUtf8(QUrl::toPercentEncoding(QStringLiteral("TimeUTC,TimeDK,PriceArea,DayAheadPriceDKK")));
    return url;
}

QString PriceModel::buildTariffUrl(const QString &gln, const QString &note) const {
    QJsonObject filter;
    filter[QStringLiteral("GLN_Number")] = gln;
    filter[QStringLiteral("Note")] = note;
    QString url = QStringLiteral(PRICELIST_URL);
    url += QStringLiteral("?filter=") + QString::fromUtf8(QUrl::toPercentEncoding(QString::fromUtf8(QJsonDocument(filter).toJson(QJsonDocument::Compact))));
    url += QStringLiteral("&sort=") + QString::fromUtf8(QUrl::toPercentEncoding(QStringLiteral("ValidFrom desc")));
    url += QStringLiteral("&limit=10");
    return url;
}

QVariantMap PriceModel::pickValidRecord(const QJsonArray &records, const QDate &date) const {
    if (records.isEmpty())
        return QVariantMap();
    QString target = date.toString(QStringLiteral("yyyy-MM-dd"));
    for (const auto &val : records) {
        QJsonObject obj = val.toObject();
        QString from = obj[QStringLiteral("ValidFrom")].toString().left(10);
        QString to = obj[QStringLiteral("ValidTo")].toString().left(10);
        if (from.isEmpty()) from = QStringLiteral("0000-00-00");
        if (to.isEmpty()) to = QStringLiteral("9999-99-99");
        if (target >= from && target < to)
            return obj.toVariantMap();
    }
    return records.first().toObject().toVariantMap();
}

qreal PriceModel::getNettarifForHour(const QVariantMap &nettarifC, int hour) const {
    if (nettarifC.isEmpty())
        return 0.0;
    QString key = QStringLiteral("Price%1").arg(hour + 1);
    return nettarifC.value(key).toDouble();
}

qreal PriceModel::calculateTotalPriceKwh(double spotDkkMwh, int hour) const {
    double spot = spotDkkMwh / 1000.0;
    double nettarif = getNettarifForHour(m_tariffs.value(QStringLiteral("nettarifC")).toMap(), hour);
    double system = m_tariffs.value(QStringLiteral("systemtarif")).toDouble();
    double transmission = m_tariffs.value(QStringLiteral("transmission")).toDouble();
    double elafgift = m_tariffs.value(QStringLiteral("elafgift")).toDouble();
    double exclVat = spot + nettarif + system + transmission + elafgift;
    return exclVat * (1.0 + VAT_RATE);
}

void PriceModel::refresh() {
    qDebug() << "[Straumr] PriceModel::refresh()";
    setLoading(true);
    setHasError(false);
    setErrorMessage(QString());

    QNetworkRequest req(QUrl(buildSpotUrl()));
    req.setRawHeader("Accept", "application/json");
    QNetworkReply *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, &PriceModel::onSpotReply);
}

void PriceModel::onSpotReply() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "[Straumr] Spot fetch fejl:" << reply->errorString();
        setLoading(false);
        setHasError(true);
        setErrorMessage(reply->errorString());
        setPrices(QVariantList());
        setTariffs(QVariantMap());
        setCurrentPrice(QVariantMap());
        setCurrentTotalKwh(0);
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    QJsonArray records = doc.object()[QStringLiteral("records")].toArray();
    qDebug() << "[Straumr] Modtog" << records.size() << "pris-records";

    if (records.isEmpty()) {
        setLoading(false);
        setHasError(true);
        setErrorMessage(QStringLiteral("Ingen priser i svaret"));
        return;
    }

    QVariantList priceList;
    for (const auto &val : records)
        priceList.append(val.toObject().toVariantMap());
    setPrices(priceList);

    fetchTariffs();
}

void PriceModel::fetchTariffs() {
    m_tariffReplies.clear();
    m_tariffsDone = 0;
    m_tariffs[QStringLiteral("systemtarif")] = QVariant();
    m_tariffs[QStringLiteral("transmission")] = QVariant();
    m_tariffs[QStringLiteral("elafgift")] = QVariant();
    m_tariffs[QStringLiteral("nettarifC")] = QVariant();

    struct TariffReq { const char *name; const char *gln; const char *note; };
    TariffReq reqs[] = {
        {"Systemtarif", ENERGINET_GLN, "Systemtarif"},
        {"Transmissions nettarif", ENERGINET_GLN, "Transmissions nettarif"},
        {"Elafgift", ENERGINET_GLN, "Elafgift"},
        {"Nettarif C", GRID_GLN, "Nettarif C"},
    };

    for (int i = 0; i < 4; i++) {
        QString url = buildTariffUrl(QStringLiteral(reqs[i].gln), QStringLiteral(reqs[i].note));
        qDebug() << "[Straumr] Henter tarif" << reqs[i].name << "fra" << reqs[i].gln;
        QNetworkRequest req(QUrl(url));
        req.setRawHeader("Accept", "application/json");
        QNetworkReply *reply = m_nam.get(req);
        reply->setProperty("tariffIndex", i);
        reply->setProperty("tariffName", QStringLiteral(reqs[i].name));
        connect(reply, &QNetworkReply::finished, this, [this, i]() { onTariffReply(i); });
        m_tariffReplies.append(reply);
    }
}

void PriceModel::onTariffReply(int index) {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    reply->deleteLater();

    QString name = reply->property("tariffName").toString();

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "[Straumr] Tarif" << name << "fejlede:" << reply->errorString();
    } else {
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray records = doc.object()[QStringLiteral("records")].toArray();
        qDebug() << "[Straumr] Tarif" << name << ":" << records.size() << "records";
        if (!records.isEmpty()) {
            QVariantMap r = pickValidRecord(records, QDate::currentDate());
            if (index == 0)
                m_tariffs[QStringLiteral("systemtarif")] = r.value(QStringLiteral("Price1"));
            else if (index == 1)
                m_tariffs[QStringLiteral("transmission")] = r.value(QStringLiteral("Price1"));
            else if (index == 2)
                m_tariffs[QStringLiteral("elafgift")] = r.value(QStringLiteral("Price1"));
            else if (index == 3)
                m_tariffs[QStringLiteral("nettarifC")] = r;
        }
    }

    m_tariffsDone++;
    if (m_tariffsDone == 4)
        finishTariffs();
}

void PriceModel::finishTariffs() {
    emit tariffsChanged();

    bool hasNettarifC = !m_tariffs.value(QStringLiteral("nettarifC")).toMap().isEmpty();
    qDebug() << "[Straumr] Tariffer klar: system=" << m_tariffs.value(QStringLiteral("systemtarif")).toDouble()
             << "transmission=" << m_tariffs.value(QStringLiteral("transmission")).toDouble()
             << "elafgift=" << m_tariffs.value(QStringLiteral("elafgift")).toDouble()
             << "nettarifC=" << (hasNettarifC ? "ja" : "nej");

    if (m_prices.isEmpty()) {
        setLoading(false);
        return;
    }

    QDateTime now = QDateTime::currentDateTime();
    QString nowISO = now.toString(QStringLiteral("yyyy-MM-ddTHH:mm")) + QStringLiteral(":00");

    QVariantMap current;
    for (const auto &v : m_prices) {
        QVariantMap rec = v.toMap();
        QString timeDK = rec.value(QStringLiteral("TimeDK")).toString();
        if (timeDK <= nowISO)
            current = rec;
        else
            break;
    }

    setCurrentPrice(current);
    if (!current.isEmpty()) {
        int hour = current.value(QStringLiteral("TimeDK")).toString().mid(11, 2).toInt();
        double spot = current.value(QStringLiteral("DayAheadPriceDKK")).toDouble();
        setCurrentTotalKwh(calculateTotalPriceKwh(spot, hour));
    } else {
        setCurrentTotalKwh(0);
    }

    setLoading(false);
    emit refreshed();
}

qreal PriceModel::totalForRecord(const QVariantMap &record) const {
    if (record.isEmpty())
        return 0.0;
    int hour = record.value(QStringLiteral("TimeDK")).toString().mid(11, 2).toInt();
    double spot = record.value(QStringLiteral("DayAheadPriceDKK")).toDouble();
    return calculateTotalPriceKwh(spot, hour);
}

QString PriceModel::timeLabel(const QVariantMap &record) const {
    if (record.isEmpty())
        return QString();
    return record.value(QStringLiteral("TimeDK")).toString().mid(11, 5);
}

int PriceModel::hourOfRecord(const QVariantMap &record) const {
    if (record.isEmpty())
        return 0;
    return record.value(QStringLiteral("TimeDK")).toString().mid(11, 2).toInt();
}
