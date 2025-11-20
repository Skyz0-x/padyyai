# Rice Farming Chatbot Setup Guide

This guide will help you set up the AI-powered rice farming chatbot using Google AI Studio (Gemini) and Supabase Edge Functions.

## Prerequisites

- Supabase project already configured
- Google AI Studio API key (Get yours at: https://aistudio.google.com/apikey)
- Supabase CLI installed (or use Supabase Dashboard)

## Important Notes

⚠️ **SECURITY**: Never commit your API key to git! Always use environment variables or Supabase secrets.

✅ **Model**: Using `gemini-2.5-flash` for faster responses and better reliability.

## Step 1: Deploy the Edge Function

### 1.1 Install Supabase CLI (if not already installed)

```powershell
# Using npm
npm install -g supabase

# Or using scoop
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

### 1.2 Login to Supabase

```powershell
supabase login
```

### 1.3 Link Your Project

```powershell
# Navigate to your project directory
cd c:\Flutter_project\padyyai

# Link to your Supabase project
supabase link --project-ref zwkntyiujwglpibmftzf
```

### 1.4 Set the Google AI API Key as Secret

**Option A: Using Supabase Dashboard (Recommended if CLI not installed)**

1. Go to https://supabase.com/dashboard/project/zwkntyiujwglpibmftzf/settings/edge-functions
2. Scroll down to "Secrets"
3. Click "Add new secret"
4. Name: `GOOGLE_AI_API_KEY`
5. Value: `YOUR_GOOGLE_AI_API_KEY` (get from https://aistudio.google.com/apikey)
6. Click "Save"

**Option B: Using Supabase CLI**

```powershell
# Replace YOUR_API_KEY with your actual key from Google AI Studio
npx supabase secrets set --project-ref zwkntyiujwglpibmftzf GOOGLE_AI_API_KEY=YOUR_API_KEY
```

### 1.5 Deploy the Edge Function

```powershell
# Deploy the chat function
supabase functions deploy chat-rice-tips
```

You should see output like:
```
Deploying function chat-rice-tips...
Function deployed successfully!
Function URL: https://zwkntyiujwglpibmftzf.supabase.co/functions/v1/chat-rice-tips
```

## Step 2: Verify the Deployment

### 2.1 Test the Edge Function

```powershell
# Test with curl
curl -i --location --request POST 'https://zwkntyiujwglpibmftzf.supabase.co/functions/v1/chat-rice-tips' `
  --header 'Authorization: Bearer YOUR_ANON_KEY' `
  --header 'Content-Type: application/json' `
  --data '{\"message\":\"What is the best time to plant rice?\"}'
```

Replace `YOUR_ANON_KEY` with your Supabase anon key (found in Settings → API)

Expected response:
```json
{
  "response": "The best time to plant rice depends on...",
  "success": true
}
```

## Step 3: Configure Flutter App

The Flutter code is already set up! The chatbot is accessible from:

1. **Home Screen** → "Farming Tips" quick action card
2. **Navigation Route** → `/chat`

### Files Created:
- ✅ `lib/services/chat_service.dart` - Service to communicate with Edge Function
- ✅ `lib/screens/chat_bot_screen.dart` - Beautiful chat UI
- ✅ `supabase/functions/chat-rice-tips/index.ts` - Edge Function with Gemini AI

## Step 4: Optional - Create Chat History Table

If you want to save chat history in the database:

```sql
-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  response TEXT NOT NULL,
  is_user_message BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own messages
CREATE POLICY "Users can view own chat messages"
  ON chat_messages
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own messages
CREATE POLICY "Users can insert own chat messages"
  ON chat_messages
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own messages
CREATE POLICY "Users can delete own chat messages"
  ON chat_messages
  FOR DELETE
  USING (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX idx_chat_messages_user_created 
  ON chat_messages(user_id, created_at DESC);
```

Run this SQL in your Supabase SQL Editor (Dashboard → SQL Editor → New Query).

## Step 5: Test the Chatbot

1. Run your Flutter app:
   ```powershell
   flutter run
   ```

2. Login as a farmer user

3. Click on "Farming Tips" card on the home screen

4. Try asking questions like:
   - "What is the best time to plant rice?"
   - "How do I treat Brown Spot disease?"
   - "What fertilizer should I use for paddy fields?"
   - "How much water does rice need?"

## Troubleshooting

### Error: "Failed to get response"

**Check:**
1. Edge function is deployed: `supabase functions list`
2. API key is set: `supabase secrets list`
3. Your Supabase project URL is correct in `lib/config/supabase_config.dart`

### Error: "Google AI API error: 401"

**Solution:**
The API key might be invalid. Verify it's correct:
```powershell
supabase secrets set GOOGLE_AI_API_KEY=AlzaSyDoVYmdDUiYfNnO6gzDHvF0DSleX8qH_yM
```

### Error: "Network request failed"

**Check:**
1. Internet connection is working
2. Supabase project is active
3. Edge Functions are enabled in your Supabase project (Settings → Edge Functions)

## Features

### Current Features:
- ✅ Real-time AI responses using Google Gemini
- ✅ Rice farming expertise (diseases, pests, cultivation)
- ✅ Conversation history (last 10 messages for context)
- ✅ Beautiful chat UI with typing indicators
- ✅ Welcome message with feature overview
- ✅ Error handling and retry capability
- ✅ Clear chat functionality

### Optional Features (already coded):
- Chat history persistence in database
- Load previous conversations
- Clear chat history

## API Usage & Costs

### Google AI Studio (Gemini Pro):
- **Free Tier:** 60 requests per minute
- **Cost:** Free for moderate usage
- **Rate Limit:** Built-in rate limiting

### Supabase Edge Functions:
- **Free Tier:** 500,000 requests/month
- **Execution Time:** Max 150 seconds per request
- **Cost:** Free for most usage

## Security Notes

1. ✅ API key is stored as Supabase secret (not in code)
2. ✅ CORS headers configured for security
3. ✅ User authentication required (RoleGuard)
4. ✅ Input validation on messages
5. ✅ Content safety filters enabled

## Next Steps

Consider adding:
1. Voice input for questions
2. Image upload for visual disease diagnosis
3. Multi-language support
4. Crop-specific tips based on user's selected variety
5. Integration with disease detection results

## Support

If you encounter issues:
1. Check Supabase Edge Function logs:
   ```powershell
   supabase functions logs chat-rice-tips
   ```

2. Check Flutter console for errors

3. Verify API key is valid at: https://aistudio.google.com/apikey

## Summary

You now have a fully functional AI chatbot for rice farming tips! The chatbot:
- Uses Google's Gemini AI for intelligent responses
- Runs serverless on Supabase Edge Functions
- Maintains conversation context
- Provides expert rice farming advice
- Has a beautiful, user-friendly interface

Enjoy helping your farmers with AI-powered guidance! 🌾🤖
