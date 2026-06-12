import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/purchase.dart';

abstract class PurchaseRemoteDataSource {
  Future<List<PurchaseOrder>> getPurchaseOrders();
  Future<PurchaseOrder> createPurchaseOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double gstAmount,
    required double totalAmount,
    String? notes,
  });
  Future<PurchaseOrder> updatePurchaseOrderStatus({
    required String id,
    required String status,
  });
  Future<PurchaseOrder> approvePurchaseOrder({required String id});
  Future<void> receivePurchaseOrder({
    required String id,
    required List<Map<String, dynamic>> receivedItems,
    String? notes,
  });
  Future<List<Supplier>> getSuppliers();
  Future<Supplier> createSupplier({
    required String name,
    required String phone,
    required String email,
    required String gstNumber,
    required String address,
    String? supplierType,
    String? contactPerson,
    String? drugLicenseNumber,
    String? licenseExpiry,
    String? status,
    bool? isPreferred,
    double? rating,
    int? leadTimeDays,
    int? paymentTermsDays,
    double? creditLimit,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
  });
}

class PurchaseRemoteDataSourceImpl implements PurchaseRemoteDataSource {
  final Dio _dio;

  PurchaseRemoteDataSourceImpl(this._dio);

  @override
  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    try {
      final response = await _dio.get('/api/purchase-orders/');
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return list.map((json) => PurchaseOrder.fromJson(json)).toList();
      }
      throw Exception(
        response.data?['message'] ?? 'Failed to load purchase orders',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['error'] ??
            'Network error loading purchase orders',
      );
    }
  }

  @override
  Future<PurchaseOrder> createPurchaseOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double gstAmount,
    required double totalAmount,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/api/purchase-orders/',
        data: {
          'supplierId': supplierId,
          'items': items,
          'subtotal': subtotal,
          'gstAmount': gstAmount,
          'totalAmount': totalAmount,
          if (notes != null) 'notes': notes.trim(),
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return PurchaseOrder.fromJson(response.data['data']);
      }
      throw Exception(
        response.data?['message'] ?? 'Failed to create purchase order',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['error'] ??
            'Network error creating purchase order',
      );
    }
  }

  @override
  Future<PurchaseOrder> updatePurchaseOrderStatus({
    required String id,
    required String status,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/purchase-orders/$id/status',
        data: {'status': status.toUpperCase()},
      );

      if (response.data != null && response.data['success'] == true) {
        return PurchaseOrder.fromJson(response.data['data']);
      }
      throw Exception(response.data?['message'] ?? 'Failed to update status');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['error'] ??
            'Network error updating purchase order status',
      );
    }
  }

  @override
  Future<PurchaseOrder> approvePurchaseOrder({required String id}) async {
    try {
      final response = await _dio.post(
        '/api/purchase-orders/$id/approve',
        data: {},
      );
      if (response.data != null && response.data['success'] == true) {
        return PurchaseOrder.fromJson(response.data['data']);
      }
      throw Exception(
        response.data?['message'] ?? 'Failed to approve purchase order',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['error'] ??
            'Network error approving purchase order',
      );
    }
  }

  @override
  Future<void> receivePurchaseOrder({
    required String id,
    required List<Map<String, dynamic>> receivedItems,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/api/purchase-orders/$id/receive',
        data: {
          'receivedItems': receivedItems,
          if (notes != null) 'notes': notes.trim(),
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return;
      }
      throw Exception(
        response.data?['message'] ?? 'Failed to receive purchase order',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['error'] ??
            'Network error receiving purchase order',
      );
    }
  }

  @override
  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _dio.get('/api/suppliers/');
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return list.map((json) => Supplier.fromJson(json)).toList();
      }
      throw Exception(response.data?['message'] ?? 'Failed to load suppliers');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['error'] ??
            'Network error loading suppliers',
      );
    }
  }

  @override
  Future<Supplier> createSupplier({
    required String name,
    required String phone,
    required String email,
    required String gstNumber,
    required String address,
    String? supplierType,
    String? contactPerson,
    String? drugLicenseNumber,
    String? licenseExpiry,
    String? status,
    bool? isPreferred,
    double? rating,
    int? leadTimeDays,
    int? paymentTermsDays,
    double? creditLimit,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
  }) async {
    try {
      final response = await _dio.post(
        '/api/suppliers/',
        data: {
          'name': name.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
          'gstNumber': gstNumber.trim().toUpperCase(),
          'address': address.trim(),
          'supplierType': ?supplierType,
          if (contactPerson != null) 'contactPerson': contactPerson.trim(),
          if (drugLicenseNumber != null)
            'drugLicenseNumber': drugLicenseNumber.trim().toUpperCase(),
          'licenseExpiry': ?licenseExpiry,
          'status': ?status,
          'isPreferred': ?isPreferred,
          'rating': ?rating,
          'leadTimeDays': ?leadTimeDays,
          'paymentTermsDays': ?paymentTermsDays,
          'creditLimit': ?creditLimit,
          if (bankName != null) 'bankName': bankName.trim(),
          if (accountNumber != null) 'accountNumber': accountNumber.trim(),
          if (ifscCode != null) 'ifscCode': ifscCode.trim().toUpperCase(),
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return Supplier.fromJson(response.data['data']);
      }
      throw Exception(response.data?['message'] ?? 'Failed to create supplier');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== DIO ERROR ===');
      }
      if (kDebugMode) {
        print('STATUS: ${e.response?.statusCode}');
      }
      if (kDebugMode) {
        print('DATA: ${e.response?.data}');
      }
      throw Exception(
        e.response?.data?['error']?['message'] ??
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Network error creating supplier',
      );
    }
  }
}

// Global Injectable PurchaseRemoteDataSource Provider
final purchaseRemoteDataSourceProvider = Provider<PurchaseRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return PurchaseRemoteDataSourceImpl(dio);
});
