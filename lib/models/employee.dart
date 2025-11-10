class Employee {
  final int id;
  final String fullName;
  final String? profilePictureUrl;

  Employee({required this.id, required this.fullName, this.profilePictureUrl});

factory Employee.fromJson(Map<String, dynamic> json) {
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  return Employee(
    id: _parseInt(json['id']), 
    fullName: json['full_name'] ?? '',
    profilePictureUrl: json['profile_picture_url'],
  );
}
}