# Auto-Delete Old Images Setup Guide (Option B: pg_cron)

## Overview
This guide will help you set up automatic deletion of disease detection images older than 7 days using PostgreSQL's pg_cron extension in Supabase.

## Step-by-Step Instructions

### Step 1: Enable pg_cron Extension

1. **Go to your Supabase Dashboard**
   - URL: https://app.supabase.com/project/YOUR_PROJECT_ID

2. **Navigate to Database > Extensions**
   - Click on **"Database"** in the left sidebar
   - Click on **"Extensions"** tab

3. **Enable pg_cron**
   - Search for `pg_cron` in the search box
   - Find **"pg_cron"** in the list
   - Click the **toggle switch** or **"Enable"** button
   - Wait for confirmation message

### Step 2: Create the Cleanup Function

1. **Go to SQL Editor**
   - Click **"SQL Editor"** in the left sidebar
   - Click **"New query"**

2. **Copy and paste this SQL code:**

```sql
-- ============================================
-- STEP 2A: Create the cleanup function
-- ============================================

CREATE OR REPLACE FUNCTION cleanup_old_disease_images()
RETURNS TABLE(
  action_taken TEXT,
  records_processed INT,
  images_marked INT
) AS $$
DECLARE
  old_record RECORD;
  image_path TEXT;
  total_records INT := 0;
  images_nullified INT := 0;
BEGIN
  -- Log the start of cleanup
  RAISE NOTICE 'Starting cleanup of disease images older than 7 days...';
  
  -- Find and update records older than 7 days with images
  FOR old_record IN
    SELECT id, image_url, disease_name, detection_date
    FROM disease_detections
    WHERE image_url IS NOT NULL
      AND detection_date < NOW() - INTERVAL '7 days'
    ORDER BY detection_date ASC
  LOOP
    total_records := total_records + 1;
    
    -- Extract the file path from the URL
    -- URL format: https://xxx.supabase.co/storage/v1/object/public/disease-images/disease_detections/filename.jpg
    image_path := regexp_replace(old_record.image_url, '^.*/disease-images/', '');
    
    -- Set image_url to NULL (actual file deletion will be done by separate process)
    UPDATE disease_detections
    SET image_url = NULL
    WHERE id = old_record.id;
    
    images_nullified := images_nullified + 1;
    
    RAISE NOTICE 'Record ID: % | Disease: % | Age: % days | Image marked: %', 
      old_record.id, 
      old_record.disease_name,
      EXTRACT(DAY FROM (NOW() - old_record.detection_date)),
      image_path;
  END LOOP;
  
  -- Return summary
  RETURN QUERY SELECT 
    'Cleanup completed'::TEXT,
    total_records,
    images_nullified;
    
  RAISE NOTICE 'Cleanup completed. Processed: %, Nullified: %', total_records, images_nullified;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment to the function
COMMENT ON FUNCTION cleanup_old_disease_images() IS 
'Removes image URLs from disease_detections records older than 7 days. Runs daily via pg_cron.';
```

3. **Click "Run" or press F5**
4. **Verify:** You should see "Success. No rows returned"

### Step 3: Create Storage Cleanup Function

Since PostgreSQL functions cannot directly delete from Supabase Storage, we need a helper function that will be called by an Edge Function or application code.

```sql
-- ============================================
-- STEP 3: Create helper function to list old images
-- ============================================

CREATE OR REPLACE FUNCTION get_old_image_paths()
RETURNS TABLE(
  image_url TEXT,
  file_path TEXT,
  detection_date TIMESTAMP WITH TIME ZONE,
  age_days NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    dd.image_url,
    regexp_replace(dd.image_url, '^.*/disease-images/', '') AS file_path,
    dd.detection_date,
    EXTRACT(DAY FROM (NOW() - dd.detection_date)) AS age_days
  FROM disease_detections dd
  WHERE dd.image_url IS NOT NULL
    AND dd.detection_date < NOW() - INTERVAL '7 days'
  ORDER BY dd.detection_date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_old_image_paths() IS 
'Returns list of image paths that are older than 7 days and need to be deleted from storage.';
```

### Step 4: Schedule the Cleanup Function

1. **In the same SQL Editor, add this code:**

```sql
-- ============================================
-- STEP 4: Schedule daily cleanup at 2 AM
-- ============================================

-- First, remove any existing schedule with the same name
SELECT cron.unschedule('cleanup-old-disease-images');

-- Schedule the cleanup to run daily at 2:00 AM
SELECT cron.schedule(
  'cleanup-old-disease-images',           -- Job name
  '0 2 * * *',                            -- Cron schedule (2 AM daily)
  $$SELECT cleanup_old_disease_images()$$ -- Function to execute
);
```

2. **Click "Run"**
3. **Verify:** You should see the schedule confirmation

### Step 5: Verify the Schedule

Check if the job is scheduled correctly:

```sql
-- ============================================
-- STEP 5: Verify scheduled jobs
-- ============================================

-- View all scheduled cron jobs
SELECT 
  jobid,
  schedule,
  command,
  nodename,
  nodeport,
  database,
  username,
  active,
  jobname
FROM cron.job
WHERE jobname = 'cleanup-old-disease-images';
```

**Expected result:** You should see one row with:
- **jobname:** cleanup-old-disease-images
- **schedule:** 0 2 * * *
- **active:** true

### Step 6: Test the Function Manually

Before waiting for the scheduled run, test it manually:

```sql
-- ============================================
-- STEP 6A: Check what will be cleaned up (DRY RUN)
-- ============================================

-- See which images would be affected
SELECT * FROM get_old_image_paths();

-- ============================================
-- STEP 6B: Run the cleanup function manually
-- ============================================

SELECT * FROM cleanup_old_disease_images();
```

**What to expect:**
- If you have detections older than 7 days, they will be processed
- If not, you'll see: `action_taken: "Cleanup completed", records_processed: 0, images_marked: 0`

### Step 7: Create Storage Deletion Edge Function

Since pg_cron cannot directly delete files from Supabase Storage, you need an Edge Function for actual file deletion.

1. **Install Supabase CLI** (if not already installed):
```powershell
npm install -g supabase
```

2. **Initialize Supabase locally** (in your project folder):
```powershell
cd C:\Flutter_project\padyyai
supabase init
```

3. **Create Edge Function:**
```powershell
supabase functions new delete-old-images
```

4. **Edit the file:** `supabase\functions\delete-old-images\index.ts`

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    // Create Supabase client with service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    console.log('🧹 Starting storage cleanup...')

    // Get list of old image paths from database
    const { data: oldPaths, error: dbError } = await supabaseClient
      .rpc('get_old_image_paths')

    if (dbError) {
      console.error('Database error:', dbError)
      throw dbError
    }

    if (!oldPaths || oldPaths.length === 0) {
      console.log('✅ No old images to delete')
      return new Response(
        JSON.stringify({ 
          message: 'No old images found',
          deleted: 0,
          timestamp: new Date().toISOString()
        }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`📋 Found ${oldPaths.length} old images to delete`)

    // Delete files from storage
    let deletedCount = 0
    let errors = []

    for (const item of oldPaths) {
      try {
        const { error: deleteError } = await supabaseClient
          .storage
          .from('disease-images')
          .remove([item.file_path])

        if (deleteError) {
          console.error(`❌ Failed to delete ${item.file_path}:`, deleteError)
          errors.push({ path: item.file_path, error: deleteError.message })
        } else {
          console.log(`✅ Deleted: ${item.file_path} (${item.age_days} days old)`)
          deletedCount++
        }
      } catch (err) {
        console.error(`❌ Error deleting ${item.file_path}:`, err)
        errors.push({ path: item.file_path, error: err.message })
      }
    }

    // Now run the database cleanup to nullify image URLs
    const { data: cleanupResult, error: cleanupError } = await supabaseClient
      .rpc('cleanup_old_disease_images')

    if (cleanupError) {
      console.error('Cleanup function error:', cleanupError)
    }

    console.log(`🎉 Cleanup complete: ${deletedCount}/${oldPaths.length} deleted`)

    return new Response(
      JSON.stringify({
        message: 'Storage cleanup completed',
        totalFound: oldPaths.length,
        deleted: deletedCount,
        failed: errors.length,
        errors: errors.length > 0 ? errors : undefined,
        timestamp: new Date().toISOString()
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('❌ Cleanup error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }
})
```

5. **Deploy the Edge Function:**
```powershell
# Login to Supabase (if not already)
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy the function
supabase functions deploy delete-old-images
```

6. **Set up secrets:**
```powershell
supabase secrets set SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### Step 8: Schedule Edge Function to Run After pg_cron

Update the cron schedule to call the Edge Function:

```sql
-- ============================================
-- STEP 8: Update schedule to include Edge Function call
-- ============================================

-- Unschedule the old job
SELECT cron.unschedule('cleanup-old-disease-images');

-- Create new schedule that will be triggered at 2:05 AM (5 minutes after database cleanup)
-- Note: You'll need to call the Edge Function from your application or use http extension
SELECT cron.schedule(
  'cleanup-old-disease-images',
  '0 2 * * *',
  $$SELECT cleanup_old_disease_images()$$
);
```

### Step 9: Manual Trigger Option

Create a simple way to manually trigger cleanup:

```sql
-- ============================================
-- STEP 9: Create manual trigger functions
-- ============================================

-- View job history
CREATE OR REPLACE FUNCTION view_cleanup_history()
RETURNS TABLE(
  run_time TIMESTAMP WITH TIME ZONE,
  status TEXT,
  return_message TEXT,
  duration INTERVAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    start_time AS run_time,
    status::TEXT,
    return_message::TEXT,
    end_time - start_time AS duration
  FROM cron.job_run_details
  WHERE jobid = (
    SELECT jobid FROM cron.job WHERE jobname = 'cleanup-old-disease-images'
  )
  ORDER BY start_time DESC
  LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- Manual trigger (for testing)
COMMENT ON FUNCTION cleanup_old_disease_images() IS 
'To manually trigger: SELECT * FROM cleanup_old_disease_images();';
```

## Monitoring and Verification

### Check Job Status

```sql
-- View scheduled jobs
SELECT * FROM cron.job WHERE jobname LIKE '%cleanup%';

-- View recent job runs
SELECT * FROM view_cleanup_history();

-- View detailed job history
SELECT 
  start_time,
  end_time,
  status,
  return_message,
  end_time - start_time as duration
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'cleanup-old-disease-images')
ORDER BY start_time DESC
LIMIT 10;
```

### Check What Will Be Cleaned

```sql
-- See current images that would be deleted
SELECT 
  disease_name,
  detection_date,
  EXTRACT(DAY FROM (NOW() - detection_date)) as age_days,
  image_url
FROM disease_detections
WHERE image_url IS NOT NULL
  AND detection_date < NOW() - INTERVAL '7 days'
ORDER BY detection_date ASC;

-- Count by age
SELECT 
  EXTRACT(DAY FROM (NOW() - detection_date))::INT as age_days,
  COUNT(*) as count
FROM disease_detections
WHERE image_url IS NOT NULL
GROUP BY age_days
HAVING EXTRACT(DAY FROM (NOW() - detection_date)) >= 7
ORDER BY age_days;
```

### Test Edge Function Manually

```powershell
# Call the Edge Function directly
curl -X POST https://YOUR_PROJECT_ID.supabase.co/functions/v1/delete-old-images `
  -H "Authorization: Bearer YOUR_ANON_KEY" `
  -H "Content-Type: application/json"
```

## Automated Workflow

Here's how it works automatically:

```
Daily at 2:00 AM (Server Time):
  ├─ pg_cron triggers
  ├─ cleanup_old_disease_images() runs
  │  ├─ Finds records > 7 days old
  │  ├─ Sets image_url to NULL
  │  └─ Logs details
  │
  ├─ Edge Function called (manual trigger for now)
  │  ├─ Calls get_old_image_paths()
  │  ├─ Deletes files from storage
  │  └─ Returns summary
  │
  └─ Cleanup complete ✅
```

## Troubleshooting

### pg_cron Not Appearing

**Issue:** Cannot find pg_cron in extensions
**Solution:** pg_cron is only available in Supabase Pro and Team plans. Free tier doesn't have it.
**Alternative:** Use Edge Functions with external cron service (GitHub Actions, cron-job.org)

### Job Not Running

1. **Check if job is active:**
```sql
SELECT * FROM cron.job WHERE jobname = 'cleanup-old-disease-images';
```

2. **Check job run details:**
```sql
SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 5;
```

3. **Manually trigger to test:**
```sql
SELECT * FROM cleanup_old_disease_images();
```

### Edge Function Fails

1. **Check function logs:**
```powershell
supabase functions logs delete-old-images
```

2. **Verify secrets are set:**
```powershell
supabase secrets list
```

3. **Test locally:**
```powershell
supabase functions serve delete-old-images
```

## Alternative: Simpler Approach Without Edge Function

If you don't want to set up Edge Functions, you can use this simpler approach where images are just marked in the database:

```sql
-- Keep it simple: Just nullify old image URLs
-- You can manually delete from storage UI periodically

SELECT cron.schedule(
  'cleanup-old-disease-images',
  '0 2 * * *',
  $$
    UPDATE disease_detections 
    SET image_url = NULL 
    WHERE image_url IS NOT NULL 
      AND detection_date < NOW() - INTERVAL '7 days'
  $$
);
```

Then manually clean storage:
1. Go to **Storage > disease-images**
2. Sort by date
3. Delete old files periodically

## Summary Checklist

- [ ] Enable pg_cron extension
- [ ] Create cleanup_old_disease_images() function
- [ ] Create get_old_image_paths() helper function
- [ ] Schedule daily cron job at 2 AM
- [ ] Verify schedule is active
- [ ] Test cleanup function manually
- [ ] Create and deploy Edge Function (optional)
- [ ] Set up Edge Function secrets (optional)
- [ ] Test complete workflow
- [ ] Monitor first automated run

## Quick Reference

**Manual cleanup:**
```sql
SELECT * FROM cleanup_old_disease_images();
```

**View schedule:**
```sql
SELECT * FROM cron.job;
```

**View history:**
```sql
SELECT * FROM view_cleanup_history();
```

**Unschedule:**
```sql
SELECT cron.unschedule('cleanup-old-disease-images');
```

**Re-schedule:**
```sql
SELECT cron.schedule('cleanup-old-disease-images', '0 2 * * *', $$SELECT cleanup_old_disease_images()$$);
```
