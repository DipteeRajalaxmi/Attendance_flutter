class MemberModel {
  final int id;
  final String name;
  final String email;
  final String? employeeId;
  final String? department;
  final String? position;
  final int companyId;
  final String? registeredAt;

  MemberModel({
    required this.id,
    required this.name,
    required this.email,
    this.employeeId,
    this.department,
    this.position,
    required this.companyId,
    this.registeredAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      employeeId: json['employee_id'],
      department: json['department'],
      position: json['position'],
      companyId: json['company_id'],
      registeredAt: json['mobile_registered_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'employee_id': employeeId,
      'department': department,
      'position': position,
      'company_id': companyId,
      'mobile_registered_at': registeredAt,
    };
  }
}