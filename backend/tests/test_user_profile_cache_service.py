import json
from datetime import datetime, timezone

from app.services.user_profile_cache_service import PlayerProfileCacheService


class FakeRedis:
    def __init__(self, payload: str | None = None, get_error: Exception | None = None) -> None:
        self.payload = payload
        self.get_error = get_error
        self.last_set: tuple[str, str, int] | None = None
        self.last_expire: tuple[str, int] | None = None

    def get(self, key: str) -> str | None:
        if self.get_error is not None:
            raise self.get_error
        return self.payload

    def set(self, key: str, value: str, ex: int) -> None:
        self.last_set = (key, value, ex)

    def expire(self, key: str, seconds: int) -> None:
        self.last_expire = (key, seconds)


def test_returns_cached_profile_and_refreshes_ttl() -> None:
    cached = {
        "id": "p1",
        "username": "neo",
        "credits": 5000,
        "reputation": 0,
        "created_at": "2026-01-01T00:00:00+00:00",
        "updated_at": "2026-01-01T00:00:00+00:00",
    }
    fake_redis = FakeRedis(payload=json.dumps(cached))

    service = PlayerProfileCacheService(ttl_seconds=86400)
    service.redis = fake_redis

    result = service.get_or_hydrate_player_profile("p1")

    assert result is not None
    assert result.source == "redis"
    assert result.player == cached
    assert fake_redis.last_expire == ("player:profile:p1", 86400)


def test_cache_miss_loads_from_postgres_and_caches(monkeypatch) -> None:
    db_row = {
        "id": "p2",
        "username": "trader",
        "credits": 6500,
        "reputation": 4,
        "created_at": datetime(2026, 1, 1, tzinfo=timezone.utc),
        "updated_at": datetime(2026, 2, 1, tzinfo=timezone.utc),
    }
    fake_redis = FakeRedis(payload=None)

    service = PlayerProfileCacheService(ttl_seconds=86400)
    service.redis = fake_redis

    monkeypatch.setattr(service, "_get_from_postgres", lambda player_id: {
        "id": db_row["id"],
        "username": db_row["username"],
        "credits": db_row["credits"],
        "reputation": db_row["reputation"],
        "created_at": db_row["created_at"].isoformat(),
        "updated_at": db_row["updated_at"].isoformat(),
    })

    result = service.get_or_hydrate_player_profile("p2")

    assert result is not None
    assert result.source == "postgres"
    assert result.player["id"] == "p2"
    assert fake_redis.last_set is not None
    assert fake_redis.last_set[0] == "player:profile:p2"
    assert fake_redis.last_set[2] == 86400


def test_cache_and_postgres_miss_returns_none(monkeypatch) -> None:
    fake_redis = FakeRedis(payload=None)

    service = PlayerProfileCacheService(ttl_seconds=86400)
    service.redis = fake_redis
    monkeypatch.setattr(service, "_get_from_postgres", lambda player_id: None)

    result = service.get_or_hydrate_player_profile("missing")

    assert result is None
    assert fake_redis.last_set is None


def test_invalid_cached_json_falls_back_to_postgres(monkeypatch) -> None:
    fake_redis = FakeRedis(payload="not-json")

    service = PlayerProfileCacheService(ttl_seconds=86400)
    service.redis = fake_redis
    monkeypatch.setattr(service, "_get_from_postgres", lambda player_id: {
        "id": "p3",
        "username": "pilot",
        "credits": 7000,
        "reputation": 1,
        "created_at": "2026-01-01T00:00:00+00:00",
        "updated_at": "2026-01-01T00:00:00+00:00",
    })

    result = service.get_or_hydrate_player_profile("p3")

    assert result is not None
    assert result.source == "postgres"
    assert fake_redis.last_set is not None
