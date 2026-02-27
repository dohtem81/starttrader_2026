$ErrorActionPreference = "Stop"

Write-Host "Stopping Docker test infrastructure..."
docker compose down

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Docker services stopped."
