@echo off
setlocal
title French Course B1 - Production Deployment

echo ====================================================
echo      FRENCH COURSE B1 DEPLOYMENT TOOL
echo ====================================================
echo.
echo THIS SCRIPT WILL PUSH TO GITHUB (STAGING/PRODUCTION)
echo NOTE: Essays and Dialogues are AUTOMATICALLY hidden
echo in the production build (Release mode).
echo.
echo ====================================================
echo.

set /p commit_msg="Enter commit message (default: Update deployment): "
if "%commit_msg%"=="" set commit_msg=Update deployment

echo.
echo [1/3] Staging changes...
git add .

echo [2/3] Committing changes...
git commit -m "%commit_msg%"

echo [3/3] Pushing to GitHub (main)...
git branch -M main
git push -u origin main

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo   ERROR: Deployment failed! Check your connection.
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
) else (
    echo.
    echo ====================================================
    echo   SUCCESS! Vercel will now start the build.
    echo   Live site will be updated in a few minutes.
    echo ====================================================
)

echo.
echo (If you are in PowerShell, remember to use .\deploy.bat)
pause
endlocal
