INSERT INTO zone_profiles (
  id,
  zone_type,
  center_x,
  center_y,
  radius,
  risk_level,
  security_level,
  profit_multiplier,
  pvp_allowed,
  active
)
VALUES
  ('z_earth_core_safe', 'core_safe', -1200, 300, 550, 8, 92, 1.00, FALSE, TRUE),
  ('z_mars_core_safe', 'core_safe', 2200, -600, 500, 10, 88, 1.00, FALSE, TRUE),
  ('z_earth_approach_high_value', 'approach_high_value', -1200, 300, 1250, 58, 42, 1.22, TRUE, TRUE),
  ('z_mars_approach_high_value', 'approach_high_value', 2200, -600, 1350, 66, 34, 1.28, TRUE, TRUE),
  ('z_jupiter_approach_high_value', 'approach_high_value', 5400, 1200, 1700, 78, 22, 1.45, TRUE, TRUE),
  ('z_inner_belt_open', 'belt_open', 700, 500, 2500, 38, 52, 1.10, TRUE, TRUE),
  ('z_ceres_belt_open', 'belt_open', 800, 2100, 1600, 44, 46, 1.16, TRUE, TRUE),
  ('z_outer_edge_wild_east', 'edge_wild', 6900, 400, 1900, 90, 10, 1.58, TRUE, TRUE),
  ('z_outer_edge_wild_northwest', 'edge_wild', -5400, 5200, 1800, 86, 12, 1.52, TRUE, TRUE)
ON CONFLICT (id) DO UPDATE
SET
  zone_type = EXCLUDED.zone_type,
  center_x = EXCLUDED.center_x,
  center_y = EXCLUDED.center_y,
  radius = EXCLUDED.radius,
  risk_level = EXCLUDED.risk_level,
  security_level = EXCLUDED.security_level,
  profit_multiplier = EXCLUDED.profit_multiplier,
  pvp_allowed = EXCLUDED.pvp_allowed,
  active = EXCLUDED.active,
  updated_at = now();
