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
if (-not $env:GOOGLE_AI_API_KEY) {
    Write-Host "❌ GOOGLE_AI_API_KEY environment variable not set!" -ForegroundColor Red
    Write-Host "Set it first: `$env:GOOGLE_AI_API_KEY='YOUR_KEY'" -ForegroundColor Yellow
    exit 1
}
npx supabase secrets set --project-ref zwkntyiujwglpibmftzf GOOGLE_AI_API_KEY=$env:GOOGLE_AI_API_KEY

Write-Host ""
Write-Host "🚀 Deploying function..." -ForegroundColor Cyan
supabase functions deploy chat-rice-tips

Write-Host ""
Write-Host "✅ Done! Try your chatbot now." -ForegroundColor Green
