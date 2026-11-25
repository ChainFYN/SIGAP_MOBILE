import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';

class AuthService {
  final Dio _dio = DioClient().dio;

  /// Melakukan login ke backend Laravel
  Future<Map<String, dynamic>> login({
    required String login, // NIK (16 digit) atau Email
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'login': login, 'password': password},
      );

      final data = response.data;
      if (data['success'] == true && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();

        // 1. Simpan Token Sanctum
        await prefs.setString('auth_token', data['token']);

        // 2. Simpan Data Profil Pengguna
        if (data['data'] != null) {
          await prefs.setString('user_profile', jsonEncode(data['data']));
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Login berhasil',
          'token': data['token'],
          'data': data['data'],
        };
      }

      return {'success': false, 'message': data['message'] ?? 'Login gagal'};
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String errorMessage = 'Gagal terhubung ke server';

      if (responseData is Map && responseData['message'] != null) {
        errorMessage = responseData['message'];
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Batas waktu koneksi terlampaui (timeout)';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Tidak dapat menghubungi server. Pastikan IP server sesuai dan server aktif.';
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan tidak terduga: $e',
      };
    }
  }

  /// Logout dari server dan hapus sesi lokal
  Future<void> logout() async {
    try {
      await _dio.post('${ApiConstants.baseUrl}/logout');
    } catch (_) {
      // Abaikan jika network error saat logout
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_profile');
  }

  /// Ambil token Sanctum yang tersimpan
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Ambil profil pengguna yang tersimpan
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('user_profile');
    if (profileJson != null && profileJson.isNotEmpty) {
      return jsonDecode(profileJson) as Map<String, dynamic>;
    }
    return null;
  }

  /// Cek apakah pengguna sudah login
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
