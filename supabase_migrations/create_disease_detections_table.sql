-- Create disease_detections table to store AI-detected diseases
-- Tracks disease detection results from image analysis

CREATE TABLE IF NOT EXISTS public.disease_detections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  disease_name VARCHAR(255) NOT NULL,
  confidence DECIMAL(5, 2) NOT NULL, -- AI confidence percentage (0-100)
  image_url TEXT,
  severity VARCHAR(50), -- 'low', 'medium', 'high', 'critical', 'healthy'
  location VARCHAR(255),
  crop_variety VARCHAR(100),
  treatment_recommended TEXT,
  notes TEXT,
  detection_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add comments for documentation
COMMENT ON TABLE public.disease_detections IS 'Stores AI-detected diseases from crop image analysis';
COMMENT ON COLUMN public.disease_detections.user_id IS 'Reference to the farmer (auth.users)';
COMMENT ON COLUMN public.disease_detections.disease_name IS 'Name of detected disease or "Healthy"';
COMMENT ON COLUMN public.disease_detections.confidence IS 'AI model confidence percentage (0-100)';
COMMENT ON COLUMN public.disease_detections.image_url IS 'URL to the analyzed image in Supabase storage';
COMMENT ON COLUMN public.disease_detections.severity IS 'Disease severity level based on confidence';
COMMENT ON COLUMN public.disease_detections.location IS 'Field location where image was taken';
COMMENT ON COLUMN public.disease_detections.crop_variety IS 'Paddy variety being monitored';
COMMENT ON COLUMN public.disease_detections.treatment_recommended IS 'Recommended treatment or action';
COMMENT ON COLUMN public.disease_detections.detection_date IS 'When the detection was performed';

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_disease_detections_user_id 
ON public.disease_detections(user_id);

CREATE INDEX IF NOT EXISTS idx_disease_detections_disease_name 
ON public.disease_detections(disease_name);

CREATE INDEX IF NOT EXISTS idx_disease_detections_date 
ON public.disease_detections(detection_date DESC);

CREATE INDEX IF NOT EXISTS idx_disease_detections_severity 
ON public.disease_detections(severity);

-- Enable Row Level Security (RLS)
ALTER TABLE public.disease_detections ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own disease detection records

-- Policy: Users can view their own disease detections
CREATE POLICY "Users can view own disease detections"
ON public.disease_detections FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own disease detections
CREATE POLICY "Users can insert own disease detections"
ON public.disease_detections FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own disease detections
CREATE POLICY "Users can update own disease detections"
ON public.disease_detections FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own disease detections
CREATE POLICY "Users can delete own disease detections"
ON public.disease_detections FOR DELETE
USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_disease_detections_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER set_disease_detections_updated_at
BEFORE UPDATE ON public.disease_detections
FOR EACH ROW
EXECUTE FUNCTION update_disease_detections_updated_at();

-- Optional: Create a view for disease statistics
CREATE OR REPLACE VIEW disease_detection_stats AS
SELECT 
  user_id,
  COUNT(*) as total_detections,
  COUNT(CASE WHEN LOWER(disease_name) LIKE '%healthy%' THEN 1 END) as healthy_count,
  COUNT(CASE WHEN LOWER(disease_name) NOT LIKE '%healthy%' THEN 1 END) as disease_count,
  ROUND(AVG(confidence), 2) as avg_confidence,
  MAX(detection_date) as last_detection_date
FROM public.disease_detections
GROUP BY user_id;

-- Grant access to the view
GRANT SELECT ON disease_detection_stats TO authenticated;

-- Apply RLS to the view
ALTER VIEW disease_detection_stats SET (security_invoker = true);
