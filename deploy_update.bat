@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo   BOOYAH REWARDS - 1-CLICK INSTANT LIVE DEPLOY
echo ===================================================
echo.

set MSG=%*
if "%MSG%"=="" set MSG=Live bug fix and UI update

echo [1/4] Compiling Flutter Web Release...
call flutter build web --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter build failed!
    exit /b %ERRORLEVEL%
)

echo.
echo [2/4] Syncing Backend with VPS (35.154.113.3)...
scp -i "C:\Users\Admin\Documents\Downloads\LightsailDefaultKey-ap-south-1.pem" -o StrictHostKeyChecking=no "server.js" ubuntu@35.154.113.3:/home/ubuntu/booyah-backend/server.js
ssh -i "C:\Users\Admin\Documents\Downloads\LightsailDefaultKey-ap-south-1.pem" -o StrictHostKeyChecking=no ubuntu@35.154.113.3 "pm2 restart booyah-api"

echo.
echo [3/4] Committing and Pushing to GitHub & Vercel...
git add .
git commit -m "%MSG%"
git push origin main
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Git push failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ===================================================
echo  SUCCESS! App updated live on Vercel and VPS!
echo  URL: https://booyehreward.vercel.app
echo ===================================================
