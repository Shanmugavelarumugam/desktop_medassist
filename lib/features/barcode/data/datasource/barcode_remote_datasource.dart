import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../inventory/domain/models/medicine.dart';

abstract class BarcodeRemoteDataSource {
  Future<Uint8List> generateBarcode({required String text, String type = 'code128'});
  Future<Medicine?> lookupMedicineByBarcode(String barcode);
}

class BarcodeRemoteDataSourceImpl implements BarcodeRemoteDataSource {
  final Dio _dio;

  BarcodeRemoteDataSourceImpl(this._dio);

  @override
  Future<Uint8List> generateBarcode({required String text, String type = 'code128'}) async {
    try {
      final response = await _dio.get(
        '/api/inventory/barcode/generate',
        queryParameters: {
          'text': text,
          'type': type,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data is Uint8List) {
        return response.data as Uint8List;
      } else if (response.data is List<int>) {
        return Uint8List.fromList(response.data as List<int>);
      }
      throw Exception('Invalid response type received from barcode generation');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error generating barcode');
    }
  }

  @override
  Future<Medicine?> lookupMedicineByBarcode(String barcode) async {
    // Try primary endpoint first: /api/inventory/medicines/barcode/{barcode}
    try {
      final response = await _dio.get('/api/inventory/medicines/barcode/$barcode');
      if (response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['success'] == true && data['data'] != null) {
            return Medicine.fromJson(data['data']);
          } else if (data['id'] != null) {
            // Raw Medicine object returned directly
            return Medicine.fromJson(data);
          }
        }
      }
    } catch (e) {
      debugPrint("Primary barcode lookup failed, trying fallback: $e");
    }

    // Try secondary endpoint: /api/medicines/barcode/{barcode}
    try {
      final response = await _dio.get('/api/medicines/barcode/$barcode');
      if (response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['success'] == true && data['data'] != null) {
            return Medicine.fromJson(data['data']);
          } else if (data['id'] != null) {
            return Medicine.fromJson(data);
          }
        }
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Medicine not found with this barcode');
    }

    throw Exception('Medicine not found for barcode: $barcode');
  }
}

final barcodeRemoteDataSourceProvider = Provider<BarcodeRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return BarcodeRemoteDataSourceImpl(dio);
});
