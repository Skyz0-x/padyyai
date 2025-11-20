# Quick script to redeploy the chatbot function
# Make sure you have Supabase CLI installed first

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Redeploying Chat Function" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if supabase CLI is installed
$supabaseExists = Get-Command supabase -ErrorAction SilentlyContinue

if (-not $supabaseExists) {
    Write-Host "❌ Supabase CLI not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install it first:" -ForegroundColor Yellow
    Write-Host "  npm install -g supabase" -ForegroundColor White
    Write-Host ""
    Write-Host "OR use Supabase Dashboard:" -ForegroundColor Yellow
    Write-Host "  https://supabase.com/dashboard/project/zwkntyiujwglpibmftzf/functions/chat-rice-tips" -ForegroundColor White
    exit 1
}

Write-Host "✅ Supabase CLI found" -ForegroundColor Green
Write-Host ""

# Set the API key
Write-Host "📝 Setting API key..." -ForegroundColor Cyan
supabase secrets set GOOGLE_AI_API_KEY=AIzaSyDoVYmdDUiYfNnO6gzDHvF0DSleX8qH_yM

Write-Host ""
Write-Host "🚀 Deploying function..." -ForegroundColor Cyan
supabase functions deploy chat-rice-tips

Write-Host ""
Write-Host "✅ Done! Try your chatbot now." -ForegroundColor Green
