CREATE TABLE IF NOT EXISTS players (
  id UUID PRIMARY KEY,
  username VARCHAR(32) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  credits BIGINT NOT NULL DEFAULT 5000,
  reputation INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS locations (
  id TEXT PRIMARY KEY,
  code VARCHAR(64) UNIQUE NOT NULL,
  name VARCHAR(128) NOT NULL,
  location_type VARCHAR(16) NOT NULL,
  x DOUBLE PRECISION NOT NULL,
  y DOUBLE PRECISION NOT NULL,
  security_level INT NOT NULL CHECK (security_level BETWEEN 0 AND 100),
  has_market BOOLEAN NOT NULL DEFAULT TRUE,
  has_repair BOOLEAN NOT NULL DEFAULT TRUE,
  has_refuel BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commodities (
  id TEXT PRIMARY KEY,
  code VARCHAR(64) UNIQUE NOT NULL,
  name VARCHAR(128) NOT NULL,
  unit_mass INT NOT NULL CHECK (unit_mass > 0),
  base_price INT NOT NULL CHECK (base_price > 0),
  illegal_level INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS market_prices (
  location_id TEXT NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
  commodity_id TEXT NOT NULL REFERENCES commodities(id) ON DELETE CASCADE,
  buy_price INT NOT NULL CHECK (buy_price > 0),
  sell_price INT NOT NULL CHECK (sell_price > 0),
  stock_qty INT NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (location_id, commodity_id),
  CHECK (buy_price >= sell_price)
);

CREATE TABLE IF NOT EXISTS zone_profiles (
  id TEXT PRIMARY KEY,
  zone_type VARCHAR(32) NOT NULL,
  center_x DOUBLE PRECISION NOT NULL,
  center_y DOUBLE PRECISION NOT NULL,
  radius DOUBLE PRECISION NOT NULL CHECK (radius > 0),
  risk_level INT NOT NULL CHECK (risk_level BETWEEN 0 AND 100),
  security_level INT NOT NULL CHECK (security_level BETWEEN 0 AND 100),
  profit_multiplier NUMERIC(4,2) NOT NULL CHECK (profit_multiplier >= 1.00),
  pvp_allowed BOOLEAN NOT NULL DEFAULT TRUE,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
