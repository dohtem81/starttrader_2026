$ErrorActionPreference = "Stop"

Write-Host "Starting required services (db, redis)..."
docker compose up -d db redis

Write-Host "Running backend unit tests in Docker (api-tests)..."
docker compose run --rm api-tests

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Docker unit tests completed successfully."
