# CSV Data Import Guide

This guide explains how to import existing member data from CSV files into the Firestore database.

## Overview

The CSV import feature allows administrators to bulk-import member data from a CSV file directly into Firestore. This is useful for:
- Initial database population
- Migrating existing member records
- Bulk updates to member information

## CSV File Format

### Required Structure

The CSV file must have the following 16 columns (in order):

1. **Sl. #** - Serial number (ignored during import)
2. **Reg. ID** - Registration ID
3. **Name** - Full name
4. **Nick Name** - Nickname
5. **NDC Roll #** - Student ID number
6. **Blood Group** - Blood group (e.g., A+, B-, O+, AB+)
7. **Home District** - Home district name
8. **DoB** - Date of birth (format: "1-Jun-76")
9. **Profession** - Current profession
10. **Professional Details** - Professional details/position
11. **Grad. Sub.** - Graduation subject
12. **Grad. Inst.** - Graduation institution
13. **Contact #** - Primary phone number
14. **e-mail ID** - Email address
15. **Residential Area** - Current residential area
16. **Polo Size** - T-shirt/polo size (S, M, L, XL, XXL, XXXL)

### Header Rows

- The import function automatically **skips the first 6 rows** of the CSV file
- These rows are assumed to contain headers, titles, or metadata
- Actual data parsing begins at row 7

### Example CSV Format

```csv
Title Row 1
Title Row 2
... (up to row 6)
1,REG001,John Doe,Johnny,12345,A+,Dhaka,1-Jun-76,Engineer,Senior Engineer,CSE,BUET,01711123456,john@example.com,Gulshan,L
```

## Firestore Field Mapping

The CSV columns are mapped to Firestore fields as follows:

| CSV Column | Firestore Field | Type | Notes |
|------------|-----------------|------|-------|
| Reg. ID | `registrationId` | String | Used for document ID |
| Name | `displayName` | String | - |
| Nick Name | `nickName` | String | - |
| NDC Roll # | `studentId` | String | - |
| Blood Group | `bloodGroup` | String | - |
| Home District | `homeDistrict` | String | - |
| DoB | `dateOfBirth` | String | Converted to DD/MM/YYYY |
| Profession | `profession` | String | - |
| Professional Details | `professionalDetails` | String | - |
| Grad. Sub. | `graduationSubject` | String | - |
| Grad. Inst. | `graduationInstitution` | String | - |
| Contact # | `phoneNumber` | String | Cleaned of formatting |
| e-mail ID | `email` | String | - |
| Residential Area | `residentialArea` | String | - |
| Polo Size | `poloSize` | String | - |

### Additional Fields

All imported documents include these metadata fields:

- `importedFromCsv`: `true` - Indicates this was imported from CSV
- `importedAt`: `timestamp` - When the import occurred
- `updatedAt`: `timestamp` - Last update time

## Import Methods

### Method 1: In-App Admin Import Screen (Recommended for Testing)

1. **Access the Import Screen**
   - Sign in to the app
   - Go to "My Profile" tab
   - Tap the **upload icon** (📄) in the top-right corner of the app bar

2. **Select CSV File**
   - Tap "Select CSV File" button
   - Choose your CSV file from the device
   - Supported format: `.csv` only

3. **Monitor Progress**
   - The app will show "Importing..." while processing
   - Do not close the app during import

4. **View Results**
   - Success: Green card shows number of users imported
   - Errors: Orange/red card shows any issues
   - Both counts are displayed if some succeed and some fail

### Method 2: Command-Line Script (For Production)

For large-scale imports or automated processes:

```dart
// In a separate Dart script
import 'package:ndc95/utils/csv_importer.dart';

void main() async {
  final result = await CsvImporter.importFromCsv('/path/to/your/file.csv');
  print(result['message']);
}
```

## Data Processing

### Date Format Conversion

The importer automatically converts dates from the CSV format to a standardized format:

- **CSV Format**: "1-Jun-76", "15-Dec-95", "3-Mar-80"
- **Firestore Format**: "01/06/1976", "15/12/1995", "03/03/1980"

Month abbreviations recognized:
- Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec

### Phone Number Cleaning

Phone numbers are cleaned automatically:
- Removes spaces, dashes, parentheses
- Removes "+" prefix
- Example: "+880-1711-123456" → "8801711123456"

### Empty Field Handling

- Empty or whitespace-only fields are stored as empty strings
- This preserves document structure while indicating no data

## Merge Strategy

**Important**: The import uses `SetOptions(merge: true)` to **preserve existing user data**.

This means:
- If a document already exists (from Google Sign-In), it will NOT be overwritten
- New fields from CSV will be added to existing documents
- Existing fields will NOT be replaced
- User photos, email verification status, etc. remain intact

### Document ID Strategy

Documents are created with IDs in the following priority:

1. **Primary**: `csv_[RegistrationID]` - if Registration ID exists
2. **Fallback**: `csv_row_[RowIndex]` - if no Registration ID

Examples:
- Registration ID "REG001" → Document ID: `csv_REG001`
- Row 7 with no Reg ID → Document ID: `csv_row_7`

## Security Considerations

### Production Deployment

⚠️ **Important**: Before deploying to production:

1. **Remove or Protect Admin Access**
   - The upload icon in the app bar should be removed or protected
   - Consider adding admin authentication checks
   - Only authorized users should access the import function

2. **Firestore Security Rules**
   - Ensure Firestore rules prevent unauthorized writes
   - Example rule:
   ```javascript
   match /users/{userId} {
     allow read: if request.auth != null;
     allow write: if request.auth != null && request.auth.uid == userId;
     // Admin import should use Firebase Admin SDK with elevated privileges
   }
   ```

3. **Use Firebase Admin SDK**
   - For production imports, use Firebase Admin SDK on a secure server
   - Avoid client-side imports for large datasets
   - Admin SDK bypasses security rules safely

### Recommended Production Approach

1. Create a separate admin tool or Cloud Function
2. Use Firebase Admin SDK with service account credentials
3. Add proper authentication and authorization
4. Log all import activities
5. Add data validation before import

## Troubleshooting

### Common Issues

**Issue**: "csv package not found"
- **Solution**: Run `flutter pub get` to install dependencies

**Issue**: "Permission denied" during import
- **Solution**: Ensure Firestore is enabled in Firebase Console
- Check: https://console.cloud.google.com/firestore/databases

**Issue**: Dates not parsing correctly
- **Solution**: Verify CSV uses format like "1-Jun-76" with 3-letter month
- Check that year is 2-digit (76, 95, etc.)

**Issue**: Some rows fail to import
- **Solution**: Check error count in result message
- Verify CSV structure matches expected format
- Ensure no corrupted rows in CSV file

**Issue**: Imported users don't appear in Directory
- **Solution**: Firestore API must be enabled
- See: FIRESTORE_SETUP.md

### Validation Checklist

Before importing, verify:

- [ ] CSV file has 16 columns
- [ ] First 6 rows are headers/metadata
- [ ] Date format is "D-MMM-YY" (e.g., "1-Jun-76")
- [ ] Blood groups match expected values (A+, B-, etc.)
- [ ] Polo sizes are valid (S, M, L, XL, XXL, XXXL)
- [ ] Registration IDs are unique
- [ ] Firestore is enabled in Firebase Console
- [ ] You have admin/owner permissions

## Testing the Import

### Test with Sample Data

1. Create a small test CSV with 2-3 rows
2. Import using the admin screen
3. Check Firestore Console to verify data
4. Verify fields are correctly mapped
5. Test that existing users are not overwritten

### Verify Import Results

After import, check:

1. **Firestore Console**
   - Go to Firebase Console → Firestore Database
   - Look for documents with IDs starting with `csv_`
   - Verify all fields are present

2. **Directory Screen**
   - Imported users should appear in directory
   - Search functionality should work
   - Profile data should display correctly

3. **Profile Screen**
   - Open an imported user's profile
   - Verify all 19 fields are populated correctly
   - Check that dates are in DD/MM/YYYY format

## Code Reference

### Import Function

Located in: `lib/utils/csv_importer.dart`

Key method:
```dart
static Future<Map<String, dynamic>> importFromCsv(String csvFilePath)
```

Returns:
```dart
{
  'success': true/false,
  'message': 'Success/error message',
  'successCount': 123,
  'errorCount': 5
}
```

### Admin Import Screen

Located in: `lib/screens/admin_import_screen.dart`

Features:
- File picker for CSV selection
- Progress indicator
- Result display with counts
- Instructions card

## Future Enhancements

Potential improvements for the import feature:

1. **User Matching**
   - Automatically link CSV records to Google Sign-In users
   - Match by email or other unique identifiers
   - Merge data when user signs in

2. **Validation & Preview**
   - Preview data before import
   - Validate data format and constraints
   - Show warnings for suspicious data

3. **Incremental Updates**
   - Only update changed fields
   - Track import history
   - Rollback capability

4. **Progress Reporting**
   - Real-time progress bar
   - Row-by-row status updates
   - Detailed error reporting

5. **Export Functionality**
   - Export Firestore data to CSV
   - Backup before bulk operations
   - Data migration tools

## Support

For issues or questions:
1. Check this guide's Troubleshooting section
2. Review FIRESTORE_SETUP.md for database setup
3. Verify Firebase configuration
4. Check app logs for detailed error messages

## Related Documentation

- [Firebase Setup Guide](FIREBASE_SETUP.md)
- [Firestore Setup](FIRESTORE_SETUP.md)
- [Profile Fields Documentation](PROFILE_FIELDS_UPDATE.md)
- [Firebase Storage Setup](FIREBASE_STORAGE_SETUP.md)
