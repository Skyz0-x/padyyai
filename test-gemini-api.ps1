# Test Google Gemini API directly
# This will help us debug the exact issue

$apiKey = "AIzaSyDoVYmdDUiYfNnO6gzDHvF0DSleX8qH_yM"

Write-Host "Testing Google Gemini API..." -ForegroundColor Cyan
Write-Host ""

# Test with v1beta endpoint
$url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey"

$body = @{
    contents = @(
        @{
            role = "user"
            parts = @(
                @{
                    text = "Hello, how do I grow rice?"
                }
            )
        }
    )
    generationConfig = @{
        temperature = 0.7
        topK = 40
        topP = 0.95
        maxOutputTokens = 1024
    }
} | ConvertTo-Json -Depth 10

Write-Host "URL: $url" -ForegroundColor Yellow
Write-Host ""
Write-Host "Sending request..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
    
} catch {
    Write-Host "❌ ERROR!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error Response:" -ForegroundColor Red
        Write-Host $responseBody
    }
    
    Write-Host ""
    Write-Host "Full Error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
