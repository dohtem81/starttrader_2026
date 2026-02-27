SELECT 'locations' AS table_name, COUNT(*) AS actual_count, 4 AS expected_count FROM locations
UNION ALL
SELECT 'commodities' AS table_name, COUNT(*) AS actual_count, 6 AS expected_count FROM commodities
UNION ALL
SELECT 'market_prices' AS table_name, COUNT(*) AS actual_count, 24 AS expected_count FROM market_prices
UNION ALL
SELECT 'zone_profiles' AS table_name, COUNT(*) AS actual_count, 9 AS expected_count FROM zone_profiles;
