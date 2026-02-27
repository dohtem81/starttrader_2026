SELECT
  'market_prices_missing_location' AS check_name,
  COUNT(*) AS issue_count
FROM market_prices mp
LEFT JOIN locations l ON l.id = mp.location_id
WHERE l.id IS NULL
UNION ALL
SELECT
  'market_prices_missing_commodity' AS check_name,
  COUNT(*) AS issue_count
FROM market_prices mp
LEFT JOIN commodities c ON c.id = mp.commodity_id
WHERE c.id IS NULL
UNION ALL
SELECT
  'market_prices_buy_lt_sell' AS check_name,
  COUNT(*) AS issue_count
FROM market_prices
WHERE buy_price < sell_price
UNION ALL
SELECT
  'zone_profiles_invalid_bounds' AS check_name,
  COUNT(*) AS issue_count
FROM zone_profiles
WHERE risk_level NOT BETWEEN 0 AND 100
   OR security_level NOT BETWEEN 0 AND 100
   OR radius <= 0
   OR profit_multiplier < 1.00;
