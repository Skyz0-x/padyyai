-- Create field_records table to track farming activities and field management
-- Auto-deletes records older than 30 days

CREATE TABLE IF NOT EXISTS public.field_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  record_type VARCHAR(50) NOT NULL, -- 'irrigation', 'fertilizer', 'pesticide', 'harvest', 'planting', 'other'
  title VARCHAR(255) NOT NULL,
  description TEXT,
  area_size DECIMAL(10, 2), -- in hectares or acres
  quantity DECIMAL(10, 2), -- amount of fertilizer/pesticide used
  unit VARCHAR(50), -- kg, liters, bags, etc.
  cost DECIMAL(10, 2),
  location VARCHAR(255),
  weather_condition VARCHAR(100),
  notes TEXT,
  record_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete for 30-day auto cleanup
);

-- Add comments
COMMENT ON TABLE public.field_records IS 'Tracks daily farming activities and field management records. Auto-deletes after 30 days.';
COMMENT ON COLUMN public.field_records.user_id IS 'Reference to the farmer (auth.users)';
COMMENT ON COLUMN public.field_records.record_type IS 'Type of activity: irrigation, fertilizer, pesticide, harvest, planting, other';
COMMENT ON COLUMN public.field_records.title IS 'Brief title/name of the activity';
COMMENT ON COLUMN public.field_records.description IS 'Detailed description of what was done';
COMMENT ON COLUMN public.field_records.area_size IS 'Size of area worked on';
COMMENT ON COLUMN public.field_records.quantity IS 'Amount of materials used';
COMMENT ON COLUMN public.field_records.cost IS 'Cost incurred for this activity';
COMMENT ON COLUMN public.field_records.record_date IS 'Date when the activity was performed';
COMMENT ON COLUMN public.field_records.deleted_at IS 'Timestamp when record was soft-deleted (30-day cleanup)';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_field_records_user_id ON public.field_records(user_id);
CREATE INDEX IF NOT EXISTS idx_field_records_record_type ON public.field_records(record_type);
CREATE INDEX IF NOT EXISTS idx_field_records_record_date ON public.field_records(record_date DESC);
CREATE INDEX IF NOT EXISTS idx_field_records_deleted_at ON public.field_records(deleted_at) WHERE deleted_at IS NULL;

-- Enable RLS for field_records
ALTER TABLE public.field_records ENABLE ROW LEVEL SECURITY;

-- RLS Policies for field_records
CREATE POLICY "Users can view own field records"
ON public.field_records FOR SELECT
USING (auth.uid() = user_id AND deleted_at IS NULL);

CREATE POLICY "Users can insert own field records"
ON public.field_records FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own field records"
ON public.field_records FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own field records"
ON public.field_records FOR DELETE
USING (auth.uid() = user_id);

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_field_records_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
CREATE TRIGGER set_field_records_updated_at
BEFORE UPDATE ON public.field_records
FOR EACH ROW
EXECUTE FUNCTION update_field_records_updated_at();

-- Function to auto-delete field records older than 30 days
CREATE OR REPLACE FUNCTION delete_old_field_records()
RETURNS void AS $$
BEGIN
  DELETE FROM public.field_records
  WHERE record_date < CURRENT_DATE - INTERVAL '30 days';
  
  RAISE NOTICE 'Deleted field records older than 30 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule automatic cleanup (requires pg_cron extension)
-- Note: You need to enable pg_cron extension in Supabase dashboard first
-- Then run this in SQL editor:
-- SELECT cron.schedule('delete-old-field-records', '0 0 * * *', 'SELECT delete_old_field_records()');

-- Alternative: Use Edge Function with scheduled trigger for auto-cleanup
-- Or manually call delete_old_field_records() periodically
