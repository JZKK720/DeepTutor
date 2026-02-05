# Diagnose Local LLM Connection Issues
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Local LLM Connection Diagnostics" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check Docker version and type
Write-Host "1. Docker Information:" -ForegroundColor Yellow
docker version --format "   Version: {{.Server.Version}}"
docker info --format "   OS Type: {{.OSType}}"
docker info --format "   Architecture: {{.Architecture}}"
Write-Host ""

# 2. Check if DeepTutor container is running
Write-Host "2. Container Status:" -ForegroundColor Yellow
$container = docker ps --filter "name=deeptutor" --format "   Name: {{.Names}} | Status: {{.Status}}"
if ($container) { Write-Host $container -ForegroundColor Green } else { Write-Host "   ✗ Container 'deeptutor' not running" -ForegroundColor Red }
Write-Host ""

# 3. Check Windows host IP addresses
Write-Host "3. Windows Host IP Addresses:" -ForegroundColor Yellow
Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -notlike "127.*" } | ForEach-Object { Write-Host "   $($_.IPAddress) ($($_.InterfaceAlias))" }
Write-Host ""

# 4. Test Ollama from Windows host
Write-Host "4. Testing Ollama on Windows Host:" -ForegroundColor Yellow
try { 
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
    Write-Host "   ✓ localhost:11434 - Working" -ForegroundColor Green
    Write-Host "   Models: $($response.models.name -join ', ')" -ForegroundColor Gray
} catch { 
    Write-Host "   ✗ localhost:11434 - Failed: $_.Exception.Message" -ForegroundColor Red 
}

# 5. Test from inside container (if running)
Write-Host ""
Write-Host "5. Testing from Inside Container:" -ForegroundColor Yellow
if ($container) {
    Write-Host "   Testing host.docker.internal:11434..." -ForegroundColor Gray
    $result = docker exec deeptutor sh -c "curl -s http://host.docker.internal:11434/api/tags 2>&1 || echo 'FAILED'"
    if ($result -match "FAILED" -or $result -match "Could not resolve") {
        Write-Host "   ✗ host.docker.internal:11434 - Failed" -ForegroundColor Red
    } else {
        Write-Host "   ✓ host.docker.internal:11434 - Working" -ForegroundColor Green
    }
    
    # Get container's network info
    Write-Host ""
    Write-Host "   Container Network Info:" -ForegroundColor Gray
    docker exec deeptutor sh -c "cat /etc/hosts | grep host.docker" 2>$null
} else {
    Write-Host "   Container not running - skipping" -ForegroundColor Gray
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Recommended Solutions (in order):" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 1: Use Docker Desktop's host.docker.internal (Recommended)" -ForegroundColor Green
Write-Host "   Prerequisites:" -ForegroundColor White
Write-Host "   - Docker Desktop for Windows (not Docker Engine)" -ForegroundColor Gray
Write-Host "   - Ollama/LM Studio must bind to 0.0.0.0 (not just 127.0.0.1)" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2: Use host.internal.docker (Alternative)" -ForegroundColor Green
Write-Host "   Try: LLM_HOST=http://host.internal.docker:11434" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 3: Use Windows Host IP (Last resort)" -ForegroundColor Yellow
Write-Host "   Find your host IP with: ipconfig" -ForegroundColor Gray
Write-Host "   Then: LLM_HOST=http://YOUR_IP:11434" -ForegroundColor Gray
Write-Host "   ⚠️  IP may change when you reconnect to network" -ForegroundColor Red
Write-Host ""
Write-Host "Option 4: Use Network Mode Host (Simplest but less secure)" -ForegroundColor Yellow
Write-Host "   Add to docker-compose.yml:" -ForegroundColor Gray
Write-Host "   network_mode: host" -ForegroundColor Green
Write-Host "   ⚠️  Container shares host network namespace" -ForegroundColor Red
