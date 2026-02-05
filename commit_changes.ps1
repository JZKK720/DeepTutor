# Script to commit and push changes to fork repo
# Run this when network is available

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Committing changes to DeepTutor fork repo" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Configure git user if not already set (uncomment and modify if needed)
# git config user.email "your-email@example.com"
# git config user.name "Your Name"

# Check git status first
Write-Host "Git status:" -ForegroundColor Yellow
git status --short
Write-Host ""

# Stage all modified and new files
Write-Host "Staging files..." -ForegroundColor Yellow
git add web/lib/api.ts
git add local_port_update_report.md
git add scripts/proxy_8681.py

# Commit with descriptive message
Write-Host "Committing..." -ForegroundColor Yellow
git commit -m "fix: SSR port handling for Docker container

- Add runtime detection for SSR vs client-side in web/lib/api.ts
  - Server-side (container): use internal port 8001
  - Client-side (browser): use external port 8681
- Update local_port_update_report.md with SSR troubleshooting section
- Add scripts/proxy_8681.py as temporary workaround for existing containers

This fixes the 'Cannot connect to backend at localhost:8681' error
that occurred during Server-Side Rendering inside Docker.

Closes SSR connection issue when frontend tries to reach backend
on the mapped host port from inside the container."

# Push to origin (your fork)
Write-Host "Pushing to fork..." -ForegroundColor Yellow
git push origin main

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Done! Changes pushed to your fork." -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

# Clean up temporary commit scripts
Remove-Item -Path "commit_changes.bat", "commit_changes.ps1" -ErrorAction SilentlyContinue
Write-Host "Cleaned up temporary scripts." -ForegroundColor Gray
