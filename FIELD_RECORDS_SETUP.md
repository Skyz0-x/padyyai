# Field Records & Farming Overview Setup

## Overview
This implementation adds field records tracking and real farming statistics to the home screen.

## Database Table Created

### `field_records` Table
**Purpose**: Track daily farming activities with automatic 30-day cleanup

**Columns**:
- `id` (UUID): Primary key
- `user_id` (UUID): Reference to farmer
- `record_type` (VARCHAR): irrigation, fertilizer, pesticide, harvest, planting, other
- `title` (VARCHAR): Activity title
- `description` (TEXT): Detailed description
- `area_size` (DECIMAL): Field size worked on
- `quantity` (DECIMAL): Amount of materials used
- `unit` (VARCHAR): Unit of measurement (kg, liters, bags)
- `cost` (DECIMAL): Activity cost
- `location` (VARCHAR): Field location
- `weather_condition` (VARCHAR): Weather during activity
- `notes` (TEXT): Additional notes
- `record_date` (DATE): When activity was performed
- `created_at`, `updated_at` (TIMESTAMP): Audit fields
- `deleted_at` (TIMESTAMP): Soft delete for 30-day cleanup

## 30-Day Auto-Delete Feature

### How It Works
Field records older than 30 days are automatically deleted to keep the database clean.

### Implementation Options

#### Option 1: Supabase pg_cron (Recommended)
1. Enable pg_cron extension in Supabase dashboard
2. Run this SQL in SQL Editor:
```sql
SELECT cron.schedule(
  'delete-old-field-records',
  '0 0 * * *',  -- Run daily at midnight
  'SELECT delete_old_field_records()'
);
```

#### Option 2: Manual Cleanup
Call the cleanup function periodically:
```dart
await FieldRecordsService().cleanupOldRecords();
```

#### Option 3: Edge Function with Scheduled Trigger
Create a Supabase Edge Function that runs daily to call the cleanup function.

## Services Created

### `FieldRecordsService`
```dart
// Add field record
addFieldRecord(type, title, description, ...)

// Get records with filters
getFieldRecords(recordType, startDate, endDate)

// Get statistics
getFieldRecordsStats() // Returns total records, costs, breakdown by type

// Update record
updateFieldRecord(recordId, updates)

// Delete record (soft delete)
deleteFieldRecord(recordId)

// Manual cleanup
cleanupOldRecords()
```

## Home Screen Integration

### Farming Overview Widget
Now displays real data from field records:
- **Field Records**: Total number of activities logged
- **Total Cost**: Sum of all activity costs in RM
- **Activities**: Count of irrigation, fertilizer, and pesticide applications

### How It Works
1. On screen load, fetches data from field_records table
2. Calculates statistics in real-time
3. Shows loading indicator while fetching
4. Updates display with actual numbers

### Statistics Calculation

**Total Cost**:
```
Sum of all cost values from field_records
Displayed as: RM{amount}
```

**Activities Count**:
- Counts irrigation + fertilizer + pesticide records
- Provides overview of farming activities performed

## Setup Instructions

### Step 1: Run SQL Migration
1. Open Supabase Dashboard → SQL Editor
2. Copy content from `supabase_migrations/create_field_records_table.sql`
3. Run the script
4. Verify tables created in Table Editor

### Step 2: Enable Auto-Cleanup (Optional)
Choose one of the 30-day cleanup options above.

### Step 3: Test the Integration
1. Hot restart the app
2. Navigate to home screen
3. Check "Your Farming Overview" section
4. Numbers should show "0" initially
5. Use disease detection → scan should increase
6. Add field records → stats should update

## Database Verification

After running migration, check:
- ✅ `field_records` table exists
- ✅ RLS policies active (4 policies)
- ✅ Indexes created (4 indexes)
- ✅ Trigger for updated_at working
- ✅ `delete_old_field_records()` function exists

## Usage Examples

### Adding a Field Record
```dart
await FieldRecordsService().addFieldRecord(
  recordType: 'fertilizer',
  title: 'NPK Application',
  description: 'Applied NPK fertilizer to north field',
  areaSize: 2.5,
  quantity: 50,
  unit: 'kg',
  cost: 250.00,
  location: 'North Field Block A',
  notes: 'Applied during morning hours',
);
```

### Getting Statistics
```dart
final stats = await FieldRecordsService().getFieldRecordsStats();
print('Total Records: ${stats['total_records']}');
print('Total Cost: RM${stats['total_cost']}');
print('By Type: ${stats['by_type']}');
```

## Security Features

### Row Level Security (RLS)
- Users can only view their own records
- Users can only insert records for themselves
- Users can only update/delete their own data
- Enforced at database level

### Data Isolation
Each farmer's data is completely isolated from others through RLS policies.

## Future Enhancements

Potential features to add:
- Field records screen to view/edit history
- Export field records to CSV/PDF
- Graphical analytics dashboard
- Disease trend analysis over time
- Cost tracking and budgeting
- Field map integration
- Weather correlation with activities
- Reminder system for scheduled activities

## Troubleshooting

### Stats showing "0"
1. Ensure table is created
2. Check user is authenticated
3. Add some field records to test
4. Check console logs for errors

### Auto-delete not working
1. Verify pg_cron is enabled
2. Check cron schedule syntax
3. Manually run `SELECT delete_old_field_records()`
4. Check Supabase logs

### RLS permission errors
1. Verify user is logged in
2. Check user_id matches auth.uid()
3. Review RLS policies in Supabase

## Notes

- Field records auto-delete after 30 days to comply with data retention
- All statistics update in real-time as new data is added
- Costs are stored in decimal format for accuracy
- Offline support can be added using local database sync
- Disease detection data is handled separately through the detect screen (not stored in database)
