import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../billing_pos/domain/models/invoice.dart';
import '../../domain/repository/expiry_batch_repository.dart';
import '../datasource/expiry_batch_remote_datasource.dart';

class ExpiryBatchRepositoryImpl implements ExpiryBatchRepository {
  final ExpiryBatchRemoteDataSource _remoteDataSource;

  ExpiryBatchRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<MedicineBatch>> getBatches() {
    return _remoteDataSource.getBatches();
  }

  @override
  Future<void> quarantineBatch(String id) {
    return _remoteDataSource.quarantineBatch(id);
  }

  @override
  Future<void> releaseBatch(String id) {
    return _remoteDataSource.releaseBatch(id);
  }

  @override
  Future<void> recallBatch(String id) {
    return _remoteDataSource.recallBatch(id);
  }
}

final expiryBatchRepositoryProvider = Provider<ExpiryBatchRepository>((ref) {
  final dataSource = ref.watch(expiryBatchRemoteDataSourceProvider);
  return ExpiryBatchRepositoryImpl(dataSource);
});
