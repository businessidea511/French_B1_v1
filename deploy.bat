@echo off
set /p commit_msg="Enter commit message: "
if "%commit_msg%"=="" set commit_msg="Update deployment"

echo Staging changes...
git add .

echo Committing...
git commit -m "%commit_msg%"

echo Pushing to GitHub...
git push -u origin main

echo Done! Vercel will now start the build.
pause
