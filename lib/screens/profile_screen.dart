import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import '../services/firebase_service.dart';
import '../constants/profile_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Personal Information
  final _nickNameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedBloodGroup;
  String? _selectedHomeDistrict;
  
  // Contact Information
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _residentialAreaController = TextEditingController();
  
  // Academic Information
  final _studentIdController = TextEditingController();
  final _registrationIdController = TextEditingController();
  final _graduationSubjectController = TextEditingController();
  final _graduationInstitutionController = TextEditingController();
  
  // Professional Information
  final _professionController = TextEditingController();
  final _professionalDetailsController = TextEditingController();
  final _companyController = TextEditingController();
  final _workLocationController = TextEditingController();
  
  // Additional
  String? _selectedPoloSize;
  final _linkedInController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    // Personal Information
    _nickNameController.dispose();
    _dobController.dispose();
    
    // Contact Information
    _phoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    _residentialAreaController.dispose();
    
    // Academic Information
    _studentIdController.dispose();
    _registrationIdController.dispose();
    _graduationSubjectController.dispose();
    _graduationInstitutionController.dispose();
    
    // Professional Information
    _professionController.dispose();
    _professionalDetailsController.dispose();
    _companyController.dispose();
    _workLocationController.dispose();
    
    // Additional
    _linkedInController.dispose();
    
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseService.currentUser;
      if (user != null) {
        setState(() {
          _currentPhotoUrl = user.photoURL;
        });
        
        final doc = await FirebaseService.getUserProfile(user.uid);
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            // Personal Information
            _nickNameController.text = data['nickName'] ?? '';
            _dobController.text = data['dateOfBirth'] ?? '';
            _selectedBloodGroup = data['bloodGroup'];
            _selectedHomeDistrict = data['homeDistrict'];
            
            // Contact Information
            _phoneController.text = data['phoneNumber'] ?? '';
            _altPhoneController.text = data['altPhoneNumber'] ?? '';
            _addressController.text = data['address'] ?? '';
            _residentialAreaController.text = data['residentialArea'] ?? '';
            
            // Academic Information
            _studentIdController.text = data['studentId'] ?? '';
            _registrationIdController.text = data['registrationId'] ?? '';
            _graduationSubjectController.text = data['graduationSubject'] ?? '';
            _graduationInstitutionController.text = data['graduationInstitution'] ?? '';
            
            // Professional Information
            _professionController.text = data['profession'] ?? '';
            _professionalDetailsController.text = data['professionalDetails'] ?? '';
            _companyController.text = data['company'] ?? '';
            _workLocationController.text = data['workLocation'] ?? '';
            
            // Additional
            _selectedPoloSize = data['poloSize'];
            _linkedInController.text = data['linkedIn'] ?? '';
            
            // Use custom photo if available, otherwise Google photo
            _currentPhotoUrl = data['photoUrl'] ?? user.photoURL;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    try {
      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      // Crop image with square aspect ratio
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Colors.blue.shade400,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            initAspectRatio: CropAspectRatioPreset.square,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return;

      // Upload to Firebase Storage
      setState(() => _isUploadingImage = true);

      final user = FirebaseService.currentUser;
      if (user != null) {
        final downloadUrl = await FirebaseService.uploadProfilePicture(
          uid: user.uid,
          imageFile: File(croppedFile.path),
        );

        if (downloadUrl != null && mounted) {
          setState(() {
            _currentPhotoUrl = downloadUrl;
            _isUploadingImage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          setState(() => _isUploadingImage = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload profile picture'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Change Profile Picture',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue.shade400),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndCropImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.blue.shade400),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndCropImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade400,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseService.currentUser;
      if (user != null) {
        await FirebaseService.updateUserProfile(
          uid: user.uid,
          data: {
            // Personal Information
            'nickName': _nickNameController.text.trim(),
            'dateOfBirth': _dobController.text.trim(),
            'bloodGroup': _selectedBloodGroup,
            'homeDistrict': _selectedHomeDistrict,
            
            // Contact Information
            'phoneNumber': _phoneController.text.trim(),
            'altPhoneNumber': _altPhoneController.text.trim(),
            'address': _addressController.text.trim(),
            'residentialArea': _residentialAreaController.text.trim(),
            
            // Academic Information
            'studentId': _studentIdController.text.trim(),
            'registrationId': _registrationIdController.text.trim(),
            'graduationSubject': _graduationSubjectController.text.trim(),
            'graduationInstitution': _graduationInstitutionController.text.trim(),
            
            // Professional Information
            'profession': _professionController.text.trim(),
            'professionalDetails': _professionalDetailsController.text.trim(),
            'company': _companyController.text.trim(),
            'workLocation': _workLocationController.text.trim(),
            
            // Additional
            'poloSize': _selectedPoloSize,
            'linkedIn': _linkedInController.text.trim(),
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
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
              // Header with Profile Pic and Name/Email
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture with Change Button
                  Stack(
                    children: [
                      _isUploadingImage
                          ? Container(
                              width: 80,
                              height: 80,
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
                                  radius: 40,
                                  backgroundImage: NetworkImage(_currentPhotoUrl!),
                                  backgroundColor: Colors.blue.shade100,
                                )
                              : CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.blue.shade400,
                                  ),
                                ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  // Name and Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'User',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'No email',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionCard(
                title: 'Personal Information',
                children: [
                  _buildTextField(
                    controller: _nickNameController,
                    label: 'Nick Name',
                    icon: Icons.person_outline,
                    hint: 'Enter your nick name',
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(
                    controller: _dobController,
                    label: 'Date of Birth',
                    icon: Icons.cake,
                    hint: 'Select your date of birth',
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Blood Group',
                    icon: Icons.bloodtype,
                    value: _selectedBloodGroup,
                    items: ProfileConstants.bloodGroups,
                    hint: 'Select blood group',
                    onChanged: (value) => setState(() => _selectedBloodGroup = value),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Home District',
                    icon: Icons.home,
                    value: _selectedHomeDistrict,
                    items: ProfileConstants.districts,
                    hint: 'Select home district',
                    onChanged: (value) => setState(() => _selectedHomeDistrict = value),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contact Information Section
              _buildSectionCard(
                title: 'Contact Information',
                children: [
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Mobile Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    hint: 'Enter your mobile number',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _altPhoneController,
                    label: 'Alternative Mobile (Optional)',
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                    hint: 'Enter alternative number',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Current Address',
                    icon: Icons.location_on,
                    hint: 'Enter your current address',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _residentialAreaController,
                    label: 'Residential Area (Optional)',
                    icon: Icons.location_city,
                    hint: 'e.g., Dhanmondi, Dhaka',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Academic Information Section
              _buildSectionCard(
                title: 'Academic Information',
                children: [
                  _buildTextField(
                    controller: _studentIdController,
                    label: 'NDC Student ID (Roll #)',
                    icon: Icons.badge,
                    hint: 'Enter your NDC roll number',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _registrationIdController,
                    label: 'Registration ID (Optional)',
                    icon: Icons.numbers,
                    hint: 'Enter registration ID',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _graduationSubjectController,
                    label: 'Graduation Subject (Optional)',
                    icon: Icons.school,
                    hint: 'e.g., Economics, Physics, etc.',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _graduationInstitutionController,
                    label: 'Graduation Institution (Optional)',
                    icon: Icons.account_balance,
                    hint: 'e.g., Dhaka University',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Professional Information Section
              _buildSectionCard(
                title: 'Professional Information',
                children: [
                  _buildTextField(
                    controller: _professionController,
                    label: 'Profession (Optional)',
                    icon: Icons.work,
                    hint: 'e.g., Doctor, Engineer, Banker',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _professionalDetailsController,
                    label: 'Professional Details (Optional)',
                    icon: Icons.description,
                    hint: 'Designation, responsibilities, etc.',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _companyController,
                    label: 'Company/Organization (Optional)',
                    icon: Icons.business,
                    hint: 'Enter company name',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _workLocationController,
                    label: 'Work Location (Optional)',
                    icon: Icons.location_city,
                    hint: 'e.g., Dhaka, Bangladesh',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Additional Information Section
              _buildSectionCard(
                title: 'Additional Information',
                children: [
                  _buildDropdownField(
                    label: 'Polo/T-Shirt Size (Optional)',
                    icon: Icons.checkroom,
                    value: _selectedPoloSize,
                    items: ProfileConstants.shirtSizes,
                    hint: 'Select your size',
                    onChanged: (value) => setState(() => _selectedPoloSize = value),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _linkedInController,
                    label: 'LinkedIn Profile (Optional)',
                    icon: Icons.link,
                    hint: 'Enter LinkedIn URL',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade400),
        suffixIcon: Icon(Icons.calendar_today, color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}