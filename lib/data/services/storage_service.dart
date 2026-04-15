import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveMemberData(Map<String, dynamic> memberData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('member_data', jsonEncode(memberData));
    await prefs.setInt('member_id', memberData['id']);
    await prefs.setInt('company_id', memberData['company_id']);
    await prefs.setBool('is_logged_in', true);
  }

  static Future<Map<String, dynamic>?> getMemberData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('member_data');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}