import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import '../services/firebase_service.dart';
import '../constants/profile_constants.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  
  // Controllers for editable fields
  late TextEditingController _nickNameController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _residentialAreaController;
  late TextEditingController _studentIdController;
  late TextEditingController _registrationIdController;
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
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nickNameController = TextEditingController(text: widget.userData['nickName'] ?? '');
    _dobController = TextEditingController(text: widget.userData['dateOfBirth'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['phoneNumber'] ?? '');
    _altPhoneController = TextEditingController(text: widget.userData['alternatePhone'] ?? '');
    _addressController = TextEditingController(text: widget.userData['address'] ?? '');
    _residentialAreaController = TextEditingController(text: widget.userData['residentialArea'] ?? '');
    _studentIdController = TextEditingController(text: widget.userData['studentId'] ?? '');
    _registrationIdController = TextEditingController(text: widget.userData['registrationId'] ?? '');
    _graduationSubjectController = TextEditingController(text: widget.userData['graduationSubject'] ?? '');
    _graduationInstitutionController = TextEditingController(text: widget.userData['graduationInstitution'] ?? '');
    _professionController = TextEditingController(text: widget.userData['profession'] ?? '');
    _professionalDetailsController = TextEditingController(text: widget.userData['professionalDetails'] ?? '');
    _companyController = TextEditingController(text: widget.userData['company'] ?? '');
    _workLocationController = TextEditingController(text: widget.userData['workLocation'] ?? '');
    _linkedInController = TextEditingController(text: widget.userData['linkedIn'] ?? '');
    
    // Normalize blood group data (convert old formats like "0+ve" to "O+")
    _selectedBloodGroup = _normalizeBloodGroup(widget.userData['bloodGroup']);
    _selectedHomeDistrict = widget.userData['homeDistrict'];
    _selectedPoloSize = widget.userData['poloSize'];
    _currentPhotoUrl = widget.userData['photoUrl'];
  }
  
  // Helper method to normalize blood group values from old CSV format
  String? _normalizeBloodGroup(String? bloodGroup) {
    if (bloodGroup == null || bloodGroup.isEmpty) return null;
    
    // Convert old CSV formats to standard format
    final normalized = bloodGroup
        .replaceAll('0', 'O')  // Convert zero to letter O
        .replaceAll('ve', '')  // Remove 've' suffix
        .replaceAll('+', '+')  // Ensure + is standard
        .replaceAll('-', '-')  // Ensure - is standard
        .trim()
        .toUpperCase();
    
    // Only return if it's a valid blood group from our list
    if (ProfileConstants.bloodGroups.contains(normalized)) {
      return normalized;
    }
    
    return null;  // Invalid blood group, will show as "Not specified"
  }

  @override
  void dispose() {
    _nickNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    _residentialAreaController.dispose();
    _studentIdController.dispose();
    _registrationIdController.dispose();
    _graduationSubjectController.dispose();
    _graduationInstitutionController.dispose();
    _professionController.dispose();
    _professionalDetailsController.dispose();
    _companyController.dispose();
    _workLocationController.dispose();
    _linkedInController.dispose();
    super.dispose();
  }

  bool _isSuperAdmin() {
    final user = FirebaseService.currentUser;
    return user?.email?.toLowerCase() == 'nayeem.ahmad@gmail.com';
  }

  bool _isCurrentUser() {
    return widget.userId == FirebaseService.currentUser?.uid;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  Future<void> _pickAndCropImage() async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Picture',
              toolbarColor: Colors.blue.shade400,
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Profile Picture',
              aspectRatioLockEnabled: true,
            ),
          ],
        );

        if (croppedFile != null) {
          final photoUrl = await FirebaseService.uploadProfilePicture(
            imageFile: File(croppedFile.path),
            uid: widget.userId,
          );

          setState(() {
            _currentPhotoUrl = photoUrl;
            _isUploadingImage = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() {
            _isUploadingImage = false;
          });
        }
      } else {
        setState(() {
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updates = {
        'nickName': _nickNameController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'bloodGroup': _selectedBloodGroup ?? '',
        'homeDistrict': _selectedHomeDistrict ?? '',
        'phoneNumber': _phoneController.text.trim(),
        'alternatePhone': _altPhoneController.text.trim(),
        'address': _addressController.text.trim(),
        'residentialArea': _residentialAreaController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'registrationId': _registrationIdController.text.trim(),
        'graduationSubject': _graduationSubjectController.text.trim(),
        'graduationInstitution': _graduationInstitutionController.text.trim(),
        'profession': _professionController.text.trim(),
        'professionalDetails': _professionalDetailsController.text.trim(),
        'company': _companyController.text.trim(),
        'workLocation': _workLocationController.text.trim(),
        'poloSize': _selectedPoloSize ?? '',
        'linkedIn': _linkedInController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_currentPhotoUrl != null) {
        updates['photoUrl'] = _currentPhotoUrl!;
      }

      await FirebaseService.updateUserProfile(uid: widget.userId, data: updates);

      setState(() {
        _isSaving = false;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _isSuperAdmin() || _isCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'Profile Details'),
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
        actions: [
          if (canEdit && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit Profile',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _initializeControllers();
                });
              },
              tooltip: 'Cancel',
            ),
        ],
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          _isUploadingImage
                              ? Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.shade100,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 60,
                                      backgroundImage: NetworkImage(_currentPhotoUrl!),
                                    )
                                  : CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        widget.userData['displayName']?.isNotEmpty == true
                                            ? widget.userData['displayName'][0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                          if (_isEditing && canEdit)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade400,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                                  onPressed: _pickAndCropImage,
                                  tooltip: 'Change Photo',
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.userData['displayName'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.userData['email'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.userData['email'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      if (_isCurrentUser())
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Your Profile',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Personal Information Section
                _buildSectionCard(
                  'Personal Information',
                  Icons.person,
                  [
                    _buildTextField('Nickname', _nickNameController, Icons.badge_outlined),
                    _buildDateField('Date of Birth', _dobController, Icons.cake),
                    _buildDropdownField('Blood Group', _selectedBloodGroup, ProfileConstants.bloodGroups, (value) {
                      setState(() => _selectedBloodGroup = value);
                    }, Icons.bloodtype),
                    _buildDropdownField('Home District', _selectedHomeDistrict, ProfileConstants.districts, (value) {
                      setState(() => _selectedHomeDistrict = value);
                    }, Icons.home),
                  ],
                ),

                // Contact Information Section
                _buildSectionCard(
                  'Contact Information',
                  Icons.contact_phone,
                  [
                    _buildTextField('Mobile Number', _phoneController, Icons.phone),
                    _buildTextField('Alternate Phone', _altPhoneController, Icons.phone_android),
                    _buildTextField('Address', _addressController, Icons.location_on, maxLines: 2),
                    _buildTextField('Residential Area', _residentialAreaController, Icons.location_city),
                  ],
                ),

                // Academic Information Section
                _buildSectionCard(
                  'Academic Information',
                  Icons.school,
                  [
                    _buildTextField('Student ID', _studentIdController, Icons.badge),
                    _buildTextField('Registration ID', _registrationIdController, Icons.app_registration),
                    _buildTextField('Graduation Subject', _graduationSubjectController, Icons.menu_book),
                    _buildTextField('Graduation Institution', _graduationInstitutionController, Icons.account_balance),
                  ],
                ),

                // Professional Information Section
                _buildSectionCard(
                  'Professional Information',
                  Icons.work,
                  [
                    _buildTextField('Profession', _professionController, Icons.business_center),
                    _buildTextField('Professional Details', _professionalDetailsController, Icons.description, maxLines: 2),
                    _buildTextField('Company', _companyController, Icons.business),
                    _buildTextField('Work Location', _workLocationController, Icons.pin_drop),
                  ],
                ),

                // Additional Information Section
                _buildSectionCard(
                  'Additional',
                  Icons.more_horiz,
                  [
                    _buildDropdownField('Polo Size', _selectedPoloSize, ProfileConstants.shirtSizes, (value) {
                      setState(() => _selectedPoloSize = value);
                    }, Icons.checkroom),
                    _buildTextField('LinkedIn Profile', _linkedInController, Icons.link),
                  ],
                ),

                // Save Button (only visible when editing)
                if (_isEditing) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        readOnly: true,
        onTap: _isEditing ? _selectDate : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: _isEditing ? const Icon(Icons.calendar_today) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, Function(String?) onChanged, IconData icon) {
    // Only use the value if it exists in the items list, otherwise treat as null
    final validValue = (value != null && value.isNotEmpty && items.contains(value)) ? value : null;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: validValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
        ),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Not specified')),
          ...items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))),
        ],
        onChanged: _isEditing ? onChanged : null,
      ),
    );
  }
}
