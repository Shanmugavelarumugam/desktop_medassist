import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/invoice.dart';

abstract class BillingRemoteDataSource {
  Future<Invoice> createInvoice({
    required List<Map<String, dynamic>> items,
    required String patientName,
    required String patientPhone,
    required double discountAmount,
    required String paymentMode,
    required List<Map<String, dynamic>> payments,
    required String notes,
  });

  Future<List<Invoice>> getInvoices();
  Future<List<MedicineBatch>> getBatches(String medicineId);
  Future<Invoice> cancelInvoice({required String id, required String reason});
  Future<Map<String, dynamic>> getDailySummary();
  Future<Map<String, dynamic>> getPaymentBreakdown();
}

class BillingRemoteDataSourceImpl implements BillingRemoteDataSource {
  final Dio _dio;

  BillingRemoteDataSourceImpl(this._dio);

  /// Safely extract a human-readable error message from a Dio error response.
  ///
  /// The backend can return the `error` field as:
  ///   - a plain String  → `"Medicine X only has 78 stock available"`
  ///   - a nested Map    → `{ "message": "..." }`
  ///
  /// Trying `data['error']['message']` on a String throws
  /// `type 'String' is not a subtype of type 'int' of 'index'`
  /// because Dart interprets `['message']` as a list index.
  String _extractErrorMessage(DioException e, String fallback) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        // Prefer the top-level 'message' field first (most backends set this)
        final topMsg = data['message'];
        if (topMsg is String && topMsg.isNotEmpty) return topMsg;

        // Then try 'error' — may be a String or a nested Map
        final err = data['error'];
        if (err is String && err.isNotEmpty) return err;
        if (err is Map) {
          final nested = err['message'];
          if (nested is String && nested.isNotEmpty) return nested;
        }
      }
    } catch (_) {
      // Never let error-extraction itself throw
    }
    return fallback;
  }

  @override
  Future<Invoice> createInvoice({
    required List<Map<String, dynamic>> items,
    required String patientName,
    required String patientPhone,
    required double discountAmount,
    required String paymentMode,
    required List<Map<String, dynamic>> payments,
    required String notes,
  }) async {
    try {
      final response = await _dio.post(
        '/api/billing/invoices',
        data: {
          'patientName': patientName,
          'patientPhone': patientPhone,
          'discountAmount': discountAmount,
          'discountPercentage': 0,
          'paymentMode': paymentMode,
          'items': items,
          'payments': payments,
          'notes': notes,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return Invoice.fromJson(response.data['data']);
      }
      throw Exception(response.data?['message'] ?? 'Failed to create invoice');
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Network error creating invoice'),
      );
    }
  }

  @override
  Future<List<Invoice>> getInvoices() async {
    try {
      final response = await _dio.get('/api/billing/invoices');
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return list.map((json) => Invoice.fromJson(json)).toList();
      }
      throw Exception(response.data?['message'] ?? 'Failed to load invoices');
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Network error fetching invoices'),
      );
    }
  }

  @override
  Future<List<MedicineBatch>> getBatches(String medicineId) async {
    try {
      final response = await _dio.get(
        '/api/inventory/batches',
        queryParameters: {'medicineId': medicineId},
      );
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data']?['batches'] ?? [];
        return list.map((json) => MedicineBatch.fromJson(json)).toList();
      }
      throw Exception(response.data?['message'] ?? 'Failed to load batches');
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Network error fetching batches'),
      );
    }
  }

  @override
  Future<Invoice> cancelInvoice({
    required String id,
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        '/api/billing/invoices/$id/cancel',
        data: {'reason': reason},
      );
      if (response.data != null && response.data['success'] == true) {
        return Invoice.fromJson(response.data['data']);
      }
      throw Exception(response.data?['message'] ?? 'Failed to cancel invoice');
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Network error cancelling invoice'),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getDailySummary() async {
    try {
      final response = await _dio.get('/api/billing/daily-summary');
      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(
        response.data?['message'] ?? 'Failed to fetch daily summary',
      );
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Network error fetching daily summary'),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getPaymentBreakdown() async {
    try {
      final response = await _dio.get('/api/billing/payment-breakdown');
      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(
        response.data?['message'] ?? 'Failed to fetch payment breakdown',
      );
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Network error fetching payment breakdown'),
      );
    }
  }
}

// Global Injectable BillingRemoteDataSource Provider
final billingRemoteDataSourceProvider = Provider<BillingRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return BillingRemoteDataSourceImpl(dio);
});
