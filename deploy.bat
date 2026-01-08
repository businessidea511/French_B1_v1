@echo off
set /p commit_msg="Enter commit message: "
if "%commit_msg%"=="" set commit_msg="Update deployment"

echo Staging changes...
git add .

echo Committing...
git commit -m "%commit_msg%"

echo Ensuring local branch is 'main'...
git branch -M main

echo Pushing to GitHub (HTTPS)...
git push -u origin main

echo Done! Vercel will now start the build.
echo (If you are in PowerShell, remember to use .\deploy.bat to run this next time)
pause
