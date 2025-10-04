import 'dart:io';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class CsvImporter {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Import users from CSV file to Firestore
  static Future<Map<String, dynamic>> importFromCsv(String csvFilePath) async {
    try {
      // Read CSV file
      final input = File(csvFilePath).readAsStringSync();
      
      // Parse CSV
      final List<List<dynamic>> rows = const CsvToListConverter().convert(input);

      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      // Skip header rows (first 6 rows based on your CSV)
      // Start from row 6 (index 6)
      for (int i = 6; i < rows.length; i++) {
        try {
          final row = rows[i];
          
          // Skip empty rows
          if (row.isEmpty || row[0].toString().trim().isEmpty) {
            continue;
          }

          // Parse CSV row
          final userData = _parseUserData(row, i);
          
          // Create a document ID based on student ID or generate one
          String docId;
          if (userData['studentId'] != null && userData['studentId'].toString().isNotEmpty) {
            docId = 'csv_${userData['studentId'].toString().replaceAll(' ', '_')}';
          } else {
            docId = 'csv_row_$i';
          }
          
          // Upload to Firestore
          await _firestore.collection('users').doc(docId).set(
            userData,
            SetOptions(merge: true), // Merge to avoid overwriting existing data
          );
          
          successCount++;
          print('✅ Imported: ${userData['displayName']} (${userData['studentId']})');
          
        } catch (e) {
          errorCount++;
          errors.add('Row $i: ${e.toString()}');
          print('❌ Error at row $i: $e');
        }
      }

      return {
        'success': true,
        'successCount': successCount,
        'errorCount': errorCount,
        'errors': errors,
        'message': 'Imported $successCount users successfully. $errorCount errors.',
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to import CSV: ${e.toString()}',
      };
    }
  }

  /// Parse a CSV row into user data map
  static Map<String, dynamic> _parseUserData(List<dynamic> row, int rowIndex) {
    // CSV columns based on your file:
    // 0: Sl. #
    // 1: Reg. ID (will be skipped - not used)
    // 2: Name
    // 3: Nick Name
    // 4: NDC Roll # (Student ID)
    // 5: Blood Group
    // 6: Home District
    // 7: DoB
    // 8: Profession
    // 9: Professional Details
    // 10: Grad. Sub.
    // 11: Grad. Inst.
    // 12: Contact #
    // 13: e-mail ID
    // 14: Residential Area
    // 15: Polo Size

    String _getValue(int index) {
      if (index < row.length && row[index] != null) {
        return row[index].toString().trim();
      }
      return '';
    }

    String _getGroupFromStudentId(String studentId) {
      if (studentId.length < 3) return '';
      return studentId.substring(2, 3);  // Get the 3rd character
    }

    final studentId = _getValue(4);

    return {
      'displayName': _getValue(2),
      'nickName': _getValue(3),
      'studentId': studentId,
      'group': _getGroupFromStudentId(studentId),
      'bloodGroup': _getValue(5),
      'homeDistrict': _getValue(6),
      'dateOfBirth': _parseDate(_getValue(7)),
      'profession': _getValue(8),
      'professionalDetails': _getValue(9),
      'graduationSubject': _getValue(10),
      'graduationInstitution': _getValue(11),
      'phoneNumber': _parsePhone(_getValue(12)),
      'email': _getValue(13).toLowerCase(),
      'residentialArea': _getValue(14),
      'poloSize': _getValue(15),
      'importedFromCsv': true,
      'importedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Parse date string (format: "1-Jun-76" or "18-May-77")
  static String _parseDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    
    try {
      // Example: "1-Jun-76"
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      
      final day = int.parse(parts[0]);
      final monthStr = parts[1];
      final yearStr = parts[2];
      int year = int.parse(yearStr);
      
      // Convert month abbreviation to number
      const months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
      };
      
      final month = months[monthStr] ?? 1;
      
      // Assume 19xx for year < 100
      if (year < 100) {
        year = 1900 + year;
      }
      
      // Return DD/MM/YYYY format (matching the app's format)
      return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
      
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  /// Parse phone number (remove spaces, keep only digits and +)
  static String _parsePhone(String phone) {
    if (phone.isEmpty) return '';
    
    // Remove extra spaces but keep the format readable
    return phone.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
