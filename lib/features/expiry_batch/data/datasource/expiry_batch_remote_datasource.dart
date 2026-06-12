import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../billing_pos/domain/models/invoice.dart';

abstract class ExpiryBatchRemoteDataSource {
  Future<List<MedicineBatch>> getBatches();
  Future<void> quarantineBatch(String id);
  Future<void> releaseBatch(String id);
  Future<void> recallBatch(String id);
}

class ExpiryBatchRemoteDataSourceImpl implements ExpiryBatchRemoteDataSource {
  final Dio _dio;

  ExpiryBatchRemoteDataSourceImpl(this._dio);

  @override
  Future<List<MedicineBatch>> getBatches() async {
    try {
      final response = await _dio.get('/api/inventory/batches');
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data']?['batches'] ?? [];
        return list.map((json) => MedicineBatch.fromJson(json)).toList();
      }
      throw Exception(response.data?['message'] ?? 'Failed to load batches');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Network error fetching batches',
      );
    }
  }

  @override
  Future<void> quarantineBatch(String id) async {
    try {
      final response = await _dio.post('/api/batches/$id/quarantine', data: {});
      if (response.data == null || response.data['success'] != true) {
        throw Exception(
          response.data?['message'] ?? 'Failed to quarantine batch',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Network error quarantining batch',
      );
    }
  }

  @override
  Future<void> releaseBatch(String id) async {
    try {
      final response = await _dio.post('/api/batches/$id/release', data: {});
      if (response.data == null || response.data['success'] != true) {
        throw Exception(response.data?['message'] ?? 'Failed to release batch');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Network error releasing batch',
      );
    }
  }

  @override
  Future<void> recallBatch(String id) async {
    try {
      final response = await _dio.post('/api/batches/$id/recall', data: {});
      if (response.data == null || response.data['success'] != true) {
        throw Exception(response.data?['message'] ?? 'Failed to recall batch');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Network error recalling batch',
      );
    }
  }
}

final expiryBatchRemoteDataSourceProvider =
    Provider<ExpiryBatchRemoteDataSource>((ref) {
      final dio = ref.watch(dioProvider);
      return ExpiryBatchRemoteDataSourceImpl(dio);
    });
