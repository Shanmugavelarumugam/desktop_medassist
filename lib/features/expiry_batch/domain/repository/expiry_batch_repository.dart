import '../../../billing_pos/domain/models/invoice.dart';

abstract class ExpiryBatchRepository {
  Future<List<MedicineBatch>> getBatches();
  Future<void> quarantineBatch(String id);
  Future<void> releaseBatch(String id);
  Future<void> recallBatch(String id);
}
