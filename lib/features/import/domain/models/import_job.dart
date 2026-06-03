import 'package:freezed_annotation/freezed_annotation.dart';

part 'import_job.freezed.dart';
part 'import_job.g.dart';

@freezed
abstract class ImportJob with _$ImportJob {
  const factory ImportJob({
    required String id,
    required String tenantId,
    required String importType, // SUPPLIER_INVOICE, PDF_INVOICE
    required String importStatus, // UPLOADED, PROCESSING, COMPLETED, FAILED
    required String uploadedBy,
    String? fileUrl,
    String? fileName,
    String? errorMessage,
    String? purchaseOrderId,
    String? processedAt,
    required String createdAt,
    required String updatedAt,
  }) = _ImportJob;

  factory ImportJob.fromJson(Map<String, dynamic> json) => _$ImportJobFromJson(json);
}
