import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/invoice.dart';

abstract class BillingRemoteDataSource {
  Future<Invoice> createInvoice({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double gst,
    required double total,
    required String paymentMethod,
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

  @override
  Future<Invoice> createInvoice({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double gst,
    required double total,
    required String paymentMethod,
    required String notes,
  }) async {
    try {
      final response = await _dio.post('/api/billing/invoices', data: {
        'items': items,
        'subtotal': subtotal,
        'discount': discount,
        'gst': gst,
        'total': total,
        'paymentMethod': paymentMethod,
        'notes': notes,
      });

      if (response.data != null && response.data['success'] == true) {
        return Invoice.fromJson(response.data['data']);
      }
      throw Exception(response.data?['message'] ?? 'Failed to create invoice');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error creating invoice');
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
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error fetching invoices');
    }
  }

  @override
  Future<List<MedicineBatch>> getBatches(String medicineId) async {
    try {
      final response = await _dio.get('/api/inventory/batches', queryParameters: {
        'medicineId': medicineId,
      });
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data']?['batches'] ?? [];
        return list.map((json) => MedicineBatch.fromJson(json)).toList();
      }
      throw Exception(response.data?['message'] ?? 'Failed to load batches');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error fetching batches');
    }
  }

  @override
  Future<Invoice> cancelInvoice({required String id, required String reason}) async {
    try {
      final response = await _dio.post('/api/billing/invoices/$id/cancel', data: {
        'reason': reason,
      });
      if (response.data != null && response.data['success'] == true) {
        return Invoice.fromJson(response.data['data']);
      }
      throw Exception(response.data?['message'] ?? 'Failed to cancel invoice');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error cancelling invoice');
    }
  }

  @override
  Future<Map<String, dynamic>> getDailySummary() async {
    try {
      final response = await _dio.get('/api/billing/daily-summary');
      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data?['message'] ?? 'Failed to fetch daily summary');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error fetching daily summary');
    }
  }

  @override
  Future<Map<String, dynamic>> getPaymentBreakdown() async {
    try {
      final response = await _dio.get('/api/billing/payment-breakdown');
      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data?['message'] ?? 'Failed to fetch payment breakdown');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Network error fetching payment breakdown');
    }
  }
}

// Global Injectable BillingRemoteDataSource Provider
final billingRemoteDataSourceProvider = Provider<BillingRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return BillingRemoteDataSourceImpl(dio);
});
