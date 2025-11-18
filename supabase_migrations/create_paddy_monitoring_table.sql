-- Create paddy_monitoring table to track farmers' paddy growth
-- This table stores paddy variety selection, planting date, and harvest tracking

CREATE TABLE IF NOT EXISTS public.paddy_monitoring (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  variety VARCHAR(50) NOT NULL,
  planting_date DATE NOT NULL,
  estimated_harvest_days_min INTEGER NOT NULL,
  estimated_harvest_days_max INTEGER NOT NULL,
  status VARCHAR(20) DEFAULT 'active',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add comments to document the table and columns
COMMENT ON TABLE public.paddy_monitoring IS 'Tracks paddy growth monitoring for farmers including variety selection and planting dates';
COMMENT ON COLUMN public.paddy_monitoring.user_id IS 'Reference to the farmer (auth.users)';
COMMENT ON COLUMN public.paddy_monitoring.variety IS 'Paddy variety name (e.g., MR 297, MR 220)';
COMMENT ON COLUMN public.paddy_monitoring.planting_date IS 'Date when the paddy was planted';
COMMENT ON COLUMN public.paddy_monitoring.estimated_harvest_days_min IS 'Minimum days to harvest for this variety';
COMMENT ON COLUMN public.paddy_monitoring.estimated_harvest_days_max IS 'Maximum days to harvest for this variety';
COMMENT ON COLUMN public.paddy_monitoring.status IS 'Monitoring status: active, harvested, cancelled';
COMMENT ON COLUMN public.paddy_monitoring.notes IS 'Optional notes about the crop';

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_paddy_monitoring_user_id 
ON public.paddy_monitoring(user_id);

CREATE INDEX IF NOT EXISTS idx_paddy_monitoring_status 
ON public.paddy_monitoring(status);

CREATE INDEX IF NOT EXISTS idx_paddy_monitoring_planting_date 
ON public.paddy_monitoring(planting_date DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.paddy_monitoring ENABLE ROW LEVEL SECURITY;

-- Create RLS policies

-- Policy: Users can view their own monitoring records
CREATE POLICY "Users can view own paddy monitoring"
ON public.paddy_monitoring
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own monitoring records
CREATE POLICY "Users can insert own paddy monitoring"
ON public.paddy_monitoring
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own monitoring records
CREATE POLICY "Users can update own paddy monitoring"
ON public.paddy_monitoring
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own monitoring records
CREATE POLICY "Users can delete own paddy monitoring"
ON public.paddy_monitoring
FOR DELETE
USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_paddy_monitoring_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER set_paddy_monitoring_updated_at
BEFORE UPDATE ON public.paddy_monitoring
FOR EACH ROW
EXECUTE FUNCTION update_paddy_monitoring_updated_at();
