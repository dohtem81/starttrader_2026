INSERT INTO locations (
  id,
  code,
  name,
  location_type,
  x,
  y,
  security_level,
  has_market,
  has_repair,
  has_refuel
)
VALUES
  ('earth-orbit-station', 'earth-orbit-station', 'Earth Orbit Station', 'station', -1200, 300, 90, TRUE, TRUE, TRUE),
  ('mars-orbit-station', 'mars-orbit-station', 'Mars Orbit Station', 'station', 2200, -600, 82, TRUE, TRUE, TRUE),
  ('ceres-hub', 'ceres-hub', 'Ceres Hub', 'station', 800, 2100, 68, TRUE, TRUE, TRUE),
  ('jupiter-trade-ring', 'jupiter-trade-ring', 'Jupiter Trade Ring', 'station', 5400, 1200, 40, TRUE, TRUE, TRUE)
ON CONFLICT (id) DO UPDATE
SET
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  location_type = EXCLUDED.location_type,
  x = EXCLUDED.x,
  y = EXCLUDED.y,
  security_level = EXCLUDED.security_level,
  has_market = EXCLUDED.has_market,
  has_repair = EXCLUDED.has_repair,
  has_refuel = EXCLUDED.has_refuel,
  updated_at = now();

INSERT INTO commodities (
  id,
  code,
  name,
  unit_mass,
  base_price,
  illegal_level
)
VALUES
  ('food', 'food', 'Food', 1, 10, 0),
  ('water', 'water', 'Water', 1, 8, 0),
  ('ore', 'ore', 'Ore', 2, 20, 0),
  ('electronics', 'electronics', 'Electronics', 1, 36, 0),
  ('medicine', 'medicine', 'Medicine', 1, 44, 0),
  ('machinery', 'machinery', 'Machinery', 3, 55, 0)
ON CONFLICT (id) DO UPDATE
SET
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  unit_mass = EXCLUDED.unit_mass,
  base_price = EXCLUDED.base_price,
  illegal_level = EXCLUDED.illegal_level,
  updated_at = now();

INSERT INTO market_prices (
  location_id,
  commodity_id,
  buy_price,
  sell_price,
  stock_qty
)
VALUES
  ('earth-orbit-station', 'food', 9, 7, 320),
  ('earth-orbit-station', 'water', 8, 6, 280),
  ('earth-orbit-station', 'ore', 24, 20, 130),
  ('earth-orbit-station', 'electronics', 42, 37, 110),
  ('earth-orbit-station', 'medicine', 48, 42, 95),
  ('earth-orbit-station', 'machinery', 62, 55, 70),

  ('mars-orbit-station', 'food', 13, 10, 180),
  ('mars-orbit-station', 'water', 11, 9, 170),
  ('mars-orbit-station', 'ore', 18, 15, 240),
  ('mars-orbit-station', 'electronics', 40, 35, 130),
  ('mars-orbit-station', 'medicine', 52, 46, 80),
  ('mars-orbit-station', 'machinery', 58, 52, 90),

  ('ceres-hub', 'food', 12, 9, 190),
  ('ceres-hub', 'water', 10, 8, 180),
  ('ceres-hub', 'ore', 16, 13, 300),
  ('ceres-hub', 'electronics', 38, 33, 120),
  ('ceres-hub', 'medicine', 50, 44, 85),
  ('ceres-hub', 'machinery', 53, 47, 115),

  ('jupiter-trade-ring', 'food', 16, 12, 120),
  ('jupiter-trade-ring', 'water', 14, 10, 130),
  ('jupiter-trade-ring', 'ore', 21, 17, 190),
  ('jupiter-trade-ring', 'electronics', 34, 30, 170),
  ('jupiter-trade-ring', 'medicine', 58, 52, 70),
  ('jupiter-trade-ring', 'machinery', 48, 42, 140)
ON CONFLICT (location_id, commodity_id) DO UPDATE
SET
  buy_price = EXCLUDED.buy_price,
  sell_price = EXCLUDED.sell_price,
  stock_qty = EXCLUDED.stock_qty,
  updated_at = now();
