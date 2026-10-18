
-- Lecture 5: Advanced SQL

-- 1. LAG(): daily currency rate changes
SELECT
    currency_code,
    rate_date,
    rate,
    ROUND(rate - LAG(rate) OVER (
        PARTITION BY currency_code ORDER BY rate_date
    ), 4) AS daily_change
FROM currency.rates
WHERE currency_code IN ('USD', 'EUR')
ORDER BY currency_code, rate_date;


-- 2. Three-record moving average for Tbilisi weather
SELECT
    forecast_time,
    temperature_c,
    ROUND(AVG(temperature_c) OVER (
        ORDER BY forecast_time
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3h
FROM weather.forecasts
WHERE city = 'Tbilisi'
ORDER BY forecast_time;


-- 3. CTE: USD changes greater than 0.002
WITH usd_changes AS (
    SELECT
        rate_date,
        rate,
        ROUND(rate - LAG(rate) OVER (ORDER BY rate_date), 4)
            AS daily_change
    FROM currency.rates
    WHERE currency_code = 'USD'
)
SELECT rate_date, rate, daily_change
FROM usd_changes
WHERE ABS(daily_change) > 0.002
ORDER BY rate_date;


-- 4. JOIN, GROUP BY and HAVING
SELECT
    c.name,
    COUNT(*) AS days_recorded,
    ROUND(AVG(r.rate), 4) AS avg_rate
FROM currency.rates AS r
JOIN currency.currencies AS c ON c.code = r.currency_code
GROUP BY c.name
HAVING COUNT(*) >= 5
ORDER BY avg_rate DESC;


-- 5. View: currency trends
CREATE OR REPLACE VIEW currency.v_usd_eur_trend AS
SELECT
    currency_code,
    rate_date,
    rate,
    ROUND(rate - LAG(rate) OVER (
        PARTITION BY currency_code ORDER BY rate_date
    ), 4) AS daily_change
FROM currency.rates
WHERE currency_code IN ('USD', 'EUR');

SELECT *
FROM currency.v_usd_eur_trend
ORDER BY currency_code, rate_date;


-- 6. Materialized view: daily weather summary
CREATE MATERIALIZED VIEW IF NOT EXISTS weather.mv_daily_summary AS
SELECT
    city,
    DATE(forecast_time) AS forecast_date,
    ROUND(AVG(temperature_c), 2) AS avg_temp,
    ROUND(MAX(temperature_c), 2) AS max_temp,
    ROUND(MIN(temperature_c), 2) AS min_temp
FROM weather.forecasts
GROUP BY city, DATE(forecast_time);

SELECT * FROM weather.mv_daily_summary;

REFRESH MATERIALIZED VIEW weather.mv_daily_summary;


-- 7. EXPLAIN ANALYZE before index creation
EXPLAIN ANALYZE
SELECT *
FROM weather.forecasts
WHERE city = 'Tbilisi'
  AND forecast_time > '2026-08-27 12:00:00+00';


-- Create a composite index
CREATE INDEX IF NOT EXISTS idx_forecasts_city_time
    ON weather.forecasts (city, forecast_time);

-- Compare the plan with sequential scans disabled
SET enable_seqscan = OFF;

EXPLAIN ANALYZE
SELECT *
FROM weather.forecasts
WHERE city = 'Tbilisi'
  AND forecast_time > '2026-08-27 12:00:00+00';

-- Restore the normal query planner setting
SET enable_seqscan = ON;
