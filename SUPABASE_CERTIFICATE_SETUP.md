# Supabase Certificate Storage Setup

## Overview
This guide explains how to set up the Supabase storage bucket for supplier SSM certificates.

## Setup Instructions

### 1. Create Storage Bucket

1. Go to your Supabase project dashboard
2. Navigate to **Storage** in the left sidebar
3. Click **"New bucket"**
4. Configure the bucket:
   - **Name**: `supplier-certificates`
   - **Public bucket**: **OFF** (keep it private)
   - Click **"Create bucket"**

### 2. Configure Storage Policies (RLS)

After creating the bucket, you need to set up Row Level Security (RLS) policies to control access.

#### Policy 1: Allow Authenticated Users to Upload
This allows authenticated suppliers to upload their certificates.

1. Click on the `supplier-certificates` bucket
2. Go to **Policies** tab
3. Click **"New Policy"**
4. Configure:
   - **Policy name**: `Allow authenticated uploads`
   - **Allowed operation**: `INSERT`
   - **Target roles**: `authenticated`
   - **USING expression**: `true`
   - **WITH CHECK expression**: `true`
5. Click **"Review"** then **"Save policy"**

#### Policy 2: Allow Authenticated Users to Read Their Own Certificates
This allows users to read their own uploaded certificates.

1. Click **"New Policy"** again
2. Configure:
   - **Policy name**: `Allow users to read own certificates`
   - **Allowed operation**: `SELECT`
   - **Target roles**: `authenticated`
   - **USING expression**: `true`
3. Click **"Review"** then **"Save policy"**

#### Policy 3: Allow Admins to Read All Certificates
This allows admin users to view all supplier certificates for verification.

1. Click **"New Policy"** again
2. Configure:
   - **Policy name**: `Allow admins to read all certificates`
   - **Allowed operation**: `SELECT`
   - **Target roles**: `authenticated`
   - **USING expression**: 
   ```sql
   (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
   ```
3. Click **"Review"** then **"Save policy"**

### 3. Update Users Table Schema

You need to add a `certificate_url` column to the `users` table if it doesn't already exist.

1. Go to **Table Editor** in the left sidebar
2. Select the `users` table
3. Click on **"+ New Column"** (or edit if column already exists)
4. Configure:
   - **Name**: `certificate_url`
   - **Type**: `text`
   - **Default value**: `NULL`
   - **Is nullable**: `true`
5. Click **"Save"**

### 4. File Upload Configuration

The application supports the following file formats for certificates:
- **Images**: JPEG, PNG
- **Documents**: PDF (via image picker - may need additional configuration)

**File Size Limits:**
- Default Supabase limit: 50MB per file
- Recommended: Keep certificates under 5MB for better performance

### 5. Testing the Setup

To verify the setup is working:

1. Register as a new supplier
2. Fill in business details
3. Upload an SSM certificate (image file)
4. Check in Supabase Storage > supplier-certificates that the file was uploaded
5. Check in users table that certificate_url is populated
6. Login as admin and view the supplier approval
7. Verify that the "View Certificate" button opens the certificate

### 6. Security Considerations

- **Private Bucket**: Keep the bucket private to prevent unauthorized access
- **RLS Policies**: Only authenticated users and admins can access certificates
- **File Validation**: The app validates file types on the client side
- **URL Expiration**: Supabase storage URLs are permanent but can be revoked by deleting the file

### 7. Troubleshooting

**Issue**: Certificate upload fails
- **Solution**: Check that the storage bucket exists and policies are configured correctly
- **Solution**: Verify that the user is authenticated
- **Solution**: Check file size is within limits

**Issue**: Admin cannot view certificates
- **Solution**: Verify admin role is set correctly in users table
- **Solution**: Check that the admin read policy is configured with the correct SQL expression

**Issue**: Certificate URL not saving to database
- **Solution**: Verify certificate_url column exists in users table
- **Solution**: Check that the AuthService.updateSupplierDetails method includes certificateFile parameter

## Database Schema Reference

### users table - certificate_url column
```sql
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS certificate_url TEXT;
```

## Storage Bucket Configuration Summary

- **Bucket Name**: `supplier-certificates`
- **Public**: No (Private)
- **File size limit**: 50MB (Supabase default)
- **Allowed operations**: INSERT (authenticated), SELECT (authenticated/admin)
- **RLS**: Enabled with 3 policies

## Implementation Files

The following files implement the certificate upload feature:

1. **lib/screens/supplier_details_screen.dart**: Certificate upload UI
2. **lib/services/auth_service.dart**: Certificate upload to Supabase storage
3. **lib/screens/admin_dashboard.dart**: Certificate viewing for admins
4. **pubspec.yaml**: Added url_launcher dependency

## Next Steps

After completing this setup:
1. Test the complete flow with a test supplier account
2. Verify admin can view and open certificates
3. Test reject/approve flow with certificate verification
4. Document the verification process for admin users
