from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from app.services.user_profile_cache_service import PlayerProfileCacheService

app = FastAPI(title="StarTrader API")
player_profile_cache_service = PlayerProfileCacheService()


class LoginHydrateRequest(BaseModel):
    player_id: str


class LoginHydrateResponse(BaseModel):
    source: str
    ttl_seconds: int
    player: dict


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/internal/auth/on-login", response_model=LoginHydrateResponse)
def on_login_hydrate(request: LoginHydrateRequest) -> LoginHydrateResponse:
    hydrated = player_profile_cache_service.get_or_hydrate_player_profile(request.player_id)
    if hydrated is None:
        raise HTTPException(status_code=404, detail="Player not found")

    return LoginHydrateResponse(
        source=hydrated.source,
        ttl_seconds=player_profile_cache_service.ttl_seconds,
        player=hydrated.player,
    )
