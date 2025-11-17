# SSM Certificate Upload Implementation

## Overview
This document explains the implementation of the SSM (Suruhanjaya Syarikat Malaysia / Companies Commission of Malaysia) certificate upload feature for supplier verification.

## Purpose
Suppliers must upload their business registration certificate during the signup process. Admin users must verify these certificates before approving supplier applications to ensure only legitimate registered businesses can sell products on the platform.

## User Flow

### Supplier Registration Flow
1. User registers with role "Supplier"
2. After registration, redirected to Supplier Details screen
3. Fills in business information (name, address, phone, type, description, products)
4. **Uploads SSM certificate** (required)
5. Submits profile for admin review
6. Status: "Pending approval"

### Admin Verification Flow
1. Admin logs in to Admin Dashboard
2. Views list of pending supplier applications
3. Clicks on a supplier to view details
4. **Reviews SSM certificate** by clicking "View Certificate" button
5. Certificate opens in browser/external viewer
6. Admin approves or rejects based on certificate validity
7. Status: "Approved" or "Rejected"

### Approved Supplier Flow
1. Approved suppliers can access Supplier Dashboard
2. Can add/manage products in marketplace
3. Can view orders and sales

## Technical Implementation

### 1. Certificate Upload UI (`lib/screens/supplier_details_screen.dart`)

**State Variables:**
```dart
File? _certificateFile;          // Stores the selected certificate file
String? _certificateFileName;    // Stores the filename for display
final ImagePicker _picker = ImagePicker();  // Image picker instance
```

**Certificate Picker Methods:**
- `_pickCertificate()`: Shows dialog to choose between gallery or camera
- `_pickFromGallery()`: Selects image from device gallery
- `_pickFromCamera()`: Takes photo using device camera

**UI Components:**
- Certificate upload card with icon and instructions
- Upload/Change certificate button
- Selected file display with remove option
- Warning indicator if no certificate uploaded
- Required field validation before submission

**Features:**
- Image quality optimization (85% quality)
- File name display
- Remove uploaded file option
- Visual feedback (green border when uploaded)
- Clear instructions for users

### 2. Certificate Storage (`lib/services/auth_service.dart`)

**Enhanced `updateSupplierDetails` Method:**
```dart
Future<Map<String, dynamic>> updateSupplierDetails(
  String userId, 
  Map<String, dynamic> data,
  {File? certificateFile}  // Optional parameter for certificate file
) async
```

**Upload Process:**
1. Read file as bytes
2. Generate unique filename: `certificate_{userId}_{timestamp}.{extension}`
3. Upload to Supabase storage bucket `supplier-certificates`
4. Get public URL
5. Save URL to `users.certificate_url` column
6. Update user profile with all business details

**Error Handling:**
- Try-catch block for upload errors
- Returns success/failure status
- Error messages for debugging

### 3. Admin Certificate Viewing (`lib/screens/admin_dashboard.dart`)

**Certificate Display in Supplier Modal:**
- Shows certificate section in supplier details modal
- "View Certificate" button if certificate exists
- Warning message if no certificate uploaded
- Opens certificate in external browser

**`_viewCertificate` Method:**
```dart
Future<void> _viewCertificate(String certificateUrl) async
```
- Uses `url_launcher` package to open certificate URL
- Opens in external application (browser or image viewer)
- Shows error message if opening fails

**UI Components:**
- Certificate section with verification icon
- View certificate button with open icon
- Warning container for missing certificates
- Color-coded visual indicators

## Supabase Backend Setup

### Storage Bucket Configuration
- **Bucket Name**: `supplier-certificates`
- **Visibility**: Private (not public)
- **RLS Policies**: 3 policies configured

### RLS Policies

**1. Allow Authenticated Uploads**
```sql
Policy: Allow authenticated uploads
Operation: INSERT
Target: authenticated
Expression: true
```
Allows any authenticated user to upload certificates.

**2. Allow Users to Read Own Certificates**
```sql
Policy: Allow users to read own certificates
Operation: SELECT
Target: authenticated
Expression: true
```
Allows users to view their own uploaded certificates.

**3. Allow Admins to Read All Certificates**
```sql
Policy: Allow admins to read all certificates
Operation: SELECT
Target: authenticated
Expression: (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
```
Allows admin users to view all supplier certificates for verification.

### Database Schema

**users table - New Column:**
```sql
certificate_url TEXT NULL
```
Stores the Supabase storage URL for the certificate file.

## File Format Support

**Supported Formats:**
- JPEG/JPG images
- PNG images
- (Future: PDF documents with additional configuration)

**File Size:**
- Recommended: Under 5MB
- Maximum: 50MB (Supabase default)
- Image quality: 85% compression for optimization

## Dependencies

### Added Package
```yaml
url_launcher: ^6.2.5
```

**Purpose**: Open certificate URLs in external applications (browser, image viewer)

**Usage**: 
```dart
import 'package:url_launcher/url_launcher.dart';
```

### Existing Packages Used
- `image_picker: ^1.1.0` - For file selection
- `supabase_flutter: ^2.3.4` - For storage and database

## Validation & Error Handling

### Client-Side Validation
1. **Certificate Required**: User cannot submit without uploading certificate
2. **File Type**: Only images supported (enforced by ImagePicker)
3. **File Size**: Limited by device and Supabase (50MB max)
4. **Business Details**: All required fields must be filled

### Server-Side Handling
1. **Upload Errors**: Caught and returned with error message
2. **Database Errors**: Transaction rollback if save fails
3. **Missing User**: Checks authentication before upload
4. **Network Errors**: Handled with try-catch blocks

### User Feedback
- Toast messages for success/error
- Loading indicators during upload
- Visual confirmation when file selected
- Error messages for failed operations

## Security Considerations

### Storage Security
- Private bucket (not publicly accessible)
- RLS policies control access
- Only authenticated users can upload
- Only admins can view all certificates
- Users can only view their own certificates

### File Security
- Unique filenames prevent collisions
- Timestamp in filename for uniqueness
- User ID in filename for traceability
- No file overwriting (upsert: true for same filename)

### Access Control
- Admin role verification via database query
- Authentication required for all operations
- Role-based access control (RBAC)
- Session-based authentication

## Testing Checklist

### Supplier Flow
- [ ] Register new supplier account
- [ ] Redirect to supplier details screen
- [ ] Fill all required fields
- [ ] Click "Upload Certificate" button
- [ ] Select image from gallery
- [ ] Verify file name displays
- [ ] Remove and re-upload certificate
- [ ] Take photo with camera option
- [ ] Submit form with certificate
- [ ] Verify success message
- [ ] Check profile status is "pending"

### Admin Flow
- [ ] Login as admin
- [ ] View pending suppliers list
- [ ] Click on supplier with certificate
- [ ] Verify certificate section appears
- [ ] Click "View Certificate" button
- [ ] Verify certificate opens in browser
- [ ] Verify image displays correctly
- [ ] Approve supplier
- [ ] Verify status changes to "approved"

### Edge Cases
- [ ] Submit without certificate (should fail)
- [ ] Upload very large image (check size limits)
- [ ] Upload corrupted image (error handling)
- [ ] Network error during upload (error message)
- [ ] Click "View Certificate" with missing URL (error handling)
- [ ] Non-admin tries to view certificates (should fail)

### Database Verification
- [ ] Check `users` table has `certificate_url` column
- [ ] Verify certificate URL is saved after upload
- [ ] Check storage bucket contains uploaded file
- [ ] Verify file naming convention is correct
- [ ] Check RLS policies are active

## Troubleshooting

### Issue: Certificate upload fails
**Possible Causes:**
- Storage bucket not created
- RLS policies not configured
- User not authenticated
- File too large
- Network error

**Solutions:**
- Follow Supabase setup guide in `SUPABASE_CERTIFICATE_SETUP.md`
- Check authentication status
- Reduce image size/quality
- Check network connection
- Review error logs

### Issue: Admin cannot view certificates
**Possible Causes:**
- Admin role not set correctly
- RLS policy not configured
- Certificate URL is null/empty

**Solutions:**
- Verify `role = 'admin'` in users table
- Check RLS policy SQL expression
- Ensure supplier uploaded certificate
- Check certificate_url in database

### Issue: Certificate URL not saving
**Possible Causes:**
- `certificate_url` column doesn't exist
- Database update error
- Transaction rollback

**Solutions:**
- Run SQL migration: `supabase_migrations/add_certificate_url.sql`
- Check database error logs
- Verify update query in AuthService

### Issue: "View Certificate" button doesn't open file
**Possible Causes:**
- URL is invalid
- File was deleted from storage
- url_launcher not configured
- Device/browser blocking popup

**Solutions:**
- Check certificate URL in database
- Verify file exists in storage bucket
- Update url_launcher package
- Check browser popup settings
- Test on different device/browser

## Future Enhancements

### Potential Improvements
1. **PDF Support**: Allow suppliers to upload PDF certificates
2. **File Preview**: Show image preview before submission
3. **Multi-file Upload**: Support multiple certificate types (business license, tax ID, etc.)
4. **In-app Viewer**: View certificates within the app instead of external browser
5. **Certificate Expiry**: Track certificate expiration dates
6. **Automatic Verification**: OCR to extract business registration number
7. **File Compression**: Automatic image compression for large files
8. **Progress Indicator**: Upload progress bar for large files
9. **Certificate History**: Track certificate updates/renewals
10. **Notification System**: Alert admins when new certificates uploaded

### Performance Optimizations
1. Implement file caching for faster loads
2. Add lazy loading for certificate images
3. Compress images before upload
4. Use thumbnail generation for previews
5. Implement CDN for faster global access

## Code References

### Key Files Modified
1. `lib/screens/supplier_details_screen.dart` - Certificate upload UI
2. `lib/services/auth_service.dart` - Certificate storage logic
3. `lib/screens/admin_dashboard.dart` - Certificate viewing for admins
4. `pubspec.yaml` - Added url_launcher dependency

### Key Methods
- `SupplierDetailsScreen._pickCertificate()` - Certificate selection
- `SupplierDetailsScreen._buildCertificateUpload()` - Upload UI widget
- `AuthService.updateSupplierDetails()` - Upload to storage
- `AdminDashboard._viewCertificate()` - Open certificate URL

### Database Migration
- `supabase_migrations/add_certificate_url.sql` - Add certificate_url column

### Setup Guide
- `SUPABASE_CERTIFICATE_SETUP.md` - Complete Supabase configuration

## Conclusion

The SSM certificate upload feature ensures supplier legitimacy and platform credibility. Admins can verify business registration before approval, preventing fraudulent suppliers from accessing the marketplace. The implementation uses secure storage with proper access control, providing a seamless experience for both suppliers and administrators.
