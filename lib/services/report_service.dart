import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/report_model.dart';

class ReportService {
  final Dio _dio = DioClient().dio;

  // Notifier untuk reaktivitas UI lokal (Riwayat / List)
  static final ValueNotifier<List<ReportModel>> reportsNotifier =
      ValueNotifier<List<ReportModel>>([]);

  static List<ReportModel> get reports => reportsNotifier.value;
  static int get totalSubmitted => reportsNotifier.value.length;
  static int get totalWaiting => reportsNotifier.value.length;

  static void addReport(ReportModel report) {
    reportsNotifier.value = [report, ...reportsNotifier.value];
  }

  /// Mengambil daftar Kecamatan
  Future<List<Map<String, dynamic>>> getKecamatan() async {
    try {
      final response = await _dio.get(ApiConstants.kecamatan);
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error getKecamatan: $e');
      return [];
    }
  }

  /// Mengambil daftar Desa berdasarkan ID Kecamatan
  Future<List<Map<String, dynamic>>> getDesa(int idKecamatan) async {
    try {
      final response = await _dio.get(
        ApiConstants.desa,
        queryParameters: {'id_kecamatan': idKecamatan},
      );
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error getDesa: $e');
      return [];
    }
  }

  /// Mengambil daftar Ruas Jalan berdasarkan ID Desa
  Future<List<Map<String, dynamic>>> getJalan(int idDesa) async {
    try {
      final response = await _dio.get(
        ApiConstants.jalan,
        queryParameters: {'id_desa': idDesa},
      );
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error getJalan: $e');
      return [];
    }
  }

  /// Mengambil daftar Kategori Kerusakan Jalan
  Future<List<Map<String, dynamic>>> getKategori() async {
    try {
      final response = await _dio.get(ApiConstants.kategori);
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error getKategori: $e');
      return [];
    }
  }

  /// Mengambil daftar laporan asli dari Laravel (GET /api/laporan)
  Future<List<ReportModel>> fetchReports() async {
    try {
      final response = await _dio.get(ApiConstants.laporan);

      if (response.data['success'] == true) {
        final List rawList = response.data['data'] ?? [];
        final List<ReportModel> listLaporan = rawList
            .map((item) => ReportModel.fromJson(item))
            .toList();

        // Update notifier agar seluruh UI yang mendengarkan otomatis ter-refresh
        reportsNotifier.value = listLaporan;
        return listLaporan;
      }
      return reportsNotifier.value;
    } catch (e) {
      debugPrint('Error fetchReports: $e');
      return reportsNotifier.value;
    }
  }

  /// Mengirimkan Laporan Baru dengan format Multipart/Form-Data ke Laravel
  Future<Map<String, dynamic>> createReport({
    required int idJalan,
    required int idKategori,
    required String tingkatBahaya, // 'Rendah', 'Sedang', atau 'Bahaya Tinggi'
    required String deskripsi,
    required File imageFile, // Berkas foto fisik dari image_picker
    double? latitude,
    double? longitude,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final fileName = imageFile.path.split('/').last;

      // 1. Kemas form teks dan file ke dalam FormData Dio
      final formData = FormData.fromMap({
        'id_jalan': idJalan,
        'id_kategori': idKategori,
        'tingkat_bahaya': tingkatBahaya,
        'deskripsi': deskripsi,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'foto': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      // 2. Kirim POST request (Token Bearer otomatis dipasang oleh DioClient Interceptor)
      final response = await _dio.post(
        ApiConstants.laporan,
        data: formData,
        onSendProgress: onProgress,
      );

      final resData = response.data;
      if (resData['success'] == true) {
        return {
          'success': true,
          'message': resData['message'] ?? 'Laporan berhasil dikirim!',
          'data': resData['data'],
        };
      }

      return {
        'success': false,
        'message': resData['message'] ?? 'Gagal membuat laporan.',
      };
    } on DioException catch (e) {
      final resData = e.response?.data;
      String errorMessage = 'Gagal mengirim laporan ke server.';

      if (resData is Map) {
        if (resData['message'] != null) {
          errorMessage = resData['message'];
        }
        // Jika ada validasi gagal dari Laravel (errors 422)
        if (resData['errors'] != null && resData['errors'] is Map) {
          final errorsMap = resData['errors'] as Map<String, dynamic>;
          final firstError = errorsMap.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Batas waktu koneksi habis (Timeout).';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Tidak dapat menghubungi server Laravel.';
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan tidak terduga: $e',
      };
    }
  }
}
