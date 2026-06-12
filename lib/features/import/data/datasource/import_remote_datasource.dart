import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/import_job.dart';

abstract class ImportRemoteDataSource {
  Future<List<ImportJob>> getImportHistory();
  Future<ImportJob> uploadPdfInvoice(String filePath, String fileName);
  Future<ImportJob> uploadSupplierInvoice(String filePath, String fileName);
  Future<Map<String, dynamic>> importBulk({
    required List<Map<String, dynamic>> medicines,
    required String supplier,
    required String duplicateStrategy,
    required Map<String, dynamic> barcodeOptions,
    required bool dryRun,
  });
  Future<Map<String, dynamic>> uploadImportFile({
    required String fileName,
    required String fileContent,
    required String duplicateStrategy,
    required Map<String, dynamic> barcodeOptions,
  });
  Future<Map<String, dynamic>> getImportStatus(String jobId);
}

class ImportRemoteDataSourceImpl implements ImportRemoteDataSource {
  final Dio _dio;

  ImportRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ImportJob>> getImportHistory() async {
    try {
      final response = await _dio.get('/api/import/history');
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return list.map((json) => ImportJob.fromJson(json)).toList();
      }
      throw Exception(
        response.data?['message'] ?? 'Failed to load import history',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['error'] ??
            'Network error loading import history',
      );
    }
  }

  @override
  Future<ImportJob> uploadPdfInvoice(String filePath, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        '/api/import/pdf-invoice',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.data != null && response.data['success'] == true) {
        return ImportJob.fromJson(response.data['data']);
      }
      throw Exception(
        response.data?['message'] ?? 'Failed to upload PDF invoice',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['error'] ??
            'Network error uploading PDF invoice',
      );
    }
  }

  @override
  Future<ImportJob> uploadSupplierInvoice(
    String filePath,
    String fileName,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        '/api/import/supplier-invoice',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.data != null && response.data['success'] == true) {
        return ImportJob.fromJson(response.data['data']);
      }
      throw Exception(
        response.data?['message'] ?? 'Failed to upload supplier invoice',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['error'] ??
            'Network error uploading supplier invoice',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> importBulk({
    required List<Map<String, dynamic>> medicines,
    required String supplier,
    required String duplicateStrategy,
    required Map<String, dynamic> barcodeOptions,
    required bool dryRun,
  }) async {
    try {
      final response = await _dio.post(
        '/api/import/bulk',
        data: {
          'medicines': medicines,
          'supplier': supplier,
          'duplicateStrategy': duplicateStrategy,
          'barcodeOptions': barcodeOptions,
          'dryRun': dryRun,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        return response.data;
      }
      throw Exception(response.data?['message'] ?? 'Bulk import failed');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['error'] ??
            'Network error in bulk import',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> uploadImportFile({
    required String fileName,
    required String fileContent,
    required String duplicateStrategy,
    required Map<String, dynamic> barcodeOptions,
  }) async {
    try {
      final response = await _dio.post(
        '/api/import/upload',
        data: {
          'fileName': fileName,
          'fileContent': fileContent,
          'duplicateStrategy': duplicateStrategy,
          'barcodeOptions': barcodeOptions,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        return response.data;
      }
      throw Exception(response.data?['message'] ?? 'Import upload failed');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['error'] ??
            'Network error uploading import file',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getImportStatus(String jobId) async {
    try {
      final response = await _dio.get('/api/import/status/$jobId');
      if (response.data != null && response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        response.data?['message'] ?? 'Failed to get import status',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['error'] ??
            'Network error fetching import status',
      );
    }
  }
}

// Global Injectable ImportRemoteDataSource Provider
final importRemoteDataSourceProvider = Provider<ImportRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ImportRemoteDataSourceImpl(dio);
});
