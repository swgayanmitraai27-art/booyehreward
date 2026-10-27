Set-Location "C:\Users\Admin\Desktop\Booyah Rewards - Copy (2)"

# Free RAM from lingering Java processes
Get-Process -Name java -ErrorAction SilentlyContinue | Stop-Process -Force

# Set Low Process Priority to prevent laptop CPU from overheating
[System.Diagnostics.Process]::GetCurrentProcess().PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal

$versions = @("1.3.8+38", "1.3.6+36", "1.3.5+35")

foreach ($v in $versions) {
    Write-Host "=========================================="
    Write-Host "=== Starting patch for release: $v ==="
    Write-Host "=========================================="
    if (Test-Path "flutter.js") {
        Rename-Item "flutter.js" "flutter.js.bak" -Force
    }
    try {
        @("y", "y", "y") | & "$env:USERPROFILE\.shorebird\bin\shorebird.ps1" patch --platforms=android --allow-asset-diffs --allow-native-diffs --release-version=$v
        Write-Host "=== Patch for $v successfully finished! ==="
    } catch {
        Write-Host "Error occurred during patching for $v"
    } finally {
        if (Test-Path "flutter.js.bak") {
            Rename-Item "flutter.js.bak" "flutter.js" -Force
        }
    }
}

Write-Host "=== All patches completed! Fetching final live status: ==="
foreach ($v in $versions) {
    Write-Host "`n--- Status for $v ---"
    & "$env:USERPROFILE\.shorebird\bin\shorebird.ps1" patches list --release-version=$v
}
