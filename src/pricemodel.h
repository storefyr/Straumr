#ifndef PRICEMODEL_H
#define PRICEMODEL_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QTimer>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include <QDebug>

class PriceModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList prices READ prices NOTIFY pricesChanged)
    Q_PROPERTY(QVariantList todayPrices READ todayPrices NOTIFY pricesChanged)
    Q_PROPERTY(QVariantList tomorrowPrices READ tomorrowPrices NOTIFY pricesChanged)
    Q_PROPERTY(QVariantMap tariffs READ tariffs NOTIFY tariffsChanged)
    Q_PROPERTY(QVariantMap currentPrice READ currentPrice NOTIFY currentPriceChanged)
    Q_PROPERTY(qreal currentTotalKwh READ currentTotalKwh NOTIFY currentTotalKwhChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(bool hasError READ hasError NOTIFY hasErrorChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(QString gridName READ gridName CONSTANT)
    Q_PROPERTY(QString priceArea READ priceArea CONSTANT)

public:
    explicit PriceModel(QObject *parent = nullptr);

    QVariantList prices() const { return m_prices; }
    QVariantList todayPrices() const;
    QVariantList tomorrowPrices() const;
    QVariantMap tariffs() const { return m_tariffs; }
    QVariantMap currentPrice() const { return m_currentPrice; }
    qreal currentTotalKwh() const { return m_currentTotalKwh; }
    bool loading() const { return m_loading; }
    bool hasError() const { return m_hasError; }
    QString errorMessage() const { return m_errorMessage; }
    QString gridName() const { return m_gridName; }
    QString priceArea() const { return m_priceArea; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE qreal totalForRecord(const QVariantMap &record) const;
    Q_INVOKABLE QString timeLabel(const QVariantMap &record) const;
    Q_INVOKABLE int hourOfRecord(const QVariantMap &record) const;

signals:
    void pricesChanged();
    void tariffsChanged();
    void currentPriceChanged();
    void currentTotalKwhChanged();
    void loadingChanged();
    void hasErrorChanged();
    void errorMessageChanged();
    void refreshed();

private slots:
    void onSpotReply();
    void onTariffReply(int index);

private:
    void setLoading(bool v);
    void setHasError(bool v);
    void setErrorMessage(const QString &v);
    void setPrices(const QVariantList &v);
    void setTariffs(const QVariantMap &v);
    void setCurrentPrice(const QVariantMap &v);
    void setCurrentTotalKwh(qreal v);
    void fetchTariffs();
    void finishTariffs();
    qreal getNettarifForHour(const QVariantMap &nettarifC, int hour) const;
    qreal calculateTotalPriceKwh(double spotDkkMwh, int hour) const;
    QString buildSpotUrl() const;
    QString buildTariffUrl(const QString &gln, const QString &note) const;
    QVariantMap pickValidRecord(const QJsonArray &records, const QDate &date) const;

    static constexpr const char *PRICE_AREA = "DK2";
    static constexpr const char *API_URL = "https://api.energidataservice.dk/dataset/DayAheadPrices";
    static constexpr const char *PRICELIST_URL = "https://api.energidataservice.dk/dataset/DatahubPricelist";
    static constexpr double VAT_RATE = 0.25;
    static constexpr const char *GRID_GLN = "5790000705689";
    static constexpr const char *GRID_NAME = "Radius Elnet";
    static constexpr const char *ENERGINET_GLN = "5790000432752";

    QVariantList m_prices;
    QVariantMap m_tariffs;
    QVariantMap m_currentPrice;
    qreal m_currentTotalKwh = 0.0;
    bool m_loading = true;
    bool m_hasError = false;
    QString m_errorMessage;
    QString m_gridName;
    QString m_priceArea;

    QNetworkAccessManager m_nam;
    QList<QNetworkReply*> m_tariffReplies;
    int m_tariffsDone = 0;
    QTimer m_autoRefresh;
};

#endif
