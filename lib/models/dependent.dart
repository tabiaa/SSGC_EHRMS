class Dependent {
  final int id;
  final int employeeId;
  final String relationshipType;
  final String name;
  final String? dateOfBirth; 
  final bool medicalElsewhere;
  final String? familyNo;
  final String? bloodGroup;
  final String? cnic;
  final String? profilePictureUrl;
  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final String? bformUrl;
  final bool isPrepopulated;

  Dependent({
    required this.id,
    required this.employeeId,
    required this.relationshipType,
    required this.name,
    this.dateOfBirth,
    required this.medicalElsewhere,
    this.familyNo,
    this.bloodGroup,
    this.cnic,
    this.profilePictureUrl,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.bformUrl,
    required this.isPrepopulated,
  });

 factory Dependent.fromJson(Map<String, dynamic> json) {
  
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }


  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value == 'true';
    }
    return false;
  }

  return Dependent(
    id: _parseInt(json['id']),
    employeeId: _parseInt(json['employee_id']),
    relationshipType: json['relationship_type'] ?? '',
    name: json['name'] ?? '',
    dateOfBirth: json['date_of_birth'],
    medicalElsewhere: _parseBool(json['medical_elsewhere']),
    familyNo: json['family_no'],
    bloodGroup: json['blood_group'],
    cnic: json['cnic'],
    profilePictureUrl: json['profile_picture_url'],
    cnicFrontUrl: json['cnic_front_url'],
    cnicBackUrl: json['cnic_back_url'],
    bformUrl: json['bform_url'],
    isPrepopulated: _parseBool(json['is_prepopulated']),
  );
}
}