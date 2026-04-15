class MemberModel {
  final int id;
  final String name;
  final String email;
  final String? employeeId;
  final String? department;
  final String? position;
  final int companyId;

  MemberModel({
    required this.id,
    required this.name,
    required this.email,
    this.employeeId,
    this.department,
    this.position,
    required this.companyId,
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
    };
  }
}