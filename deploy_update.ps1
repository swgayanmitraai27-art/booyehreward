# BOOYAH REWARDS - 1-CLICK INSTANT LIVE DEPLOY SCRIPT (POWERSHELL)
param(
    [string]$Message = "Live bug fix and UI update"
)

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  BOOYAH REWARDS - 1-CLICK INSTANT LIVE DEPLOY" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Flutter Build Web Release
Write-Host "[1/4] Compiling Flutter Web Release..." -ForegroundColor Green
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Flutter build failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

# 2. Sync server.js with VPS
Write-Host "[2/4] Syncing Backend with VPS (35.154.113.3)..." -ForegroundColor Green
$keyPath = "C:\Users\Admin\Documents\Downloads\LightsailDefaultKey-ap-south-1.pem"
scp -i "$keyPath" -o StrictHostKeyChecking=no "server.js" ubuntu@35.154.113.3:/home/ubuntu/booyah-backend/server.js
ssh -i "$keyPath" -o StrictHostKeyChecking=no ubuntu@35.154.113.3 "pm2 restart booyah-api"

# 3. Git Commit and Push to GitHub & Vercel
Write-Host "[3/4] Committing and Pushing to GitHub & Vercel..." -ForegroundColor Green
git add .
git commit -m "$Message"
git push origin main

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  SUCCESS! App updated live on Vercel & VPS!" -ForegroundColor Green
Write-Host "  Live URL: https://booyehreward.vercel.app" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Cyan
