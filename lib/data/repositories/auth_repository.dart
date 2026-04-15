import '../models/auth_response_model.dart';
import '../models/member_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthRepository {
  static Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    final response = await ApiService.register(
      email: email,
      password: password,
      inviteCode: inviteCode,
    );

    final authResponse = AuthResponseModel.fromJson(response['data']);

    await StorageService.saveToken(authResponse.accessToken);
    await StorageService.saveMemberData(authResponse.member.toJson());

    return authResponse;
  }

  static Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.login(
      email: email,
      password: password,
    );

    final authResponse = AuthResponseModel.fromJson(response['data']);

    await StorageService.saveToken(authResponse.accessToken);
    await StorageService.saveMemberData(authResponse.member.toJson());

    return authResponse;
  }

  static Future<MemberModel?> getStoredMember() async {
    final data = await StorageService.getMemberData();
    if (data == null) return null;
    return MemberModel.fromJson(data);
  }

  static Future<bool> isLoggedIn() => StorageService.isLoggedIn();

  static Future<void> logout() => StorageService.clearAll();
}