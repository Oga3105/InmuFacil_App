# Utility script to clean up development artifacts
Write-Host "🧹 Cleaning up temporary files..." -ForegroundColor Cyan

# Remove Log files
Get-ChildItem -Path . -Filter "*.log" -Recurse | ForEach-Object {
    Write-Host "Removing log: $($_.Name)" -ForegroundColor Gray
    Remove-Item $_.FullName -Force
}

# Remove SQLite DBs (Test artifacts)
Get-ChildItem -Path . -Filter "*.db" -Recurse | Where-Object { $_.Name -ne "inmufacil.db" } | ForEach-Object {
    Write-Host "Removing db: $($_.Name)" -ForegroundColor Gray
    Remove-Item $_.FullName -Force
}

# Remove PyCache
Get-ChildItem -Path . -Filter "__pycache__" -Recurse | ForEach-Object {
    Write-Host "Removing cache: $($_.FullName)" -ForegroundColor Gray
    Remove-Item $_.FullName -Recurse -Force
}

Write-Host "✨ Cleanup Complete!" -ForegroundColor Green
