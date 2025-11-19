// @deno-types="https://deno.land/std@0.168.0/http/server.ts"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GOOGLE_AI_API_KEY = Deno.env.get('GOOGLE_AI_API_KEY')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ChatRequest {
  message: string
  conversationHistory?: Array<{
    role: string
    content: string
  }>
}

serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { message, conversationHistory = [] }: ChatRequest = await req.json()

    if (!message) {
      throw new Error('Message is required')
    }

    // Build conversation context with rice farming expertise
    const systemPrompt = `You are an expert rice farming assistant with deep knowledge about:
- Rice cultivation techniques and best practices
- Pest and disease management (Brown Planthopper, Rice Leafroller, Rice Yellow Stem Borer, Leaf Blast, Brown Spot, Sheath Blight, Leaf Scald)
- Fertilizer application and soil management
- Water management and irrigation
- Rice varieties and selection
- Planting and harvesting timing
- Weather considerations
- Crop rotation and field preparation
- Organic and sustainable farming methods
- Post-harvest handling and storage

Provide practical, actionable advice tailored for rice farmers. Be concise but thorough. If discussing diseases or pests, mention symptoms, prevention, and treatment methods.`

    // Build the conversation for Google AI
    const contents = [
      {
        role: "user",
        parts: [{ text: systemPrompt }]
      },
      {
        role: "model",
        parts: [{ text: "I understand. I'm ready to help with rice farming questions and provide expert advice on all aspects of rice cultivation, pest management, and farming best practices." }]
      }
    ]

    // Add conversation history
    conversationHistory.forEach(msg => {
      contents.push({
        role: msg.role === 'user' ? 'user' : 'model',
        parts: [{ text: msg.content }]
      })
    })

    // Add current message
    contents.push({
      role: "user",
      parts: [{ text: message }]
    })

    // Call Google AI API (Gemini)
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${GOOGLE_AI_API_KEY}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: contents,
          generationConfig: {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 1024,
          },
          safetySettings: [
            {
              category: "HARM_CATEGORY_HARASSMENT",
              threshold: "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              category: "HARM_CATEGORY_HATE_SPEECH",
              threshold: "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              threshold: "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              category: "HARM_CATEGORY_DANGEROUS_CONTENT",
              threshold: "BLOCK_MEDIUM_AND_ABOVE"
            }
          ]
        }),
      }
    )

    if (!response.ok) {
      const errorData = await response.text()
      console.error('Google AI API Error:', errorData)
      throw new Error(`Google AI API error: ${response.status}`)
    }

    const data = await response.json()
    
    // Extract the response text
    const aiResponse = data.candidates?.[0]?.content?.parts?.[0]?.text || 'Sorry, I could not generate a response.'

    return new Response(
      JSON.stringify({
        response: aiResponse,
        success: true
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error: unknown) {
    console.error('Error:', error)
    const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred'
    return new Response(
      JSON.stringify({
        error: errorMessage,
        success: false
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})
