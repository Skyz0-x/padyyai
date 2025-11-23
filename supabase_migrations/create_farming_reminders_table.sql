-- Create farming_reminders table for calendar and notifications
CREATE TABLE IF NOT EXISTS farming_reminders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  reminder_type TEXT NOT NULL CHECK (reminder_type IN ('fertilization', 'irrigation', 'pest_control', 'planting', 'harvest', 'field_inspection', 'weather_alert', 'custom')),
  scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  is_recurring BOOLEAN DEFAULT FALSE,
  recurrence_pattern TEXT CHECK (recurrence_pattern IN ('daily', 'weekly', 'biweekly', 'monthly', 'seasonal')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  field_id UUID REFERENCES field_records(id) ON DELETE SET NULL,
  notification_sent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_farming_reminders_user_id ON farming_reminders(user_id);
CREATE INDEX idx_farming_reminders_scheduled_date ON farming_reminders(scheduled_date);
CREATE INDEX idx_farming_reminders_type ON farming_reminders(reminder_type);
CREATE INDEX idx_farming_reminders_completed ON farming_reminders(is_completed);

-- Enable Row Level Security
ALTER TABLE farming_reminders ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own reminders"
  ON farming_reminders FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own reminders"
  ON farming_reminders FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reminders"
  ON farming_reminders FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reminders"
  ON farming_reminders FOR DELETE
  USING (auth.uid() = user_id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_farming_reminders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER farming_reminders_updated_at
  BEFORE UPDATE ON farming_reminders
  FOR EACH ROW
  EXECUTE FUNCTION update_farming_reminders_updated_at();

-- Insert default reminders for optimal planting schedule (Malaysia rice farming calendar)
-- This is just a template - actual dates should be calculated based on user's location and weather
COMMENT ON TABLE farming_reminders IS 'Stores farming calendar events and reminder notifications for users';
