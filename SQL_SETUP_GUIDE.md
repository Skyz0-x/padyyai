# Database Setup - Quick Reference

## SQL Files Created

### 1. Field Records Table
**File**: `supabase_migrations/create_field_records_table.sql`

**Purpose**: Track daily farming activities (irrigation, fertilizer, pesticide, harvest, planting)

**Features**:
- ✅ Auto-deletes records older than 30 days
- ✅ Tracks costs, quantities, locations
- ✅ Soft delete with `deleted_at`
- ✅ Row Level Security enabled
- ✅ 4 RLS policies (view, insert, update, delete)
- ✅ 4 indexes for performance
- ✅ Auto-update `updated_at` trigger

**Key Columns**:
- `record_type`: irrigation, fertilizer, pesticide, harvest, planting, other
- `title`, `description`: Activity details
- `area_size`, `quantity`, `unit`: Measurements
- `cost`: Activity cost (DECIMAL)
- `record_date`: When activity was performed
- `deleted_at`: Soft delete timestamp

---

### 2. Disease Detections Table
**File**: `supabase_migrations/create_disease_detections_table.sql`

**Purpose**: Store AI disease detection results from image analysis

**Features**:
- ✅ Stores disease name, confidence, severity
- ✅ Links to images in Supabase storage
- ✅ Row Level Security enabled
- ✅ 4 RLS policies (view, insert, update, delete)
- ✅ 4 indexes for performance
- ✅ Auto-update `updated_at` trigger
- ✅ Statistics view included

**Key Columns**:
- `disease_name`: Name of detected disease or "Healthy"
- `confidence`: AI confidence (0-100%)
- `image_url`: Link to analyzed image
- `severity`: low, medium, high, critical, healthy
- `crop_variety`: Paddy variety (MR 297, MR 220, etc.)
- `treatment_recommended`: Treatment advice
- `detection_date`: When detected

**Bonus**: Includes `disease_detection_stats` view for quick statistics

---

## Setup Instructions

### Step 1: Run Field Records SQL
1. Open Supabase Dashboard
2. Go to **SQL Editor**
3. Copy content from `supabase_migrations/create_field_records_table.sql`
4. Paste and click **RUN**
5. Verify table created in **Table Editor**

### Step 2: Run Disease Detections SQL
1. Stay in **SQL Editor**
2. Copy content from `supabase_migrations/create_disease_detections_table.sql`
3. Paste and click **RUN**
4. Verify table created in **Table Editor**

### Step 3: Enable Auto-Cleanup (Optional - Field Records Only)
For automatic 30-day cleanup of field records:

```sql
-- Enable pg_cron extension first (Database → Extensions)
-- Then run this:
SELECT cron.schedule(
  'delete-old-field-records',
  '0 0 * * *',  -- Daily at midnight
  'SELECT delete_old_field_records()'
);
```

---

## Verification Checklist

After running both SQL files, verify:

### Field Records Table
- ✅ Table `field_records` exists
- ✅ 4 RLS policies active
- ✅ 4 indexes created
- ✅ Function `delete_old_field_records()` exists
- ✅ Trigger `set_field_records_updated_at` exists

### Disease Detections Table
- ✅ Table `disease_detections` exists
- ✅ 4 RLS policies active
- ✅ 4 indexes created
- ✅ View `disease_detection_stats` exists
- ✅ Trigger `set_disease_detections_updated_at` exists

---

## Service Files

### FieldRecordsService
**Location**: `lib/services/field_records_service.dart`

**Status**: ✅ No errors - Ready to use

**Methods**:
```dart
addFieldRecord()        // Add new field activity
getFieldRecords()       // Get records with filters
getFieldRecordsStats()  // Get statistics
updateFieldRecord()     // Update existing record
deleteFieldRecord()     // Soft delete
cleanupOldRecords()     // Manual cleanup trigger
```

### DiseaseRecordsService
**Status**: ⚠️ Not created yet (if needed)

You can create it based on the disease_detections table structure.

---

## Quick Test

After setup, test with:

```dart
// Test Field Records
await FieldRecordsService().addFieldRecord(
  recordType: 'irrigation',
  title: 'Test Irrigation',
  cost: 100.00,
);

// Check stats
final stats = await FieldRecordsService().getFieldRecordsStats();
print(stats); // Should show 1 record, cost 100
```

---

## Troubleshooting

### "relation already exists"
- Table was already created. Safe to ignore or drop and recreate.

### "permission denied for schema public"
- Check you're using the correct Supabase project
- Verify you have admin access

### RLS blocking access
- Ensure user is authenticated
- Check `auth.uid()` matches `user_id` in records
- Review RLS policies in Supabase dashboard

### Auto-delete not working
- Enable pg_cron extension in Supabase
- Check cron schedule is created
- Manually test: `SELECT delete_old_field_records();`

---

## Data Retention

- **Field Records**: Auto-deleted after 30 days
- **Disease Detections**: Kept permanently for analysis

---

## Notes

- Both tables use UUID primary keys
- Both enforce data isolation through RLS
- Timestamps are in UTC with time zone
- Costs stored as DECIMAL for accuracy
- Indexes optimize common queries (by user, date, type)
