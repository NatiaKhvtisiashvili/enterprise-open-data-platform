-- Lecture 3: საწყისი schema-ების შექმნა სამი მონაცემთა წყაროსთვის.
-- ცხრილების დეტალური სტრუქტურა lecture 4-ზე დაემატება.

CREATE SCHEMA IF NOT EXISTS weather;
COMMENT ON SCHEMA weather IS 'Open-Meteo API-დან საქართველოს ამინდის მონაცემები';

CREATE SCHEMA IF NOT EXISTS currency;
COMMENT ON SCHEMA currency IS 'ეროვნული ბანკის (NBG) ვალუტის კურსების მონაცემები';

CREATE SCHEMA IF NOT EXISTS seismic;
COMMENT ON SCHEMA seismic IS 'USGS Earthquake Catalog-იდან საქართველოს რეგიონის სეისმური მონაცემები';
