SELECT
  'sanity' AS check_group,
  'locations_count' AS check_name,
  COUNT(*)::bigint AS actual_value,
  4::bigint AS expected_value,
  (COUNT(*) = 4) AS ok
FROM locations
UNION ALL
SELECT
  'sanity',
  'commodities_count',
  COUNT(*)::bigint,
  6::bigint,
  (COUNT(*) = 6)
FROM commodities
UNION ALL
SELECT
  'sanity',
  'market_prices_count',
  COUNT(*)::bigint,
  24::bigint,
  (COUNT(*) = 24)
FROM market_prices
UNION ALL
SELECT
  'sanity',
  'zone_profiles_count',
  COUNT(*)::bigint,
  9::bigint,
  (COUNT(*) = 9)
FROM zone_profiles
UNION ALL
SELECT
  'integrity',
  'market_prices_missing_location',
  COUNT(*)::bigint,
  0::bigint,
  (COUNT(*) = 0)
FROM market_prices mp
LEFT JOIN locations l ON l.id = mp.location_id
WHERE l.id IS NULL
UNION ALL
SELECT
  'integrity',
  'market_prices_missing_commodity',
  COUNT(*)::bigint,
  0::bigint,
  (COUNT(*) = 0)
FROM market_prices mp
LEFT JOIN commodities c ON c.id = mp.commodity_id
WHERE c.id IS NULL
UNION ALL
SELECT
  'integrity',
  'market_prices_buy_lt_sell',
  COUNT(*)::bigint,
  0::bigint,
  (COUNT(*) = 0)
FROM market_prices
WHERE buy_price < sell_price
UNION ALL
SELECT
  'integrity',
  'zone_profiles_invalid_bounds',
  COUNT(*)::bigint,
  0::bigint,
  (COUNT(*) = 0)
FROM zone_profiles
WHERE risk_level NOT BETWEEN 0 AND 100
   OR security_level NOT BETWEEN 0 AND 100
   OR radius <= 0
   OR profit_multiplier < 1.00;
