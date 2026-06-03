import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/import_job.dart';

part 'import_state.freezed.dart';

@freezed
abstract class ImportState with _$ImportState {
  const factory ImportState({
    @Default(false) bool isLoading,
    @Default(false) bool isUploading,
    String? errorMessage,
    @Default([]) List<ImportJob> importJobs,

    // Interactive ETL fields
    @Default([]) List<Map<String, String>> parsedCsvData,
    @Default([]) List<String> csvHeaders,
    @Default([]) List<Map<String, String>> previewRows,
    @Default({}) Map<String, String> columnMapping,
    @Default('None') String supplier,
    @Default('Skip') String duplicateStrategy,
    @Default({'autoGen': true, 'overwrite': false, 'validate': true}) Map<String, dynamic> barcodeOptions,
    Map<String, dynamic>? analysisSummary,
    @Default('idle') String currentStep, // idle, parsed, checking, importing, complete
    String? jobId,
    @Default(0.0) double uploadProgress,
    String? fileName,
    String? fileSizeStr,
  }) = _ImportState;
}
