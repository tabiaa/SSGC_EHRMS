// screens/dependent_detail_form.dart
import 'dart:io';
import 'dart:math' as math; // ✅ for min()
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' show Dio, FormData, MultipartFile, Options;
import 'package:http_parser/http_parser.dart';
// ✅ explicit import
import '../models/dependent.dart';
import '../services/api_service.dart';

// 🔍 ML Kit + Image Processing
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart'; // ✅ resolved

class DependentDetailForm extends StatefulWidget {
  final Dependent dependent;
  final VoidCallback onUpdated;

  const DependentDetailForm({
    required this.dependent,
    required this.onUpdated,
    Key? key,
  }) : super(key: key);

  @override
  _DependentDetailFormState createState() => _DependentDetailFormState();
}

class _DependentDetailFormState extends State<DependentDetailForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _editableFields;
  bool _uploading = false;

  Map<String, File?> _selectedFiles = {};
  Set<String> _lockedFields = {};

  final Color primaryOrange = const Color(0xFFFF6F00);

  @override
  void initState() {
    super.initState();
    _editableFields = {
      'relationship_type': widget.dependent.relationshipType,
      'name': widget.dependent  .name,
      'date_of_birth': widget.dependent.dateOfBirth,
      'medical_elsewhere': widget.dependent.medicalElsewhere,
      'blood_group': widget.dependent.bloodGroup,
      'cnic': widget.dependent.cnic,
    };

    _selectedFiles = {
      'profile_picture': null,
      'cnic_front': null,
      'cnic_back': null,
      'bform': null,
    };

    if (widget.dependent.profilePictureUrl?.isNotEmpty == true) _lockedFields.add('profile_picture');
    if (widget.dependent.cnicFrontUrl?.isNotEmpty == true) _lockedFields.add('cnic_front');
    if (widget.dependent.cnicBackUrl?.isNotEmpty == true) _lockedFields.add('cnic_back');
    if (widget.dependent.bformUrl?.isNotEmpty == true) _lockedFields.add('bform');
  }

  bool _isEditable(String key) {
    final value = _getFieldValue(key);
    if (key == 'medical_elsewhere') return true;
    return value == null || value == '';
  }

  dynamic _getFieldValue(String key) {
    switch (key) {
      case 'relationship_type':
        return widget.dependent.relationshipType;
      case 'name':
        return widget.dependent.name;
      case 'date_of_birth':
        return widget.dependent.dateOfBirth;
      case 'medical_elsewhere':
        return widget.dependent.medicalElsewhere;
      case 'blood_group':
        return widget.dependent.bloodGroup;
      case 'cnic':
        return widget.dependent.cnic;
      default:
        return null;
    }
  }

  bool _isFieldLocked(String fieldKey) => _lockedFields.contains(fieldKey);

  Future<void> _pickFile(String fieldKey) async {
    if (_isFieldLocked(fieldKey)) return;

    final picker = ImagePicker();
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt, color: primaryOrange),
            title: const Text('Capture from Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.image, color: primaryOrange),
            title: const Text('Select from Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (choice == null) return;
    final XFile? xFile = await picker.pickImage(source: choice);
    if (xFile == null) return;

    if (fieldKey == 'profile_picture') {
      final croppedFile = await _detectAndCropFace(File(xFile.path));
      if (croppedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please upload a clear photo with exactly one face.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      setState(() => _selectedFiles[fieldKey] = croppedFile);
    } else {
      setState(() => _selectedFiles[fieldKey] = File(xFile.path));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fieldKey selected'),
        backgroundColor: primaryOrange,
      ),
    );
  }

  Future<File?> _detectAndCropFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    // ✅ landmarkMode REMOVED in v0.10+
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    try {
      final List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.length != 1) return null;

      final face = faces.first;
      final Rect rect = face.boundingBox;

      final originalImage = img.decodeImage(imageFile.readAsBytesSync())!;
      final width = originalImage.width;
      final height = originalImage.height;

      final padding = 0.15;
      final cropSize = rect.width * (1 + padding);
      final cropHalf = cropSize / 2;

      final centerX = rect.left + rect.width / 2;
      final centerY = rect.top + rect.height / 2;

      int left = (centerX - cropHalf).toInt().clamp(0, width);
      int top = (centerY - cropHalf).toInt().clamp(0, height);
      int right = (centerX + cropHalf).toInt().clamp(0, width);
      int bottom = (centerY + cropHalf).toInt().clamp(0, height);

      final cropWidth = right - left;
      final cropHeight = bottom - top;
      // ✅ Use math.min and toInt
      final size = math.min(cropWidth, cropHeight).toInt();
      right = left + size;
      bottom = top + size;

      // ✅ Named parameters for copyCrop
      final cropped = img.copyCrop(originalImage, x: left, y: top, width: size, height: size);
      final resized = img.copyResize(cropped, width: 400, height: 400);

      // ✅ getTemporaryDirectory now works
      final tempDir = await getTemporaryDirectory();
      final outputPath = p.join(tempDir.path, 'face_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(resized, quality: 90));

      return outputFile;
    } catch (e) {
      debugPrint('Face detection failed: $e');
      return null;
    }
  }

Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();

  final textUpdates = <String, dynamic>{};
  _editableFields.forEach((key, newValue) {
    final originalValue = _getFieldValue(key);
    if (key == 'medical_elsewhere') {
      if ((originalValue == true) != (newValue == true)) {
        textUpdates[key] = newValue;
      }
    } else {
      if ((originalValue == null || originalValue == '') &&
          (newValue != null && newValue != '')) {
        textUpdates[key] = newValue;
      }
    }
  });

  try {
    setState(() => _uploading = true);

    // 🔹 Upload selected files using ApiService.uploadFile()
    for (var fieldKey in _selectedFiles.keys) {
      final file = _selectedFiles[fieldKey];
      if (file != null && !_isFieldLocked(fieldKey)) {
        print("📤 Uploading $fieldKey for dependent ${widget.dependent.id}");
        final res = await ApiService.uploadFile(
          widget.dependent.id,
          fieldKey,
          file.path,
        );
        print("✅ Upload response for $fieldKey: $res");

        if (res['success'] != true) {
          throw Exception(res['message'] ?? 'Upload failed');
        }

        _lockedFields.add(fieldKey);
      }
    }

    // 🔹 Send text field updates
    if (textUpdates.isNotEmpty) {
      print("📝 Sending text updates: $textUpdates");
      final res = await ApiService.updateDependent(
        widget.dependent.id,
        textUpdates,
      );
      print("✅ Text update response: $res");

      if (res['success'] != true) {
        throw Exception(res['message'] ?? 'Update failed');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Updated successfully!'),
        backgroundColor: primaryOrange,
      ),
    );

    widget.onUpdated();
    Navigator.pop(context);
  } catch (e) {
    print("❌ Error during submit: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.redAccent,
      ),
    );
  } finally {
    setState(() => _uploading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    const Color ssgcOrange = Color(0xFFEA7600);
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.dependent.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryOrange,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: primaryOrange),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Dependent Details',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ssgcOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ssgcOrange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: ssgcOrange, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Important Note",
                              style: TextStyle(
                                color: Color(0xFF5A3B00),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Once your information is submitted, it cannot be changed later. "
                              "Please ensure that all details are accurate before submission.",
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.4,
                                color: ssgcOrange.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade100,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildField('Name', 'name', TextInputType.text),
                      _buildField('Relationship', 'relationship_type', TextInputType.text),
                      _buildField('CNIC', 'cnic', TextInputType.text),
                      _buildField('Blood Group', 'blood_group', TextInputType.text),
                      _buildDateField(),
                      _buildMedicalSwitch(),
                      const SizedBox(height: 20),

                      _uploading
                          ? const CircularProgressIndicator()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildUploadButton('Profile Picture', 'profile_picture'),
                                _buildUploadButton('CNIC Front', 'cnic_front'),
                                _buildUploadButton('CNIC Back', 'cnic_back'),
                                _buildUploadButton('B-Form', 'bform'),
                              ],
                            ),

                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'Submit Updates',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String key, TextInputType inputType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: _getFieldValue(key)?.toString(),
        enabled: _isEditable(key),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primaryOrange),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryOrange, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        keyboardType: inputType,
        onSaved: (v) => _editableFields[key] = v,
      ),
    );
  }

  Widget _buildDateField() {
    final currentValue = _getFieldValue('date_of_birth')?.toString() ?? '';
    final enabled = _isEditable('date_of_birth');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Theme(
  data: Theme.of(context).copyWith(disabledColor: Colors.black54),
        child: TextFormField(
          enabled: enabled,
          controller: TextEditingController(text: currentValue),
          decoration: InputDecoration(
            labelText: 'Date of Birth (YYYY-MM-DD)',
            labelStyle: TextStyle(color: primaryOrange),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryOrange, width: 2),
              borderRadius: BorderRadius.circular(15),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
          keyboardType: TextInputType.datetime,
          onSaved: (v) => _editableFields['date_of_birth'] = v,
          validator: (v) {
            if (v != null && v.isNotEmpty) {
              if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
                return 'Invalid date format (use YYYY-MM-DD)';
              }
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildMedicalSwitch() {
    return SwitchListTile(
      title: Text('Medical Elsewhere', style: TextStyle(color: primaryOrange)),
      value: _editableFields['medical_elsewhere'] ?? false,
      onChanged: (bool? value) {
        setState(() => _editableFields['medical_elsewhere'] = value!);
      },
      activeColor: Color(0xFF003366),
      inactiveThumbColor: Colors.grey[400],
      inactiveTrackColor: Colors.grey[200],
      activeTrackColor: Colors.orangeAccent.withOpacity(0.3),
    );
  }

  Widget _buildUploadButton(String label, String fieldKey) {
    bool hasServerFile = false;
    if (fieldKey == 'profile_picture') {
      hasServerFile = widget.dependent.profilePictureUrl?.isNotEmpty == true;
    } else if (fieldKey == 'cnic_front') {
      hasServerFile = widget.dependent.cnicFrontUrl?.isNotEmpty == true;
    } else if (fieldKey == 'cnic_back') {
      hasServerFile = widget.dependent.cnicBackUrl?.isNotEmpty == true;
    } else if (fieldKey == 'bform') {
      hasServerFile = widget.dependent.bformUrl?.isNotEmpty == true;
    }

    final isLocked = _isFieldLocked(fieldKey);
    final isSelected = _selectedFiles[fieldKey] != null;
    final isDone = isLocked || hasServerFile || isSelected;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        onPressed: isLocked ? null : () => _pickFile(fieldKey),
        icon: Icon(
          isDone ? Icons.check_circle : Icons.upload_file,
          color: Colors.white,
        ),
        label: Text(
          isDone ? '$label ✓' : 'Upload $label',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDone ? Colors.green : primaryOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: isDone ? 2 : 5,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}