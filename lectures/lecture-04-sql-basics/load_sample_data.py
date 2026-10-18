
"""
Lecture 4: საწყისი მონაცემების ჩატვირთვა cached sample-ებიდან.

აჩვენებს:
- Transaction-ის მართვას (commit / rollback)
- Bulk insert-ს (executemany)
- Primary და foreign key-ების გამოყენებას
"""

import json
import os
from datetime import datetime, timezone
from pathlib import Path

import psycopg2
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / ".env")
SAMPLE_DIR = ROOT / "data" / "sample"


def get_connection():
    return psycopg2.connect(
        host=os.getenv("POSTGRES_HOST", "localhost"),
        port=os.getenv("POSTGRES_PORT", "5432"),
        dbname=os.getenv("POSTGRES_DB", "enterprise_open_data"),
        user=os.getenv("POSTGRES_USER", "eodp_user"),
        password=os.getenv("POSTGRES_PASSWORD", "change_me_locally"),
    )


def load_weather(cur):
    data = json.loads(
        (SAMPLE_DIR / "weather_sample.json").read_text()
    )
    hourly = data["hourly"]

    rows = list(zip(
        [data["city"]] * len(hourly["time"]),
        [data["latitude"]] * len(hourly["time"]),
        [data["longitude"]] * len(hourly["time"]),
        hourly["time"],
        hourly["temperature_2m"],
        hourly["relative_humidity_2m"],
        hourly["precipitation"],
        hourly["wind_speed_10m"],
    ))

    cur.executemany(
        """
        INSERT INTO weather.forecasts
            (city, latitude, longitude, forecast_time,
             temperature_c, humidity_pct, precipitation_mm,
             wind_speed_kmh)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (city, forecast_time) DO NOTHING
        """,
        rows,
    )

    return len(rows)


def load_currency(cur):
    data = json.loads(
        (SAMPLE_DIR / "nbg_sample.json").read_text()
    )
    entry = data[0]
    rate_date = entry["date"][:10]
    inserted = 0

    for c in entry["currencies"]:
        cur.execute(
            """
            INSERT INTO currency.currencies (code, name)
            VALUES (%s, %s)
            ON CONFLICT (code) DO NOTHING
            """,
            (c["code"], c["name"]),
        )

        cur.execute(
            """
            INSERT INTO currency.rates
                (currency_code, quantity, rate, rate_date)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (currency_code, rate_date) DO NOTHING
            """,
            (c["code"], c["quantity"], c["rate"], rate_date),
        )

        inserted += 1

    return inserted


def load_seismic(cur):
    data = json.loads(
        (SAMPLE_DIR / "earthquakes_sample.geojson").read_text()
    )
    rows = []

    for feature in data["features"]:
        props = feature["properties"]
        lon, lat, depth = feature["geometry"]["coordinates"]

        event_time = datetime.fromtimestamp(
            props["time"] / 1000,
            tz=timezone.utc,
        )

        rows.append((
            feature["id"],
            props["mag"],
            props["place"],
            event_time,
            lat,
            lon,
            depth,
        ))

    cur.executemany(
        """
        INSERT INTO seismic.events
            (event_id, magnitude, place, event_time,
             latitude, longitude, depth_km)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (event_id) DO NOTHING
        """,
        rows,
    )

    return len(rows)


def main():
    conn = get_connection()

    try:
        with conn:
            with conn.cursor() as cur:
                w = load_weather(cur)
                c = load_currency(cur)
                s = load_seismic(cur)

        print(f"[OK] weather.forecasts: {w} row(s) attempted")
        print(f"[OK] currency.rates:    {c} row(s) attempted")
        print(f"[OK] seismic.events:    {s} row(s) attempted")
        print("Transaction committed.")

    except Exception as exc:
        print(f"[FAIL] შეცდომა, rollback: {exc}")
        raise

    finally:
        conn.close()


if __name__ == "__main__":
    main()
