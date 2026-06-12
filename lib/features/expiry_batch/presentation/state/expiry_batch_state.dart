import '../../../billing_pos/domain/models/invoice.dart';

class ExpiryBatchState {
  final List<MedicineBatch> batches;
  final bool isLoading;
  final String? errorMessage;
  final String
  filterStatus; // 'All', 'Active', 'Expired', 'Near Expiry', 'Quarantined'
  final String searchQuery;

  const ExpiryBatchState({
    this.batches = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filterStatus = 'All',
    this.searchQuery = '',
  });

  ExpiryBatchState copyWith({
    List<MedicineBatch>? batches,
    bool? isLoading,
    String? errorMessage,
    String? filterStatus,
    String? searchQuery,
  }) {
    return ExpiryBatchState(
      batches: batches ?? this.batches,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // We pass null explicitly to clear the error
      filterStatus: filterStatus ?? this.filterStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
