# Test Local LLM Connection from Docker Container
# Run these commands to diagnose connection issues

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Testing Local LLM Connection" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Test from host machine
Write-Host "1. Testing from HOST machine..." -ForegroundColor Yellow
Write-Host "   Testing Ollama (port 11434):" -ForegroundColor Gray
try { $r = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5; Write-Host "   ✓ Ollama is reachable" -ForegroundColor Green } catch { Write-Host "   ✗ Ollama not reachable: $_" -ForegroundColor Red }

Write-Host "   Testing LM Studio (port 14321):" -ForegroundColor Gray
try { $r = Invoke-RestMethod -Uri "http://localhost:14321/v1/models" -TimeoutSec 5; Write-Host "   ✓ LM Studio is reachable" -ForegroundColor Green } catch { Write-Host "   ✗ LM Studio not reachable: $_" -ForegroundColor Red }

Write-Host ""

# 2. Test from inside container
Write-Host "2. Testing from CONTAINER..." -ForegroundColor Yellow
Write-Host "   Getting host IP..." -ForegroundColor Gray

# Get host IP
$hostIP = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
Write-Host "   Host IP: $hostIP" -ForegroundColor Cyan

Write-Host ""
Write-Host "3. To test from INSIDE the container, run:" -ForegroundColor Yellow
Write-Host "   docker exec -it deeptutor bash" -ForegroundColor White
Write-Host "   curl http://host.docker.internal:11434/api/tags" -ForegroundColor White
Write-Host "   curl http://$hostIP`:11434/api/tags" -ForegroundColor White
Write-Host ""
Write-Host "   If host.docker.internal fails, try the IP address instead." -ForegroundColor Gray

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Common Fixes for Windows:" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "1. Use host IP instead of host.docker.internal in .env:" -ForegroundColor White
Write-Host "   LLM_HOST=http://${hostIP}:11434" -ForegroundColor Green
Write-Host ""
Write-Host "2. Or add to docker-compose.yml (already added if you see extra_hosts):" -ForegroundColor White
Write-Host "   extra_hosts:" -ForegroundColor Green
Write-Host '     - "host.docker.internal:host-gateway"' -ForegroundColor Green
Write-Host ""
Write-Host "3. Make sure Ollama/LM Studio binds to 0.0.0.0, not just 127.0.0.1" -ForegroundColor White
Write-Host "   Ollama: Set OLLAMA_HOST=0.0.0.0 before starting" -ForegroundColor Gray
Write-Host "   LM Studio: Enable 'Run on Local Network' in settings" -ForegroundColor Gray
