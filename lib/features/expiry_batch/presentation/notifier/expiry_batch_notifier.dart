import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../inventory/presentation/notifier/inventory_notifier.dart';
import '../../data/repository/expiry_batch_repository_impl.dart';
import '../../domain/repository/expiry_batch_repository.dart';
import '../state/expiry_batch_state.dart';

class ExpiryBatchNotifier extends Notifier<ExpiryBatchState> {
  late final ExpiryBatchRepository _repository;

  @override
  ExpiryBatchState build() {
    _repository = ref.watch(expiryBatchRepositoryProvider);
    Future.microtask(() {
      loadBatches();
    });
    return const ExpiryBatchState();
  }

  Future<void> loadBatches() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getBatches();
      state = state.copyWith(batches: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> quarantineBatch(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.quarantineBatch(id);
      // Refresh inventory stock amounts so the main screen updates instantly!
      ref.read(inventoryNotifierProvider.notifier).loadInventory();
      // Reload batches list
      await loadBatches();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> releaseBatch(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.releaseBatch(id);
      // Refresh inventory stock amounts so the main screen updates instantly!
      ref.read(inventoryNotifierProvider.notifier).loadInventory();
      // Reload batches list
      await loadBatches();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> recallBatch(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.recallBatch(id);
      // Refresh inventory stock amounts so the main screen updates instantly!
      ref.read(inventoryNotifierProvider.notifier).loadInventory();
      // Reload batches list
      await loadBatches();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void setFilterStatus(String status) {
    state = state.copyWith(filterStatus: status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final expiryBatchNotifierProvider =
    NotifierProvider<ExpiryBatchNotifier, ExpiryBatchState>(ExpiryBatchNotifier.new);
