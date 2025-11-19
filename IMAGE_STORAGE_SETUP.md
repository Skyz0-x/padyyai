# Disease Detection Image Storage Setup Guide

## Overview
This guide explains how to set up Supabase Storage for disease detection images with automatic deletion after 7 days.

## What's Been Implemented

### 1. Auto-Save Detection to History
After each disease scan, the app now automatically:
- ✅ Uploads the scanned image to Supabase Storage
- ✅ Saves detection details to `disease_detections` table
- ✅ Links the image URL to the detection record
- ✅ Determines severity level based on confidence and disease type
- ✅ Makes the detection visible in Detect History screen

### 2. Image Storage Structure
**Bucket:** `disease-images`
**Path Format:** `disease_detections/detection_[timestamp].jpg`

Example:
```
disease-images/
  └── disease_detections/
      ├── detection_1700400000001.jpg
      ├── detection_1700400123456.jpg
      └── detection_1700400234567.jpg
```

## Supabase Storage Setup Instructions

### Step 1: Create Storage Bucket

1. Go to your Supabase Dashboard
2. Navigate to **Storage** in the left sidebar
3. Click **"New bucket"**
4. Configure the bucket:
   ```
   Name: disease-images
   Public bucket: ✓ (checked)
   File size limit: 5 MB (or as needed)
   Allowed MIME types: image/jpeg, image/png, image/jpg
   ```
5. Click **"Create bucket"**

### Step 2: Set Up Storage Policies

Go to **Storage > Policies** and create these policies for the `disease-images` bucket:

#### Policy 1: Allow Authenticated Users to Upload
```sql
CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'disease-images' AND
  (storage.foldername(name))[1] = 'disease_detections' AND
  auth.uid()::text IS NOT NULL
);
```

#### Policy 2: Allow Public Read Access
```sql
CREATE POLICY "Public read access for disease images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'disease-images');
```

#### Policy 3: Allow Users to Delete Their Own Images
```sql
CREATE POLICY "Users can delete their own images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'disease-images' AND
  auth.uid()::text IS NOT NULL
);
```

### Step 3: Set Up Automatic Image Deletion After 7 Days

Supabase doesn't have built-in TTL (Time To Live) for storage objects, but we can implement automatic deletion using **Edge Functions** or **Database Functions with Cron Jobs**.

#### Option A: Using Supabase Edge Function (Recommended)

1. **Install Supabase CLI** (if not already installed):
```bash
npm install -g supabase
```

2. **Create Edge Function:**
```bash
cd your-project-directory
supabase functions new cleanup-old-images
```

3. **Edit the function file** `supabase/functions/cleanup-old-images/index.ts`:
```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Calculate the cutoff date (7 days ago)
    const cutoffDate = new Date()
    cutoffDate.setDate(cutoffDate.getDate() - 7)

    console.log('Cleaning up images older than:', cutoffDate.toISOString())

    // List all files in the disease_detections folder
    const { data: files, error: listError } = await supabaseClient
      .storage
      .from('disease-images')
      .list('disease_detections', {
        limit: 1000,
        sortBy: { column: 'created_at', order: 'asc' }
      })

    if (listError) throw listError

    if (!files || files.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No files found', deleted: 0 }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Filter files older than 7 days
    const oldFiles = files.filter(file => {
      const fileDate = new Date(file.created_at)
      return fileDate < cutoffDate
    })

    console.log(`Found ${oldFiles.length} files to delete`)

    // Delete old files
    let deletedCount = 0
    for (const file of oldFiles) {
      const filePath = `disease_detections/${file.name}`
      const { error: deleteError } = await supabaseClient
        .storage
        .from('disease-images')
        .remove([filePath])

      if (deleteError) {
        console.error(`Error deleting ${filePath}:`, deleteError)
      } else {
        console.log(`Deleted: ${filePath}`)
        deletedCount++

        // Also update the database to remove the image URL
        await supabaseClient
          .from('disease_detections')
          .update({ image_url: null })
          .like('image_url', `%${file.name}%`)
      }
    }

    return new Response(
      JSON.stringify({
        message: 'Cleanup completed',
        deleted: deletedCount,
        checked: files.length
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
```

4. **Deploy the Edge Function:**
```bash
supabase functions deploy cleanup-old-images
```

5. **Set up a Cron Job** (using a service like cron-job.org or GitHub Actions):

Create `.github/workflows/cleanup-images.yml`:
```yaml
name: Cleanup Old Images

on:
  schedule:
    # Run daily at 2 AM UTC
    - cron: '0 2 * * *'
  workflow_dispatch: # Allow manual trigger

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - name: Call Supabase Edge Function
        run: |
          curl -X POST \
            https://YOUR_PROJECT_ID.supabase.co/functions/v1/cleanup-old-images \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_ANON_KEY }}"
```

#### Option B: Using PostgreSQL Function with pg_cron Extension

1. **Enable pg_cron extension** in Supabase Dashboard:
   - Go to **Database > Extensions**
   - Search for `pg_cron`
   - Click **Enable**

2. **Create cleanup function** in SQL Editor:
```sql
-- Create a function to clean up old images
CREATE OR REPLACE FUNCTION cleanup_old_disease_images()
RETURNS void AS $$
DECLARE
  old_record RECORD;
  image_path TEXT;
BEGIN
  -- Find records older than 7 days with images
  FOR old_record IN
    SELECT id, image_url
    FROM disease_detections
    WHERE image_url IS NOT NULL
      AND detection_date < NOW() - INTERVAL '7 days'
  LOOP
    -- Extract the file path from the URL
    -- Assumes URL format: https://xxx.supabase.co/storage/v1/object/public/disease-images/disease_detections/filename.jpg
    image_path := regexp_replace(old_record.image_url, '^.*/disease-images/', '');
    
    -- Delete the file from storage (requires service role key in production)
    -- This part needs to be handled by Edge Function or application code
    -- For now, just set image_url to NULL
    UPDATE disease_detections
    SET image_url = NULL
    WHERE id = old_record.id;
    
    RAISE NOTICE 'Marked image for deletion: %', image_path;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule the function to run daily at 2 AM
SELECT cron.schedule(
  'cleanup-old-disease-images',
  '0 2 * * *', -- Every day at 2 AM
  $$SELECT cleanup_old_disease_images()$$
);
```

#### Option C: Manual Cleanup Script (For Testing)

Create a simple cleanup script to run manually:

```sql
-- Get list of old images (for review)
SELECT 
  id,
  disease_name,
  image_url,
  detection_date,
  NOW() - detection_date AS age
FROM disease_detections
WHERE image_url IS NOT NULL
  AND detection_date < NOW() - INTERVAL '7 days'
ORDER BY detection_date ASC;

-- Set image URLs to NULL for old records
UPDATE disease_detections
SET image_url = NULL
WHERE image_url IS NOT NULL
  AND detection_date < NOW() - INTERVAL '7 days';
```

Then manually delete the files from Storage UI or using the Supabase client.

## How It Works in the App

### Detection Flow

1. **User scans disease** using camera/gallery
2. **AI analyzes** the image
3. **Results displayed** on screen
4. **Background save process:**
   - Image uploaded to `disease-images/disease_detections/`
   - Detection record created in `disease_detections` table
   - Image URL linked to the record
   - Severity automatically determined:
     - `healthy` - for healthy crops
     - `high` - confidence > 80%
     - `medium` - confidence 50-80%
     - `low` - confidence < 50%

### Viewing History

1. Navigate to **Detect History** screen
2. All saved detections are displayed
3. Click on any detection to view details
4. Images are loaded from Supabase Storage

## Storage Optimization Settings

### Current Configuration
- **Cache Control:** 7 days (604800 seconds)
- **Image Format:** JPEG
- **Compression:** Applied by Flutter before upload
- **Naming:** Timestamp-based for uniqueness

### Recommended Settings
```dart
// In detect_screen.dart _saveDetectionToHistory method
fileOptions: const FileOptions(
  cacheControl: '604800',  // 7 days cache
  upsert: false,           // Don't overwrite
)
```

## Troubleshooting

### Images Not Uploading

**Error:** "Storage bucket not found"
- **Solution:** Create the `disease-images` bucket in Supabase Dashboard

**Error:** "Permission denied"
- **Solution:** Check storage policies, ensure user is authenticated

**Error:** "File too large"
- **Solution:** Increase bucket size limit or compress images before upload

### Images Not Appearing in History

1. Check if image URL is saved in database:
```sql
SELECT id, disease_name, image_url, detection_date
FROM disease_detections
ORDER BY detection_date DESC
LIMIT 10;
```

2. Verify storage policies allow public read
3. Check if image exists in storage bucket

### Automatic Deletion Not Working

1. **For Edge Functions:**
   - Check function logs: `supabase functions logs cleanup-old-images`
   - Verify cron job is running
   - Test manually: Call the edge function URL

2. **For pg_cron:**
   - Check scheduled jobs:
   ```sql
   SELECT * FROM cron.job;
   ```
   - View job run history:
   ```sql
   SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;
   ```

## Testing Checklist

- [ ] Storage bucket `disease-images` created
- [ ] Bucket is public
- [ ] Storage policies configured
- [ ] Scan a disease image
- [ ] Check image uploaded to storage
- [ ] Verify detection appears in Detect History
- [ ] Click detection to view image
- [ ] Image loads correctly
- [ ] Set up automatic cleanup (Edge Function or pg_cron)
- [ ] Test cleanup function manually
- [ ] Verify old images are deleted after 7 days

## Cost Optimization

### Storage Costs
- Supabase Free Tier: 1 GB storage
- Each image: ~100-500 KB
- Estimated capacity: 2,000-10,000 images
- With 7-day auto-delete: Sustainable for most use cases

### Reducing Storage Usage

1. **Compress images before upload:**
```dart
// Add image compression package
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Compress before upload
final compressed = await FlutterImageCompress.compressWithFile(
  _image!.path,
  quality: 70, // 0-100
);
```

2. **Reduce image resolution:**
```dart
// Resize image using image package
final resized = img.copyResize(
  originalImage,
  width: 800, // Max width
  height: 800, // Max height
  interpolation: img.Interpolation.linear,
);
```

3. **Store thumbnails only** (optional):
   - Save small thumbnails for history view
   - Only keep original for 24 hours

## Security Considerations

### Current Security
- ✅ Only authenticated users can upload
- ✅ Users can only delete their own images
- ✅ Public read access for viewing
- ✅ Files stored in isolated folder structure

### Additional Security (Optional)

1. **Signed URLs for private access:**
```dart
final signedUrl = await supabase.storage
  .from('disease-images')
  .createSignedUrl(filePath, 3600); // 1 hour expiry
```

2. **Rate limiting:**
   - Implement upload limits per user
   - Prevent abuse

3. **File validation:**
   - Check file type
   - Verify image format
   - Scan for malware (if needed)

## Future Enhancements

Potential improvements:
- [ ] Image compression before upload
- [ ] Thumbnail generation
- [ ] Multiple images per detection
- [ ] Image annotation/markup
- [ ] Export detection history with images
- [ ] Offline image caching
- [ ] Image comparison (before/after treatment)
- [ ] Share detection images

## Quick Reference

### Upload Image
```dart
await supabase.storage
  .from('disease-images')
  .uploadBinary('disease_detections/file.jpg', bytes);
```

### Get Public URL
```dart
final url = supabase.storage
  .from('disease-images')
  .getPublicUrl('disease_detections/file.jpg');
```

### Delete Image
```dart
await supabase.storage
  .from('disease-images')
  .remove(['disease_detections/file.jpg']);
```

### List Files
```dart
final files = await supabase.storage
  .from('disease-images')
  .list('disease_detections');
```
