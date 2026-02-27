# Seed Loader Pseudocode (Python)

## Purpose

Provide implementation-ready pseudocode for a deterministic, idempotent `seed_loader.py` that imports Sol-1 seed files.

## Scope

- Reads YAML seed files from `docs/seeds/`
- Validates schema + business rules
- Upserts into PostgreSQL in one transaction
- Supports dry-run mode
- Produces structured error output

## Suggested Module Layout

```text
backend/
  app/
    seeds/
      seed_loader.py
      validators.py
      upserts.py
      types.py
```

## Data Types (pseudocode)

```python
class ValidationError:
    file_name: str
    record_index: int | None
    field: str | None
    rule: str
    actual: object

class SeedBundle:
    locations: dict
    commodities: dict
    market_prices: dict
    zones: dict

class SeedLoadResult:
    inserted: dict[str, int]
    updated: dict[str, int]
    warnings: list[str]
```

## Entry Point

```python
def main(argv):
    args = parse_args(argv)
    cfg = load_config(args)

    bundle = load_seed_files(seed_dir=args.seed_dir)
    errors = validate_bundle(bundle)
    if errors:
        print_validation_errors(errors)
        return 1

    if args.dry_run:
        print("Dry run OK: all seed validations passed")
        return 0

    with db_session(cfg.database_url) as session:
        result = apply_seed_bundle(session, bundle, strict_version=args.strict_version)

    print_summary(result)
    return 0
```

## CLI Shape

```python
def parse_args(argv):
    # --seed-dir (default: docs/seeds)
    # --dry-run
    # --strict-version
    # --fail-on-warning
    # --verbose
```

## File Loading

```python
def load_seed_files(seed_dir: str) -> SeedBundle:
    locations = read_yaml(seed_dir / "sol1-locations.yaml")
    commodities = read_yaml(seed_dir / "sol1-commodities.yaml")
    market_prices = read_yaml(seed_dir / "sol1-market-prices.yaml")
    zones = read_yaml(seed_dir / "sol1-zones.yaml")

    return SeedBundle(
        locations=locations,
        commodities=commodities,
        market_prices=market_prices,
        zones=zones,
    )
```

## Validation Pipeline

```python
def validate_bundle(bundle: SeedBundle) -> list[ValidationError]:
    errors = []

    errors += validate_locations(bundle.locations)
    errors += validate_commodities(bundle.commodities)
    errors += validate_market_prices(bundle.market_prices)
    errors += validate_zones(bundle.zones)

    # Cross-file references
    errors += validate_market_refs(
        market_prices=bundle.market_prices,
        location_ids=get_location_ids(bundle.locations),
        commodity_ids=get_commodity_ids(bundle.commodities),
    )

    errors += validate_core_safe_rules(bundle.zones)
    errors += validate_seed_versions(bundle)

    return errors
```

### Validation Rules (implementation hints)

```python
def validate_locations(doc):
    # unique id/code
    # security_level in [0,100]
    # coordinates in world bounds


def validate_commodities(doc):
    # unique id/code
    # unit_mass > 0
    # base_price > 0
    # volatility in [0.05,0.35]


def validate_market_prices(doc):
    # buy_price >= sell_price > 0
    # stock_qty >= 0


def validate_zones(doc):
    # zone_type enum check
    # radius > 0
    # risk/security in [0,100]
    # profit_multiplier >= 1.0
```

## Transaction + Upsert Flow

```python
def apply_seed_bundle(session, bundle: SeedBundle, strict_version: bool) -> SeedLoadResult:
    result = SeedLoadResult(inserted={}, updated={}, warnings=[])

    with session.begin():
        ensure_seed_version_ok(session, bundle, strict_version)

        result += upsert_locations(session, bundle.locations)
        result += upsert_commodities(session, bundle.commodities)
        result += upsert_market_prices(session, bundle.market_prices)
        result += upsert_zones(session, bundle.zones)

        write_seed_audit(session, bundle)

    return result
```

## Upsert Patterns

### SQLAlchemy-style pseudocode

```python
def upsert_locations(session, locations_doc):
    for row in locations_doc["locations"]:
        stmt = pg_insert(Location).values(...row...)
        stmt = stmt.on_conflict_do_update(
            index_elements=[Location.id],
            set_={
                "name": row["name"],
                "x": row["x"],
                "y": row["y"],
                "security_level": row["security_level"],
                "has_market": row["has_market"],
                "has_repair": row["has_repair"],
                "has_refuel": row["has_refuel"],
                "updated_at": now_utc(),
            },
        )
        session.execute(stmt)
```

### Market price conflict key

```python
# unique(location_id, commodity_id)
stmt.on_conflict_do_update(
    index_elements=[MarketPrice.location_id, MarketPrice.commodity_id],
    set_={"buy_price": ..., "sell_price": ..., "stock_qty": ..., "updated_at": now_utc()},
)
```

## Idempotency + Versioning

```python
def ensure_seed_version_ok(session, bundle, strict_version):
    # optional table: seed_metadata(seed_name, version, applied_at)
    # if strict_version and incoming_version < applied_version: raise
    # if incoming_version == applied_version: allow rerun (idempotent)
```

## Error Reporting Format

```python
def print_validation_errors(errors):
    for err in errors:
        print(
            f"{err.file_name} item[{err.record_index}] field={err.field} "
            f"rule={err.rule} actual={err.actual}"
        )
```

Example output:

```text
sol1-market-prices.yaml item[12] field=buy_price rule=buy_price>=sell_price actual=14<18
```

## Post-Load Smoke Checks (optional command)

```python
def smoke_check(session):
    assert count_locations(session) >= 4
    assert count_commodities(session) >= 6
    assert count_zones(session) >= 8
    assert market_rows_exist_for_all_locations(session)
```

## Suggested Next Step

After this pseudocode is approved, generate:

1. SQLAlchemy models
2. Alembic migration for required tables
3. Real `seed_loader.py` with testable validators
4. A `make seed` or task runner command
