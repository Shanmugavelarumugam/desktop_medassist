import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../../../core/network/dio_client.dart';
import '../../domain/models/medicine.dart';

abstract class InventoryRemoteDataSource {
  Future<List<Medicine>> getMedicines({String? search, int? limit});
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
    double? gstPercentage,
    int? reorderLevel,
    bool? prescriptionRequired,
    String? hsnCode,
    String? barcode,
    String? supplier,
    String? notes,
  });

  Future<Medicine> updateMedicine({
    required String id,
    required String name,
    String? genericName,
    String? categoryId,
    String? manufacturerId,
    double? gstPercentage,
    int? reorderLevel,
    bool? prescriptionRequired,
    String? hsnCode,
    String? barcode,
    String? supplier,
    String? notes,
  });

  Future<void> deleteMedicine({required String id});

  Future<Map<String, dynamic>> getSummary();

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
  Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await _dio.get('/api/inventory/summary');
      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(
        response.data?['message'] ?? 'Failed to load inventory summary',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Network error fetching inventory summary',
      );
    }
  }

  @override
  Future<List<Medicine>> getMedicines({String? search, int? limit}) async {
    try {
      developer.log("GET MEDICINES CALL STARTED");
      final queryParams = <String, dynamic>{'limit': limit ?? 1000};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      final response = await _dio.get(
        '/api/inventory/medicines',
        queryParameters: queryParams,
      );
      developer.log("GET MEDICINES RESPONSE STATUS: ${response.statusCode}");
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final List list;
        if (data is List) {
          list = data;
        } else if (data is Map && data['items'] is List) {
          list = data['items'];
        } else {
          list = [];
        }
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
        developer.log("LOADED ${medicines.length} MEDICINES SUCCESSFULLY.");

        return medicines;
      }
      throw Exception(response.data?['message'] ?? 'Failed to load medicines');
    } on DioException catch (e) {
      developer.log(
        "DIO EXCEPTION FETCHING MEDICINES: ${e.response?.statusCode} - ${e.response?.data}",
      );
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Network error fetching medicines',
      );
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
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Network error fetching categories',
      );
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
      throw Exception(
        response.data?['message'] ?? 'Failed to load manufacturers',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Network error fetching manufacturers',
      );
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
    double? gstPercentage,
    int? reorderLevel,
    bool? prescriptionRequired,
    String? hsnCode,
    String? barcode,
    String? supplier,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/api/inventory/medicines',
        data: {
          'name': name.trim(),
          'genericName': genericName.trim(),
          'categoryId': categoryId,
          'gstPercentage': gstPercentage ?? 12.0,
          'reorderLevel': reorderLevel ?? 10,
          'prescriptionRequired': prescriptionRequired ?? false,
          'manufacturerId': ?manufacturerId,
          'hsnCode': ?hsnCode?.trim(),
          'barcode': ?barcode?.trim(),
          'supplier': ?supplier?.trim(),
          'notes': ?notes?.trim(),
          'initialBatch': {
            'batchNumber': batchNumber.trim(),
            'expiryDate': expiryDate,
            'quantity': quantity,
            'purchasePrice': purchasePrice,
            'mrp': mrp,
          },
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return Medicine.fromJson(response.data['data']);
      }
      throw Exception(response.data?['message'] ?? 'Failed to create medicine');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Network error creating medicine',
      );
    }
  }

  @override
  Future<Medicine> updateMedicine({
    required String id,
    required String name,
    String? genericName,
    String? categoryId,
    String? manufacturerId,
    double? gstPercentage,
    int? reorderLevel,
    bool? prescriptionRequired,
    String? hsnCode,
    String? barcode,
    String? supplier,
    String? notes,
  }) async {
    try {
      final response = await _dio.put(
        '/api/inventory/medicines/$id',
        data: {
          'name': name.trim(),
          'genericName': ?genericName?.trim(),
          'categoryId': ?categoryId,
          'manufacturerId': ?manufacturerId,
          'gstPercentage': ?gstPercentage,
          'reorderLevel': ?reorderLevel,
          'prescriptionRequired': ?prescriptionRequired,
          'hsnCode': ?hsnCode?.trim(),
          'barcode': ?barcode?.trim(),
          'supplier': ?supplier?.trim(),
          'notes': ?notes?.trim(),
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return Medicine.fromJson(response.data['data']);
      }
      throw Exception(response.data?['message'] ?? 'Failed to update medicine');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Network error updating medicine',
      );
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
      throw Exception(
        e.response?.data?['error']?['message'] ??
            'Network error deleting medicine',
      );
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
      final response = await _dio.post(
        '/api/inventory/medicines/$medicineId/batches',
        data: {
          'batchNumber': batchNumber.trim(),
          'quantity': quantity,
          'expiryDate': expiryDate,
          'purchasePrice': purchasePrice,
          'mrp': mrp,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        return;
      }
      throw Exception(response.data?['message'] ?? 'Failed to add batch');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ?? 'Network error adding batch',
      );
    }
  }
}

// Global Injectable InventoryRemoteDataSource Provider
final inventoryRemoteDataSourceProvider = Provider<InventoryRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return InventoryRemoteDataSourceImpl(dio);
});
