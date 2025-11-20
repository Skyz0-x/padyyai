# List available Gemini models
# IMPORTANT: Get API key from environment variable
$apiKey = $env:GOOGLE_AI_API_KEY

if (-not $apiKey) {
    Write-Host "❌ Error: GOOGLE_AI_API_KEY environment variable not set!" -ForegroundColor Red
    exit 1
}

Write-Host "Listing available Gemini models..." -ForegroundColor Cyan
Write-Host ""

$url = "https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey"

try {
    $response = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop
    
    Write-Host "✅ Available Models:" -ForegroundColor Green
    Write-Host ""
    
    foreach ($model in $response.models) {
        Write-Host "Model Name: $($model.name)" -ForegroundColor Yellow
        Write-Host "  Display Name: $($model.displayName)"
        Write-Host "  Supported Methods: $($model.supportedGenerationMethods -join ', ')"
        Write-Host ""
    }
    
} catch {
    Write-Host "❌ ERROR!" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
