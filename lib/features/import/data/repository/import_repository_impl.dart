import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repository/import_repository.dart';
import '../../domain/models/import_job.dart';
import '../datasource/import_remote_datasource.dart';

class ImportRepositoryImpl implements ImportRepository {
  final ImportRemoteDataSource _remoteDataSource;

  ImportRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ImportJob>> getImportHistory() {
    return _remoteDataSource.getImportHistory();
  }

  @override
  Future<ImportJob> uploadPdfInvoice(String filePath, String fileName) {
    return _remoteDataSource.uploadPdfInvoice(filePath, fileName);
  }

  @override
  Future<ImportJob> uploadSupplierInvoice(String filePath, String fileName) {
    return _remoteDataSource.uploadSupplierInvoice(filePath, fileName);
  }

  @override
  Future<Map<String, dynamic>> importBulk({
    required List<Map<String, dynamic>> medicines,
    required String supplier,
    required String duplicateStrategy,
    required Map<String, dynamic> barcodeOptions,
    required bool dryRun,
  }) {
    return _remoteDataSource.importBulk(
      medicines: medicines,
      supplier: supplier,
      duplicateStrategy: duplicateStrategy,
      barcodeOptions: barcodeOptions,
      dryRun: dryRun,
    );
  }

  @override
  Future<Map<String, dynamic>> uploadImportFile({
    required String fileName,
    required String fileContent,
    required String duplicateStrategy,
    required Map<String, dynamic> barcodeOptions,
  }) {
    return _remoteDataSource.uploadImportFile(
      fileName: fileName,
      fileContent: fileContent,
      duplicateStrategy: duplicateStrategy,
      barcodeOptions: barcodeOptions,
    );
  }

  @override
  Future<Map<String, dynamic>> getImportStatus(String jobId) {
    return _remoteDataSource.getImportStatus(jobId);
  }
}

// Global Injectable ImportRepository Provider
final importRepositoryProvider = Provider<ImportRepository>((ref) {
  final remoteDataSource = ref.watch(importRemoteDataSourceProvider);
  return ImportRepositoryImpl(remoteDataSource);
});
