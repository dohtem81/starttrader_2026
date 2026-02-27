import json
import os
from dataclasses import dataclass
from datetime import datetime
from typing import Any

import psycopg
from psycopg.rows import dict_row
from redis import Redis
from redis.exceptions import RedisError


@dataclass(frozen=True)
class CachedPlayerProfile:
    source: str
    player: dict[str, Any]


class PlayerProfileCacheService:
    def __init__(
        self,
        redis_url: str | None = None,
        database_url: str | None = None,
        ttl_seconds: int | None = None,
    ) -> None:
        self.redis_url = redis_url or os.getenv("REDIS_URL", "redis://localhost:6379/0")
        self.database_url = database_url or os.getenv("DATABASE_URL", "")
        self.ttl_seconds = ttl_seconds or int(os.getenv("LOGIN_PROFILE_CACHE_TTL_SECONDS", "86400"))
        self.redis = Redis.from_url(self.redis_url, decode_responses=True)

    def get_or_hydrate_player_profile(self, player_id: str) -> CachedPlayerProfile | None:
        cache_key = self._cache_key(player_id)

        cached_payload = self._get_from_cache(cache_key)
        if cached_payload is not None:
            return CachedPlayerProfile(source="redis", player=cached_payload)

        db_payload = self._get_from_postgres(player_id)
        if db_payload is None:
            return None

        self._set_cache(cache_key, db_payload)
        return CachedPlayerProfile(source="postgres", player=db_payload)

    def _cache_key(self, player_id: str) -> str:
        return f"player:profile:{player_id}"

    def _get_from_cache(self, cache_key: str) -> dict[str, Any] | None:
        try:
            payload = self.redis.get(cache_key)
        except RedisError:
            return None

        if not payload:
            return None

        try:
            data = json.loads(payload)
            if not isinstance(data, dict):
                return None

            try:
                self.redis.expire(cache_key, self.ttl_seconds)
            except RedisError:
                pass

            return data
        except json.JSONDecodeError:
            return None

    def _set_cache(self, cache_key: str, payload: dict[str, Any]) -> None:
        try:
            self.redis.set(cache_key, json.dumps(payload), ex=self.ttl_seconds)
        except RedisError:
            return

    def _get_from_postgres(self, player_id: str) -> dict[str, Any] | None:
        if not self.database_url:
            return None

        with psycopg.connect(self.database_url, row_factory=dict_row) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT
                        id::text AS id,
                        username,
                        credits,
                        reputation,
                        created_at,
                        updated_at
                    FROM players
                    WHERE id::text = %s
                    """,
                    (player_id,),
                )
                row = cur.fetchone()

        if row is None:
            return None

        return {
            "id": row["id"],
            "username": row["username"],
            "credits": row["credits"],
            "reputation": row["reputation"],
            "created_at": self._to_iso(row.get("created_at")),
            "updated_at": self._to_iso(row.get("updated_at")),
        }

    def _to_iso(self, value: Any) -> str | None:
        if isinstance(value, datetime):
            return value.isoformat()
        return None
