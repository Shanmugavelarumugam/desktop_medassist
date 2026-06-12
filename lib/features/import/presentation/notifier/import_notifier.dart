import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repository/import_repository.dart';
import '../../data/repository/import_repository_impl.dart';
import '../state/import_state.dart';
import '../../../../core/helpers/csv_helper.dart';

class ImportNotifier extends Notifier<ImportState> {
  late ImportRepository _repository;

  @override
  ImportState build() {
    _repository = ref.watch(importRepositoryProvider);
    // Auto-load import history in microtask
    Future.microtask(() => loadImportHistory());
    return const ImportState();
  }

  Future<void> loadImportHistory() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final history = await _repository.getImportHistory();
      state = state.copyWith(importJobs: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> uploadPdfInvoice(String filePath, String fileName) async {
    state = state.copyWith(isUploading: true, errorMessage: null);
    try {
      await _repository.uploadPdfInvoice(filePath, fileName);
      await loadImportHistory();
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> uploadSupplierInvoice(String filePath, String fileName) async {
    state = state.copyWith(isUploading: true, errorMessage: null);
    try {
      await _repository.uploadSupplierInvoice(filePath, fileName);
      await loadImportHistory();
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // --- INTERACTIVE ETL IMPORT FLOW METHODS ---

  void loadCsv(String csvText, String fileName, int fileSize) {
    try {
      final parsedRows = CsvHelper.parse(csvText);
      if (parsedRows.isEmpty) {
        state = state.copyWith(
          errorMessage: 'The CSV file is empty or invalid.',
        );
        return;
      }

      final headers = parsedRows.first;
      final List<Map<String, String>> dataMaps = CsvHelper.toMaps(parsedRows);

      final kbSize = fileSize / 1024;
      final fileSizeStr = kbSize > 1024
          ? '${(kbSize / 1024).toStringAsFixed(2)} MB'
          : '${kbSize.toStringAsFixed(1)} KB';

      // Get first 5 rows for tabular data preview
      final preview = dataMaps.take(5).toList();

      state = state.copyWith(
        parsedCsvData: dataMaps,
        csvHeaders: headers,
        previewRows: preview,
        fileName: fileName,
        fileSizeStr: fileSizeStr,
        currentStep: 'parsed',
        errorMessage: null,
      );

      suggestMapping(headers);
      runDryRunAnalysis();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to parse CSV: ${e.toString()}',
      );
    }
  }

  void suggestMapping(List<String> headers) {
    final Map<String, String> mapping = {};
    final Set<String> usedHeaders = {};

    final Map<String, List<String>> rules = {
      'nameColumn': ['name', 'med', 'medicine', 'drug', 'item'],
      'qtyColumn': ['qty', 'quantity', 'stock', 'units', 'count'],
      'expiryColumn': ['expiry', 'exp', 'date', 'valid'],
      'priceColumn': ['price', 'rate', 'cost', 'inr'],
      'batchColumn': ['batch', 'lot', 'no', 'code'],
      'barcodeColumn': ['barcode', 'upc', 'ean', 'sku'],
      'genericColumn': ['generic'],
      'categoryColumn': ['category'],
      'manufacturerColumn': ['manufacturer', 'mfg', 'brand'],
    };

    rules.forEach((key, patterns) {
      for (final header in headers) {
        if (usedHeaders.contains(header)) continue;
        final hLower = header.toLowerCase();
        if (patterns.any((pat) => hLower.contains(pat))) {
          mapping[key] = header;
          usedHeaders.add(header);
          break;
        }
      }
    });

    state = state.copyWith(columnMapping: mapping);
  }

  void setMapping(String field, String? csvHeader) {
    final currentMapping = Map<String, String>.from(state.columnMapping);
    if (csvHeader == null) {
      currentMapping.remove(field);
    } else {
      currentMapping[field] = csvHeader;
    }
    state = state.copyWith(columnMapping: currentMapping);
    runDryRunAnalysis();
  }

  void setSupplier(String supplier) {
    state = state.copyWith(supplier: supplier);
    runDryRunAnalysis();
  }

  void setDuplicateStrategy(String strategy) {
    state = state.copyWith(duplicateStrategy: strategy);
    runDryRunAnalysis();
  }

  void setBarcodeOptions(Map<String, dynamic> options) {
    state = state.copyWith(barcodeOptions: options);
    runDryRunAnalysis();
  }

  void clearImport() {
    state = state.copyWith(
      parsedCsvData: [],
      csvHeaders: [],
      previewRows: [],
      columnMapping: {},
      supplier: 'None',
      duplicateStrategy: 'Skip',
      barcodeOptions: {'autoGen': true, 'overwrite': false, 'validate': true},
      analysisSummary: null,
      currentStep: 'idle',
      jobId: null,
      uploadProgress: 0.0,
      fileName: null,
      fileSizeStr: null,
      errorMessage: null,
    );
  }

  String _normalizeDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
        return dateStr;
      }
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        return "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
      }

      // Handle DD/MM/YYYY or DD-MM-YYYY
      final dmyMatch = RegExp(
        r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$',
      ).firstMatch(dateStr);
      if (dmyMatch != null) {
        final day = int.parse(dmyMatch.group(1)!);
        final month = int.parse(dmyMatch.group(2)!);
        final year = int.parse(dmyMatch.group(3)!);
        return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
      }
    } catch (_) {}
    return dateStr;
  }

  Future<void> runDryRunAnalysis() async {
    final medicines = _mapParsedDataToMedicines();
    if (medicines.isEmpty) {
      state = state.copyWith(analysisSummary: null);
      return;
    }

    // Client-side validations
    final clientErrors = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 0; i < medicines.length; i++) {
      final med = medicines[i];
      final name = med['name'] ?? 'Row ${i + 1}';

      // 1. Expiry Validation
      final expiryStr = med['expiry'] ?? '';
      if (expiryStr.isNotEmpty) {
        final expiryDate = DateTime.tryParse(expiryStr);
        if (expiryDate != null && expiryDate.isBefore(now)) {
          clientErrors.add({
            'row': i + 1,
            'name': name,
            'reason': 'Medicine is expired (Expiry: $expiryStr)',
            'warnings': [],
            'action': 'Skip',
          });
        }
      }

      // 2. Quantity Validation
      final qtyStr = med['qty'] ?? '';
      final qty = int.tryParse(qtyStr);
      if (qty == null) {
        clientErrors.add({
          'row': i + 1,
          'name': name,
          'reason': 'Quantity must be a valid integer',
          'warnings': [],
          'action': 'Skip',
        });
      } else if (qty < 0) {
        clientErrors.add({
          'row': i + 1,
          'name': name,
          'reason': 'Quantity cannot be negative',
          'warnings': [],
          'action': 'Skip',
        });
      }

      // 3. Price Validation
      final priceStr = med['price'] ?? '';
      final price = double.tryParse(priceStr);
      if (price == null) {
        clientErrors.add({
          'row': i + 1,
          'name': name,
          'reason': 'Price must be a valid decimal number',
          'warnings': [],
          'action': 'Skip',
        });
      } else if (price < 0) {
        clientErrors.add({
          'row': i + 1,
          'name': name,
          'reason': 'Price cannot be negative',
          'warnings': [],
          'action': 'Skip',
        });
      }
    }

    try {
      final result = await _repository.importBulk(
        medicines: medicines,
        supplier: state.supplier,
        duplicateStrategy: state.duplicateStrategy,
        barcodeOptions: state.barcodeOptions,
        dryRun: true,
      );
      if (result['success'] == true) {
        final summary = Map<String, dynamic>.from(result['summary'] ?? {});
        final backendErrors = List<dynamic>.from(summary['errors'] ?? []);

        // Merge client-side errors (avoid duplicates if same row failed on backend)
        final existingRows = backendErrors.map((e) => e['row'] as int).toSet();
        for (final ce in clientErrors) {
          if (!existingRows.contains(ce['row'])) {
            backendErrors.add(ce);
          }
        }
        summary['errors'] = backendErrors;

        // Adjust readyCount to exclude client errors
        final totalCount = medicines.length;
        final errRowsCount = backendErrors.map((e) => e['row']).toSet().length;
        summary['readyCount'] = (totalCount - errRowsCount).clamp(
          0,
          totalCount,
        );

        state = state.copyWith(analysisSummary: summary, errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(
        analysisSummary: {
          'error': e.toString().replaceFirst('Exception: ', ''),
          'readyCount': 0,
          'duplicates': 0,
          'errors': clientErrors.isNotEmpty
              ? clientErrors
              : [
                  {
                    'row': 1,
                    'name': 'Import',
                    'reason': e.toString(),
                    'warnings': [],
                    'action': 'Skip',
                  },
                ],
          'new': 0,
        },
      );
    }
  }

  List<Map<String, dynamic>> _mapParsedDataToMedicines() {
    final mapping = state.columnMapping;
    if (mapping['nameColumn'] == null || mapping['qtyColumn'] == null) {
      return [];
    }

    return state.parsedCsvData.map((row) {
      final rawExpiry = mapping['expiryColumn'] != null
          ? (row[mapping['expiryColumn']] ?? '').trim()
          : '';
      final normalizedExpiry = _normalizeDate(rawExpiry);

      return {
        'name': (row[mapping['nameColumn']] ?? '').trim(),
        'qty': (row[mapping['qtyColumn']] ?? '0').trim(),
        'expiry': normalizedExpiry,
        'price': mapping['priceColumn'] != null
            ? (row[mapping['priceColumn']] ?? '0').trim()
            : '0',
        'batch': mapping['batchColumn'] != null
            ? (row[mapping['batchColumn']] ?? '').trim()
            : '',
        'barcode': mapping['barcodeColumn'] != null
            ? (row[mapping['barcodeColumn']] ?? '').trim()
            : '',
        'genericName': mapping['genericColumn'] != null
            ? (row[mapping['genericColumn']] ?? '').trim()
            : '',
        'category': mapping['categoryColumn'] != null
            ? (row[mapping['categoryColumn']] ?? '').trim()
            : '',
        'manufacturer': mapping['manufacturerColumn'] != null
            ? (row[mapping['manufacturerColumn']] ?? '').trim()
            : '',
      };
    }).toList();
  }

  Future<bool> commitImportLegacy() async {
    final medicines = _mapParsedDataToMedicines();
    if (medicines.isEmpty) return false;

    state = state.copyWith(
      currentStep: 'importing',
      isUploading: true,
      errorMessage: null,
    );
    try {
      final result = await _repository.importBulk(
        medicines: medicines,
        supplier: state.supplier,
        duplicateStrategy: state.duplicateStrategy,
        barcodeOptions: state.barcodeOptions,
        dryRun: false,
      );

      if (result['success'] == true) {
        state = state.copyWith(
          currentStep: 'complete',
          isUploading: false,
          errorMessage: null,
        );
        await loadImportHistory();
        return true;
      }
      throw Exception(result['message'] ?? 'Import failed');
    } catch (e) {
      state = state.copyWith(
        currentStep: 'parsed',
        isUploading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> commitImportEtl() async {
    if (state.fileName == null || state.parsedCsvData.isEmpty) return false;

    state = state.copyWith(
      currentStep: 'importing',
      isUploading: true,
      uploadProgress: 0.1,
      errorMessage: null,
    );
    try {
      final mapping = state.columnMapping;

      final targetHeaders = [
        'name',
        'qty',
        'expiry',
        'price',
        'batch',
        'barcode',
        'genericName',
        'category',
        'manufacturer',
      ];

      final mappingKeys = {
        'name': 'nameColumn',
        'qty': 'qtyColumn',
        'expiry': 'expiryColumn',
        'price': 'priceColumn',
        'batch': 'batchColumn',
        'barcode': 'barcodeColumn',
        'genericName': 'genericColumn',
        'category': 'categoryColumn',
        'manufacturer': 'manufacturerColumn',
      };

      final buffer = StringBuffer();
      // Write standard headers expected by backend
      buffer.writeln(targetHeaders.map((h) => '"$h"').join(','));

      // Write mapped data rows
      for (final row in state.parsedCsvData) {
        final rowVals = <String>[];
        for (final th in targetHeaders) {
          final mappingKey = mappingKeys[th]!;
          final originalCol = mapping[mappingKey];
          String val = '';
          if (originalCol != null) {
            val = (row[originalCol] ?? '').trim();
            if (th == 'expiry') {
              val = _normalizeDate(val);
            }
          } else {
            // Default values for missing fields
            if (th == 'qty') val = '0';
            if (th == 'price') val = '0';
          }
          rowVals.add('"${val.replaceAll('"', '""')}"');
        }
        buffer.writeln(rowVals.join(','));
      }
      final fileContent = buffer.toString();

      state = state.copyWith(uploadProgress: 0.3);

      final result = await _repository.uploadImportFile(
        fileName: state.fileName!,
        fileContent: fileContent,
        duplicateStrategy: state.duplicateStrategy,
        barcodeOptions: state.barcodeOptions,
      );

      if (result['success'] == true) {
        final jobId = result['data']['jobId'];
        state = state.copyWith(jobId: jobId, uploadProgress: 0.5);
        return await _pollImportStatus(jobId);
      }
      throw Exception(result['message'] ?? 'ETL Upload failed');
    } catch (e) {
      state = state.copyWith(
        currentStep: 'parsed',
        isUploading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> _pollImportStatus(String jobId) async {
    int attempts = 0;
    while (attempts < 300) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final statusRes = await _repository.getImportStatus(jobId);
        final data = statusRes['data'];
        if (data == null) continue;

        final processed = data['processed'] ?? 0;
        final total = data['total'] ?? 0;
        final status = data['status'] ?? 'processing';
        final summary = data['summary'];

        double progress = 0.5;
        if (total > 0) {
          progress = 0.5 + (processed / total) * 0.45;
        }

        state = state.copyWith(uploadProgress: progress);

        if (status == 'completed' || status == 'complete') {
          state = state.copyWith(
            currentStep: 'complete',
            uploadProgress: 1.0,
            isUploading: false,
            analysisSummary: summary as Map<String, dynamic>?,
          );
          await loadImportHistory();
          return true;
        } else if (status == 'failed' || status == 'error') {
          throw Exception(
            summary?['error'] ?? 'ETL parsing job failed on backend',
          );
        }
      } catch (e) {
        state = state.copyWith(
          currentStep: 'parsed',
          isUploading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
        return false;
      }
      attempts++;
    }

    state = state.copyWith(
      currentStep: 'parsed',
      isUploading: false,
      errorMessage: 'Import processing timed out on backend.',
    );
    return false;
  }
}

// Global Injectable ImportNotifier Provider
final importNotifierProvider = NotifierProvider<ImportNotifier, ImportState>(
  ImportNotifier.new,
);
