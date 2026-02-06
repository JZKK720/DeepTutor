@echo off
REM Script to commit and push changes to fork repo
REM Run this when network is available

echo ============================================
echo Committing changes to DeepTutor fork repo
echo ============================================
echo.

REM Configure git user if not already set (uncomment and modify if needed)
REM git config user.email "your-email@example.com"
REM git config user.name "Your Name"

REM Check git status first
echo Git status:
git status --short
echo.

REM Stage all modified and new files
echo Staging files...
git add web/lib/api.ts
git add local_port_update_report.md
git add scripts/proxy_8781.py

REM Commit with descriptive message
echo Committing...
git commit -m "fix: SSR port handling for Docker container"

REM Push to origin (your fork)
echo Pushing to fork...
git push origin main

echo.
echo ============================================
echo Done! Changes pushed to your fork.
echo ============================================

REM Clean up temporary commit scripts
del /f commit_changes.bat 2>nul
del /f commit_changes.ps1 2>nul

pause
