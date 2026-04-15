import 'member_model.dart';


class AuthResponseModel {
  final MemberModel member;
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  AuthResponseModel({
    required this.member,
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      member: MemberModel.fromJson(json['member']),
      accessToken: json['auth']['access_token'],
      tokenType: json['auth']['token_type'],
      expiresIn: json['auth']['expires_in'],
    );
  }
}