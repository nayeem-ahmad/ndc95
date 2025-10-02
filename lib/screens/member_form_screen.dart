import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../constants/profile_constants.dart';

class MemberFormScreen extends StatefulWidget {
  final String? userId; // null for new member, non-null for editing
  final Map<String, dynamic>? userData; // null for new member

  const MemberFormScreen({
    super.key,
    this.userId,
    this.userData,
  });

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers for all fields
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _nickNameController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _residentialAreaController;
  late TextEditingController _studentIdController;
  late TextEditingController _graduationSubjectController;
  late TextEditingController _graduationInstitutionController;
  late TextEditingController _professionController;
  late TextEditingController _professionalDetailsController;
  late TextEditingController _companyController;
  late TextEditingController _workLocationController;
  late TextEditingController _linkedInController;

  String? _selectedBloodGroup;
  String? _selectedHomeDistrict;
  String? _selectedPoloSize;
  
  bool get _isEditMode => widget.userId != null;
  String _originalEmail = ''; // To track if email changed

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _displayNameController = TextEditingController(text: widget.userData?['displayName'] ?? '');
    _emailController = TextEditingController(text: widget.userData?['email'] ?? '');
    _nickNameController = TextEditingController(text: widget.userData?['nickName'] ?? '');
    _dobController = TextEditingController(text: widget.userData?['dateOfBirth'] ?? '');
    _phoneController = TextEditingController(text: widget.userData?['phoneNumber'] ?? '');
    _altPhoneController = TextEditingController(text: widget.userData?['alternatePhone'] ?? '');
    _addressController = TextEditingController(text: widget.userData?['address'] ?? '');
    _residentialAreaController = TextEditingController(text: widget.userData?['residentialArea'] ?? '');
    _studentIdController = TextEditingController(text: widget.userData?['studentId'] ?? '');
    _graduationSubjectController = TextEditingController(text: widget.userData?['graduationSubject'] ?? '');
    _graduationInstitutionController = TextEditingController(text: widget.userData?['graduationInstitution'] ?? '');
    _professionController = TextEditingController(text: widget.userData?['profession'] ?? '');
    _professionalDetailsController = TextEditingController(text: widget.userData?['professionalDetails'] ?? '');
    _companyController = TextEditingController(text: widget.userData?['company'] ?? '');
    _workLocationController = TextEditingController(text: widget.userData?['workLocation'] ?? '');
    _linkedInController = TextEditingController(text: widget.userData?['linkedIn'] ?? '');

    _selectedBloodGroup = widget.userData?['bloodGroup'];
    _selectedHomeDistrict = widget.userData?['homeDistrict'];
    _selectedPoloSize = widget.userData?['poloSize'];
    
    _originalEmail = widget.userData?['email'] ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _nickNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    _residentialAreaController.dispose();
    _studentIdController.dispose();
    _graduationSubjectController.dispose();
    _graduationInstitutionController.dispose();
    _professionController.dispose();
    _professionalDetailsController.dispose();
    _companyController.dispose();
    _workLocationController.dispose();
    _linkedInController.dispose();
    super.dispose();
  }

  // Helper method to extract group from student ID (3rd digit)
  String _getGroupFromStudentId(String? studentId) {
    if (studentId == null || studentId.length < 3) {
      return '';
    }
    return studentId.substring(2, 3);
  }

  // Check if email is unique in the database
  Future<bool> _isEmailUnique(String email) async {
    try {
      // If editing and email hasn't changed, it's valid
      if (_isEditMode && email.toLowerCase() == _originalEmail.toLowerCase()) {
        return true;
      }

      final QuerySnapshot result = await FirebaseService.firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      return result.docs.isEmpty;
    } catch (e) {
      print('Error checking email uniqueness: $e');
      return false;
    }
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check email uniqueness
    final email = _emailController.text.trim();
    final isUnique = await _isEmailUnique(email);
    
    if (!isUnique) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This email is already registered in the system.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final studentId = _studentIdController.text.trim();
      final memberData = {
        'displayName': _displayNameController.text.trim(),
        'email': email.toLowerCase(),
        'nickName': _nickNameController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'alternatePhone': _altPhoneController.text.trim(),
        'address': _addressController.text.trim(),
        'residentialArea': _residentialAreaController.text.trim(),
        'studentId': studentId,
        'graduationSubject': _graduationSubjectController.text.trim(),
        'graduationInstitution': _graduationInstitutionController.text.trim(),
        'profession': _professionController.text.trim(),
        'professionalDetails': _professionalDetailsController.text.trim(),
        'company': _companyController.text.trim(),
        'workLocation': _workLocationController.text.trim(),
        'linkedIn': _linkedInController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'homeDistrict': _selectedHomeDistrict,
        'poloSize': _selectedPoloSize,
        'group': _getGroupFromStudentId(studentId),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        // Update existing member
        await FirebaseService.firestore
            .collection('users')
            .doc(widget.userId)
            .update(memberData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        // Add new member - use studentId as document ID if provided
        final docId = studentId.isNotEmpty ? studentId : null;
        memberData['createdAt'] = FieldValue.serverTimestamp();
        memberData['photoUrl'] = ''; // Default empty photo
        
        if (docId != null) {
          await FirebaseService.firestore
              .collection('users')
              .doc(docId)
              .set(memberData);
        } else {
          await FirebaseService.firestore
              .collection('users')
              .add(memberData);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Member' : 'Add New Member'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Required Fields Section
              _buildSectionHeader('Required Information', Icons.person),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _displayNameController,
                label: 'Full Name *',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _emailController,
                label: 'Email *',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _studentIdController,
                label: 'Student ID (NDC Roll #) *',
                icon: Icons.badge,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Student ID is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Personal Information Section
              _buildSectionHeader('Personal Information', Icons.info),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _nickNameController,
                label: 'Nick Name',
                icon: Icons.tag,
              ),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _dobController,
                label: 'Date of Birth',
                icon: Icons.cake,
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              
              _buildDropdownField(
                value: _selectedBloodGroup,
                items: ProfileConstants.bloodGroups,
                label: 'Blood Group',
                icon: Icons.bloodtype,
                onChanged: (value) {
                  setState(() {
                    _selectedBloodGroup = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              
              _buildDropdownField(
                value: _selectedHomeDistrict,
                items: ProfileConstants.districts,
                label: 'Home District',
                icon: Icons.home,
                onChanged: (value) {
                  setState(() {
                    _selectedHomeDistrict = value;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Contact Information Section
              _buildSectionHeader('Contact Information', Icons.contact_phone),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _altPhoneController,
                label: 'Alternate Phone',
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _residentialAreaController,
                label: 'Residential Area',
                icon: Icons.location_city,
              ),
              
              const SizedBox(height: 24),
              
              // Education Section
              _buildSectionHeader('Education', Icons.school),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _graduationSubjectController,
                label: 'Graduation Subject',
                icon: Icons.subject,
              ),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _graduationInstitutionController,
                label: 'Graduation Institution',
                icon: Icons.account_balance,
              ),
              
              const SizedBox(height: 24),
              
              // Professional Information Section
              _buildSectionHeader('Professional Information', Icons.work),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _professionController,
                label: 'Profession',
                icon: Icons.work_outline,
              ),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _professionalDetailsController,
                label: 'Professional Details',
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _companyController,
                label: 'Company',
                icon: Icons.business,
              ),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _workLocationController,
                label: 'Work Location',
                icon: Icons.place,
              ),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _linkedInController,
                label: 'LinkedIn Profile',
                icon: Icons.link,
                keyboardType: TextInputType.url,
              ),
              
              const SizedBox(height: 24),
              
              // Other Information Section
              _buildSectionHeader('Other Information', Icons.checkroom),
              const SizedBox(height: 12),
              
              _buildDropdownField(
                value: _selectedPoloSize,
                items: ProfileConstants.shirtSizes,
                label: 'Polo Size',
                icon: Icons.checkroom,
                onChanged: (value) {
                  setState(() {
                    _selectedPoloSize = value;
                  });
                },
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMember,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(_isEditMode ? Icons.save : Icons.add),
                  label: Text(
                    _isSaving 
                        ? 'Saving...' 
                        : (_isEditMode ? 'Update Member' : 'Add Member'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
