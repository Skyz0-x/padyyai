# Paddy Monitoring Database Setup

## Overview
This guide explains how to set up the database table for the Paddy Growth Monitoring feature.

## Database Table Created
- **Table Name**: `paddy_monitoring`
- **Purpose**: Store farmers' paddy variety selection, planting dates, and track growth progress

## Table Schema

### Columns
- `id` (UUID): Primary key
- `user_id` (UUID): Reference to authenticated user
- `variety` (VARCHAR): Paddy variety name (MR 297, MR 220, etc.)
- `planting_date` (DATE): When the paddy was planted
- `estimated_harvest_days_min` (INTEGER): Minimum days to harvest
- `estimated_harvest_days_max` (INTEGER): Maximum days to harvest
- `status` (VARCHAR): active, harvested, or cancelled
- `notes` (TEXT): Optional farmer notes
- `created_at` (TIMESTAMP): Record creation time
- `updated_at` (TIMESTAMP): Last update time

## Setup Instructions

### Option 1: Supabase Dashboard (Recommended)
1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Create a new query
4. Copy the contents of `supabase_migrations/create_paddy_monitoring_table.sql`
5. Paste and run the SQL script
6. Verify the table was created in **Table Editor**

### Option 2: Supabase CLI
```bash
# Navigate to project root
cd c:\Flutter_project\padyyai

# Run the migration
supabase db push
```

## Security Features

### Row Level Security (RLS)
The table has RLS enabled with the following policies:
- ✅ Users can only view their own monitoring records
- ✅ Users can only insert records for themselves
- ✅ Users can only update their own records
- ✅ Users can only delete their own records

### Automatic Triggers
- `updated_at` field automatically updates on every record modification

## How It Works in the App

### Data Flow
1. **User selects paddy variety** → Data saved to state
2. **User selects planting date** → Data saved to database
3. **App loads** → Previous data automatically restored
4. **User changes variety/date** → Database updated automatically

### Features
- ✅ Automatic save when variety + planting date are both selected
- ✅ Auto-load saved data on app start
- ✅ Success notification when data is saved
- ✅ Support for multiple monitoring records (history)
- ✅ Mark crops as harvested
- ✅ Add notes to each crop

## API Methods Available

### `PaddyMonitoringService` Methods
```dart
// Save or update monitoring data
savePaddyMonitoring(variety, plantingDate, min, max, notes)

// Get active monitoring record
getActivePaddyMonitoring()

// Get all records (including history)
getAllPaddyMonitoring()

// Mark as harvested
markAsHarvested(recordId)

// Delete record
deletePaddyMonitoring(recordId)

// Update notes
updateNotes(recordId, notes)
```

## Verification

After running the migration, verify:
1. Table `paddy_monitoring` exists in Supabase
2. RLS policies are active (4 policies)
3. Indexes are created (3 indexes)
4. Trigger function exists

## Troubleshooting

### Issue: "relation already exists"
- The table was already created. Safe to ignore.

### Issue: "permission denied"
- Check RLS policies are properly configured
- Ensure user is authenticated

### Issue: Data not saving
1. Check Supabase project URL and keys in `.env`
2. Verify user is logged in
3. Check console logs for error messages

## Next Steps

1. Run the SQL migration in Supabase
2. Test the app:
   - Select a paddy variety
   - Choose a planting date
   - Verify green success notification appears
   - Restart app and confirm data is restored
3. Check Supabase Table Editor to see saved records
