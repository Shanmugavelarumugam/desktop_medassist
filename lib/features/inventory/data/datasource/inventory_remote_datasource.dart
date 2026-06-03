import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../../../core/network/dio_client.dart';
import '../../domain/models/medicine.dart';

abstract class InventoryRemoteDataSource {
  Future<List<Medicine>> getMedicines();
  Future<List<MedicineCategory>> getCategories();
  Future<List<Manufacturer>> getManufacturers();
  
  Future<Medicine> createMedicine({
    required String name,
    required String genericName,
    required double mrp,
    required double purchasePrice,
    required String batchNumber,
    required int quantity,
    required String expiryDate,
    required String categoryId,
    String? manufacturerId,
  });

  Future<Medicine> updateMedicine({
    required String id,
    required String name,
    String? genericName,
    String? categoryId,
    String? manufacturerId,
  });

  Future<void> deleteMedicine({required String id});

  Future<void> addBatch({
    required String medicineId,
    required String batchNumber,
    required int quantity,
    required String expiryDate,
    required double purchasePrice,
    required double mrp,
  });
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final Dio _dio;

  InventoryRemoteDataSourceImpl(this._dio);

  @override
  Future<List<Medicine>> getMedicines() async {
    try {
      developer.log("GET MEDICINES CALL STARTED");
      final response = await _dio.get(
        '/api/inventory/medicines',
        queryParameters: {'limit': 500},
      );
      developer.log("GET MEDICINES RESPONSE STATUS: ${response.statusCode}");
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        developer.log("MAPPING ${list.length} MEDICINES FROM JSON...");
        final medicines = list.map((json) {
          try {
            return Medicine.fromJson(json);
          } catch (e, stack) {
            developer.log("ERROR PARSING MEDICINE JSON: $e");
            developer.log("OFFENDING JSON: $json");
            developer.log("STACKTRACE: $stack");
            rethrow;
          }
        }).toList();
        developer.log("MAPPED MEDICINES SUCCESSFULLY.");
        return medicines;
      }
      throw Exception(response.data?['message'] ?? 'Failed to load medicines');
    } on DioException catch (e) {
      developer.log("DIO EXCEPTION FETCHING MEDICINES: ${e.response?.statusCode} - ${e.response?.data}");
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error fetching medicines');
    } catch (e, stack) {
      developer.log("UNEXPECTED ERROR FETCHING MEDICINES: $e");
      developer.log("STACKTRACE: $stack");
      rethrow;
    }
  }

  @override
  Future<List<MedicineCategory>> getCategories() async {
    try {
      final response = await _dio.get('/api/inventory/categories');
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return list.map((json) => MedicineCategory.fromJson(json)).toList();
      }
      throw Exception(response.data?['message'] ?? 'Failed to load categories');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error fetching categories');
    }
  }

  @override
  Future<List<Manufacturer>> getManufacturers() async {
    try {
      final response = await _dio.get('/api/inventory/manufacturers');
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return list.map((json) => Manufacturer.fromJson(json)).toList();
      }
      throw Exception(response.data?['message'] ?? 'Failed to load manufacturers');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error fetching manufacturers');
    }
  }

  @override
  Future<Medicine> createMedicine({
    required String name,
    required String genericName,
    required double mrp,
    required double purchasePrice,
    required String batchNumber,
    required int quantity,
    required String expiryDate,
    required String categoryId,
    String? manufacturerId,
  }) async {
    try {
      final response = await _dio.post('/api/inventory/medicines', data: {
        'name': name.trim(),
        'genericName': genericName.trim(),
        'categoryId': categoryId,
        'gstPercentage': 12.0, // Default for pharmacy
        'manufacturerId': ?manufacturerId,
        'initialBatch': {
          'batchNumber': batchNumber.trim(),
          'expiryDate': expiryDate,
          'quantity': quantity,
          'purchasePrice': purchasePrice,
          'mrp': mrp,
        }
      });

      if (response.data != null && response.data['success'] == true) {
        return Medicine.fromJson(response.data['data']);
      }
      throw Exception(response.data?['message'] ?? 'Failed to create medicine');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error creating medicine');
    }
  }

  @override
  Future<Medicine> updateMedicine({
    required String id,
    required String name,
    String? genericName,
    String? categoryId,
    String? manufacturerId,
  }) async {
    try {
      final response = await _dio.put('/api/inventory/medicines/$id', data: {
        'name': name.trim(),
        'genericName': ?genericName?.trim(),
        'categoryId': ?categoryId,
        'manufacturerId': ?manufacturerId,
      });

      if (response.data != null && response.data['success'] == true) {
        return Medicine.fromJson(response.data['data']);
      }
      throw Exception(response.data?['message'] ?? 'Failed to update medicine');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error updating medicine');
    }
  }

  @override
  Future<void> deleteMedicine({required String id}) async {
    try {
      final response = await _dio.delete('/api/inventory/medicines/$id');
      if (response.data != null && response.data['success'] == true) {
        return;
      }
      throw Exception(response.data?['message'] ?? 'Failed to delete medicine');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error deleting medicine');
    }
  }

  @override
  Future<void> addBatch({
    required String medicineId,
    required String batchNumber,
    required int quantity,
    required String expiryDate,
    required double purchasePrice,
    required double mrp,
  }) async {
    try {
      final response = await _dio.post('/api/inventory/medicines/$medicineId/batches', data: {
        'batchNumber': batchNumber.trim(),
        'quantity': quantity,
        'expiryDate': expiryDate,
        'purchasePrice': purchasePrice,
        'mrp': mrp,
      });
      if (response.data != null && response.data['success'] == true) {
        return;
      }
      throw Exception(response.data?['message'] ?? 'Failed to add batch');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error adding batch');
    }
  }
}

// Global Injectable InventoryRemoteDataSource Provider
final inventoryRemoteDataSourceProvider = Provider<InventoryRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return InventoryRemoteDataSourceImpl(dio);
});
