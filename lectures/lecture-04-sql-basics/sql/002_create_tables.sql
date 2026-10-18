
-- Lecture 4: Creating tables in all three schemas

-- ============ WEATHER ============
CREATE TABLE IF NOT EXISTS weather.forecasts (
    id                SERIAL PRIMARY KEY,
    city              VARCHAR(50) NOT NULL,
    latitude          NUMERIC(8,4) NOT NULL,
    longitude         NUMERIC(8,4) NOT NULL,
    forecast_time     TIMESTAMPTZ NOT NULL,
    temperature_c     NUMERIC(5,2),
    humidity_pct      NUMERIC(5,2) CHECK (humidity_pct BETWEEN 0 AND 100),
    precipitation_mm  NUMERIC(6,2) CHECK (precipitation_mm >= 0),
    wind_speed_kmh    NUMERIC(5,2) CHECK (wind_speed_kmh >= 0),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (city, forecast_time)
);

-- ============ CURRENCY ============
CREATE TABLE IF NOT EXISTS currency.currencies (
    code CHAR(3) PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS currency.rates (
    id SERIAL PRIMARY KEY,
    currency_code CHAR(3) NOT NULL
        REFERENCES currency.currencies(code),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    rate NUMERIC(10,4) NOT NULL CHECK (rate > 0),
    rate_date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (currency_code, rate_date)
);

-- ============ SEISMIC ============
CREATE TABLE IF NOT EXISTS seismic.events (
    id SERIAL PRIMARY KEY,
    event_id VARCHAR(30) NOT NULL UNIQUE,
    magnitude NUMERIC(3,1) CHECK (magnitude >= 0),
    place VARCHAR(200),
    event_time TIMESTAMPTZ NOT NULL,
    latitude NUMERIC(8,4) NOT NULL,
    longitude NUMERIC(8,4) NOT NULL,
    depth_km NUMERIC(6,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
