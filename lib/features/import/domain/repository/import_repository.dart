import '../../domain/models/import_job.dart';

abstract class ImportRepository {
  Future<List<ImportJob>> getImportHistory();
  Future<ImportJob> uploadPdfInvoice(String filePath, String fileName);
  Future<ImportJob> uploadSupplierInvoice(String filePath, String fileName);
  Future<Map<String, dynamic>> importBulk({
    required List<Map<String, dynamic>> medicines,
    required String supplier,
    required String duplicateStrategy,
    required Map<String, dynamic> barcodeOptions,
    required bool dryRun,
  });
  Future<Map<String, dynamic>> uploadImportFile({
    required String fileName,
    required String fileContent,
    required String duplicateStrategy,
    required Map<String, dynamic> barcodeOptions,
  });
  Future<Map<String, dynamic>> getImportStatus(String jobId);

}
