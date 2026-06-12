import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../notifier/import_notifier.dart';
import '../state/import_state.dart';
import '../../domain/models/import_job.dart';
import '../../../purchase/presentation/notifier/purchase_notifier.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _isPdfMode = false; // false = CSV (ETL), true = PDF OCR
  String? _selectedFilePath;
  String? _selectedFileName;
  String? _selectedFileSizeStr;

  int? _hoveredRowIndex; // Table hover effect
  bool _isDragging = false; // Drag & drop zone hover indicator

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _isPdfMode ? ['pdf'] : ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        if (_isPdfMode) {
          final kbSize = file.size / 1024;
          setState(() {
            _selectedFilePath = file.path;
            _selectedFileName = file.name;
            _selectedFileSizeStr = kbSize > 1024
                ? '${(kbSize / 1024).toStringAsFixed(2)} MB'
                : '${kbSize.toStringAsFixed(1)} KB';
          });
        } else {
          final filePath = file.path!;
          final csvText = await File(filePath).readAsString();
          ref
              .read(importNotifierProvider.notifier)
              .loadCsv(csvText, file.name, file.size);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _clearFileSelection() {
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
      _selectedFileSizeStr = null;
    });
    ref.read(importNotifierProvider.notifier).clearImport();
  }

  Future<void> _startPdfImport() async {
    if (_selectedFilePath == null || _selectedFileName == null) return;

    final notifier = ref.read(importNotifierProvider.notifier);
    final success = await notifier.uploadPdfInvoice(
      _selectedFilePath!,
      _selectedFileName!,
    );

    if (mounted) {
      if (success) {
        _clearFileSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PDF invoice uploaded successfully! Import job created.',
            ),
            backgroundColor: Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final error =
            ref.read(importNotifierProvider).errorMessage ??
            'Failed to upload PDF';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _startLegacyImport() async {
    final notifier = ref.read(importNotifierProvider.notifier);
    final success = await notifier.commitImportLegacy();

    if (mounted) {
      if (success) {
        _clearFileSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bulk import committed successfully! Inventory updated.',
            ),
            backgroundColor: Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final error =
            ref.read(importNotifierProvider).errorMessage ?? 'Import failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _startEtlImport() async {
    final notifier = ref.read(importNotifierProvider.notifier);
    final success = await notifier.commitImportEtl();

    if (mounted) {
      if (success) {
        _clearFileSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ETL CSV file uploaded and processed! Inventory updated.',
            ),
            backgroundColor: Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final error =
            ref.read(importNotifierProvider).errorMessage ??
            'ETL processing failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;
    final cleanStatus = status.toUpperCase();

    switch (cleanStatus) {
      case 'UPLOADED':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        break;
      case 'PROCESSING':
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF2563EB);
        break;
      case 'COMPLETED':
        bg = const Color(0xFFD1FAE5);
        text = const Color(0xFF059669);
        break;
      case 'FAILED':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        cleanStatus,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0F766E);
    const textDark = Color(0xFF0F172A);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF4F7FA);
    const borderGrey = Color(0xFFE2E8F0);

    final state = ref.watch(importNotifierProvider);
    final purchaseState = ref.watch(purchaseNotifierProvider);

    final isInteractive = state.currentStep != 'idle';

    return Container(
      color: bgGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. DYNAMIC HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: borderGrey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isInteractive
                          ? 'CSV Import Mapping & ETL'
                          : 'Bulk Import & OCR',
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isInteractive
                          ? 'Map your CSV headers, select duplicate strategies, and preview validation summary.'
                          : 'Upload supplier invoices, CSV sheets, or PDF bills to bulk-import items and update stock.',
                      style: const TextStyle(
                        color: softGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (!isInteractive)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: primaryTeal),
                    tooltip: 'Refresh history',
                    onPressed: () {
                      ref
                          .read(importNotifierProvider.notifier)
                          .loadImportHistory();
                    },
                  ),
              ],
            ),
          ),

          // 2. MAIN SPLIT VIEW OR ETL FLOW WORKSPACE
          Expanded(
            child: isInteractive
                ? _buildEtlFlowWorkspace(
                    state,
                    purchaseState,
                    primaryTeal,
                    textDark,
                    softGrey,
                    borderGrey,
                  )
                : _buildIdleWorkspace(
                    state,
                    primaryTeal,
                    textDark,
                    softGrey,
                    borderGrey,
                  ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Idle Mode Workspace (Upload selection + History logs)
  Widget _buildIdleWorkspace(
    ImportState state,
    Color primaryTeal,
    Color textDark,
    Color softGrey,
    Color borderGrey,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel: Drag & Drop zone
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderGrey),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Source',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Toggle mode buttons
                  Row(
                    children: [
                      _buildModeButton(
                        label: 'CSV File Mapping',
                        icon: Icons.table_chart_outlined,
                        isActive: !_isPdfMode,
                        onTap: () {
                          if (_isPdfMode) {
                            setState(() {
                              _isPdfMode = false;
                              _clearFileSelection();
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildModeButton(
                        label: 'PDF Invoice (OCR)',
                        icon: Icons.picture_as_pdf_outlined,
                        isActive: _isPdfMode,
                        onTap: () {
                          if (!_isPdfMode) {
                            setState(() {
                              _isPdfMode = true;
                              _clearFileSelection();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Upload Drag zone / button box
                  MouseRegion(
                    onEnter: (_) => setState(() => _isDragging = true),
                    onExit: (_) => setState(() => _isDragging = false),
                    child: InkWell(
                      onTap: state.isUploading ? null : _pickFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: _isDragging
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isDragging ? primaryTeal : borderGrey,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isPdfMode
                                    ? Icons.picture_as_pdf
                                    : Icons.upload_file_rounded,
                                size: 48,
                                color: _isDragging ? primaryTeal : softGrey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isPdfMode
                                    ? 'Select PDF Invoice File'
                                    : 'Select CSV Sheet File',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isDragging ? primaryTeal : textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isPdfMode
                                    ? 'Supports standard invoice PDFs'
                                    : 'Supports standard comma-separated .csv sheets',
                                style: TextStyle(fontSize: 13, color: softGrey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selected file summary (for PDF OCR only)
                  if (_selectedFileName != null && _isPdfMode) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFileName!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedFileSizeStr ?? '',
                                  style: TextStyle(
                                    color: softGrey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                            onPressed: _clearFileSelection,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.isUploading ? null : _startPdfImport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: state.isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Upload & Extract OCR',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),

          // Right panel: Import history logs
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderGrey),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Import History & Statuses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: borderGrey),

                  state.isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(80.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: primaryTeal,
                            ),
                          ),
                        )
                      : state.importJobs.isEmpty
                      ? _buildEmptyState()
                      : _buildJobsTable(state.importJobs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Interactive CSV ETL Mapping flow
  Widget _buildEtlFlowWorkspace(
    ImportState state,
    dynamic purchaseState,
    Color primaryTeal,
    Color textDark,
    Color softGrey,
    Color borderGrey,
  ) {
    final mapping = state.columnMapping;
    final headers = state.csvHeaders;
    final supplierList = purchaseState.suppliers;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sub-bar showing selected file banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                border: Border(bottom: BorderSide(color: borderGrey)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.table_chart,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    state.fileName ?? 'CSV File',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${state.fileSizeStr})',
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 1,
                    height: 16,
                    color: const Color(0xFFBFDBFE),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.check, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Parsed ${state.parsedCsvData.length} rows — ${state.csvHeaders.length} columns detected',
                    style: const TextStyle(
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear File'),
                    onPressed: _clearFileSelection,
                  ),
                ],
              ),
            ),

            // Scrollable Panels
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  40,
                  32,
                  40,
                  140,
                ), // extra padding for bottom stats bar
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN: Data Preview Table
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderGrey),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.01),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'DATA PREVIEW (FIRST 5 ROWS)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                                Divider(height: 1, color: borderGrey),
                                Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Scrollbar(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              const Color(0xFFF8FAFC),
                                            ),
                                        horizontalMargin: 24,
                                        columnSpacing: 28,
                                        dividerThickness: 1,
                                        columns: headers.map((h) {
                                          return DataColumn(
                                            label: Text(
                                              h.toUpperCase(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: softGrey,
                                                fontSize: 11,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        rows: state.previewRows.map((row) {
                                          return DataRow(
                                            cells: headers.map((h) {
                                              return DataCell(
                                                Text(
                                                  row[h] ?? '',
                                                  style: TextStyle(
                                                    color: textDark,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),

                    // RIGHT COLUMN: Mapping Config Sidebar
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderGrey),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Field Mapping',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Map the target fields to your uploaded CSV columns.',
                              style: TextStyle(color: softGrey, fontSize: 12),
                            ),
                            const SizedBox(height: 24),

                            // 6 CORE MAPPINGS
                            _buildMappingDropdown(
                              label: 'Medication Name *',
                              fieldKey: 'nameColumn',
                              currentValue: mapping['nameColumn'],
                              headers: headers,
                            ),
                            _buildMappingDropdown(
                              label: 'Units in Stock *',
                              fieldKey: 'qtyColumn',
                              currentValue: mapping['qtyColumn'],
                              headers: headers,
                            ),
                            _buildMappingDropdown(
                              label: 'Expiry Date',
                              fieldKey: 'expiryColumn',
                              currentValue: mapping['expiryColumn'],
                              headers: headers,
                            ),
                            _buildMappingDropdown(
                              label: 'Unit Price (INR)',
                              fieldKey: 'priceColumn',
                              currentValue: mapping['priceColumn'],
                              headers: headers,
                            ),
                            _buildMappingDropdown(
                              label: 'Batch Number',
                              fieldKey: 'batchColumn',
                              currentValue: mapping['batchColumn'],
                              headers: headers,
                            ),
                            _buildMappingDropdown(
                              label: 'Barcode / SKU',
                              fieldKey: 'barcodeColumn',
                              currentValue: mapping['barcodeColumn'],
                              headers: headers,
                            ),

                            // OPTIONAL MAPPINGS
                            _buildMappingDropdown(
                              label: 'Generic Name',
                              fieldKey: 'genericColumn',
                              currentValue: mapping['genericColumn'],
                              headers: headers,
                            ),
                            _buildMappingDropdown(
                              label: 'Category',
                              fieldKey: 'categoryColumn',
                              currentValue: mapping['categoryColumn'],
                              headers: headers,
                            ),
                            _buildMappingDropdown(
                              label: 'Manufacturer',
                              fieldKey: 'manufacturerColumn',
                              currentValue: mapping['manufacturerColumn'],
                              headers: headers,
                            ),

                            Divider(height: 32, color: borderGrey),

                            // OPTIONS: Supplier, Duplicates, Barcodes
                            _buildSupplierDropdown(
                              state.supplier,
                              supplierList,
                              textDark,
                              softGrey,
                              borderGrey,
                            ),
                            const SizedBox(height: 16),
                            _buildDuplicateDropdown(
                              state.duplicateStrategy,
                              textDark,
                              softGrey,
                              borderGrey,
                            ),
                            const SizedBox(height: 16),

                            // BARCODE OPTIONS COLLAPSIBLE OR SECTION
                            Text(
                              'Barcode Processing Options',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildBarcodeOptionsSwitches(state.barcodeOptions),

                            Divider(height: 32, color: borderGrey),

                            // UTILITY BUTTONS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: primaryTeal,
                                  ),
                                  icon: const Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Reset to AI suggestions',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(importNotifierProvider.notifier)
                                        .suggestMapping(headers);
                                    ref
                                        .read(importNotifierProvider.notifier)
                                        .runDryRunAnalysis();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // FIXED BOTTOM STATISTICS BAR
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomStatsBar(state, primaryTeal, borderGrey),
        ),
      ],
    );
  }

  // WIDGET: Mapping Dropdown Builder
  Widget _buildMappingDropdown({
    required String label,
    required String fieldKey,
    required String? currentValue,
    required List<String> headers,
  }) {
    const textDark = Color(0xFF0F172A);
    const softGrey = Color(0xFF64748B);
    const borderGrey = Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: currentValue,
            hint: const Text(
              'Unmapped',
              style: TextStyle(fontSize: 13, color: softGrey),
            ),
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: borderGrey, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: borderGrey, width: 1),
              ),
            ),
            style: const TextStyle(color: textDark, fontSize: 13),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Unmapped', style: TextStyle(color: softGrey)),
              ),
              ...headers.map((h) {
                return DropdownMenuItem<String>(value: h, child: Text(h));
              }),
            ],
            onChanged: (val) {
              ref
                  .read(importNotifierProvider.notifier)
                  .setMapping(fieldKey, val);
            },
          ),
        ],
      ),
    );
  }

  // WIDGET: Supplier Selector Dropdown
  Widget _buildSupplierDropdown(
    String currentValue,
    List<dynamic> suppliers,
    Color textDark,
    Color softGrey,
    Color borderGrey,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Associated Supplier',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: borderGrey, width: 1),
            ),
          ),
          style: TextStyle(color: textDark, fontSize: 13),
          items: [
            const DropdownMenuItem<String>(value: 'None', child: Text('None')),
            ...suppliers.map((sup) {
              return DropdownMenuItem<String>(
                value: sup.name,
                child: Text(sup.name),
              );
            }),
          ],
          onChanged: (val) {
            if (val != null) {
              ref.read(importNotifierProvider.notifier).setSupplier(val);
            }
          },
        ),
      ],
    );
  }

  // WIDGET: Duplicate Strategy Selector Dropdown
  Widget _buildDuplicateDropdown(
    String currentValue,
    Color textDark,
    Color softGrey,
    Color borderGrey,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duplicate Strategy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: borderGrey, width: 1),
            ),
          ),
          style: TextStyle(color: textDark, fontSize: 13),
          items: const [
            DropdownMenuItem<String>(
              value: 'Skip',
              child: Text('Skip duplicate matches'),
            ),
            DropdownMenuItem<String>(
              value: 'Overwrite',
              child: Text('Overwrite existing matches'),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              ref
                  .read(importNotifierProvider.notifier)
                  .setDuplicateStrategy(val);
            }
          },
        ),
      ],
    );
  }

  // WIDGET: Barcode options switches
  Widget _buildBarcodeOptionsSwitches(Map<String, dynamic> barcodeOptions) {
    final autoGen = barcodeOptions['autoGen'] == true;
    final overwrite = barcodeOptions['overwrite'] == true;
    final validate = barcodeOptions['validate'] == true;

    return Column(
      children: [
        _buildMiniSwitchRow(
          label: 'Auto-generate missing barcodes',
          value: autoGen,
          onChanged: (val) {
            final opts = Map<String, dynamic>.from(barcodeOptions);
            opts['autoGen'] = val;
            ref.read(importNotifierProvider.notifier).setBarcodeOptions(opts);
          },
        ),
        _buildMiniSwitchRow(
          label: 'Validate barcode formatting',
          value: validate,
          onChanged: (val) {
            final opts = Map<String, dynamic>.from(barcodeOptions);
            opts['validate'] = val;
            ref.read(importNotifierProvider.notifier).setBarcodeOptions(opts);
          },
        ),
        _buildMiniSwitchRow(
          label: 'Overwrite existing barcodes',
          value: overwrite,
          onChanged: (val) {
            final opts = Map<String, dynamic>.from(barcodeOptions);
            opts['overwrite'] = val;
            ref.read(importNotifierProvider.notifier).setBarcodeOptions(opts);
          },
        ),
      ],
    );
  }

  Widget _buildMiniSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
          ),
          SizedBox(
            height: 24,
            width: 44,
            child: FittedBox(
              fit: BoxFit.fill,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: const Color(0xFF0F766E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Bottom statistics ETL summary bar
  Widget _buildBottomStatsBar(
    ImportState state,
    Color primaryTeal,
    Color borderGrey,
  ) {
    final summary = state.analysisSummary;

    final rawErrors = summary?['errors'];
    final int errorCount = rawErrors is List
        ? rawErrors.length
        : (rawErrors is num
              ? rawErrors.toInt()
              : int.tryParse(rawErrors.toString()) ?? 0);

    final rawDuplicates = summary?['duplicates'];
    final int duplicateCount = rawDuplicates is List
        ? rawDuplicates.length
        : (rawDuplicates is num
              ? rawDuplicates.toInt()
              : int.tryParse(rawDuplicates.toString()) ?? 0);

    final rawReadyCount = summary?['readyCount'];
    final int readyCount = rawReadyCount is List
        ? rawReadyCount.length
        : (rawReadyCount is num
              ? rawReadyCount.toInt()
              : int.tryParse(rawReadyCount.toString()) ?? 0);

    final rawNewCount = summary?['new'];
    final int newCount = rawNewCount is List
        ? rawNewCount.length
        : (rawNewCount is num
              ? rawNewCount.toInt()
              : int.tryParse(rawNewCount.toString()) ?? 0);

    final rawValidBarcodes = summary?['validBarcodes'];
    final int validBarcodes = rawValidBarcodes is List
        ? rawValidBarcodes.length
        : (rawValidBarcodes is num
              ? rawValidBarcodes.toInt()
              : int.tryParse(rawValidBarcodes.toString()) ?? 0);

    final rawAutoGenBarcodes = summary?['autoGenBarcodes'];
    final int autoGenBarcodes = rawAutoGenBarcodes is List
        ? rawAutoGenBarcodes.length
        : (rawAutoGenBarcodes is num
              ? rawAutoGenBarcodes.toInt()
              : int.tryParse(rawAutoGenBarcodes.toString()) ?? 0);

    final isMapped =
        state.columnMapping['nameColumn'] != null &&
        state.columnMapping['qtyColumn'] != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderGrey, width: 1.5)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // If uploading or processing, render progressive bar details
          if (state.isUploading) ...[
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF0F766E)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  state.currentStep == 'importing'
                      ? 'Executing transaction and processing queue... ${(state.uploadProgress * 100).toInt()}%'
                      : 'Importing records...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: state.uploadProgress,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF0F766E)),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // STATS BADGES (LEFT SIDE)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildStatBadge(
                            '● $readyCount rows ready to import',
                            const Color(0xFF10B981),
                          ),
                          _buildStatBadge(
                            isMapped
                                ? '● Required fields mapped'
                                : '● Name + Stock column required',
                            isMapped
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          _buildStatBadge(
                            '● $validBarcodes valid barcodes - $autoGenBarcodes auto-gen',
                            const Color(0xFF2563EB),
                          ),
                          _buildStatBadge(
                            '● Supplier: ${state.supplier}',
                            const Color(0xFF64748B),
                          ),
                          _buildStatBadge(
                            '● $duplicateCount duplicates — handling: ${state.duplicateStrategy}',
                            const Color(0xFFF59E0B),
                          ),
                          if (errorCount > 0)
                            _buildStatBadge(
                              '● $errorCount rows with invalid data will be skipped',
                              const Color(0xFFEF4444),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Will import: $newCount new — $duplicateCount duplicates — $errorCount errors = $readyCount records',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ACTION BUTTONS (RIGHT SIDE)
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _clearFileSelection,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0FDF4),
                        foregroundColor: const Color(0xFF166534),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFBBF7D0)),
                        ),
                      ),
                      onPressed: (!isMapped || readyCount == 0)
                          ? null
                          : _startLegacyImport,
                      child: Text(
                        'Import (Legacy) — $readyCount Records',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: (!isMapped || readyCount == 0)
                          ? null
                          : _startEtlImport,
                      child: Text(
                        'Upload as File (ETL) — $readyCount Records',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    const primaryTeal = Color(0xFF0F766E);
    const borderGrey = Color(0xFFE2E8F0);
    const textDark = Color(0xFF0F172A);
    const softGrey = Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? primaryTeal : borderGrey,
              width: isActive ? 1.8 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? primaryTeal : softGrey, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? primaryTeal : textDark,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(80.0),
      child: Center(
        child: Text(
          'No bulk imports performed yet.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildJobsTable(List<ImportJob> jobs) {
    const textDark = Color(0xFF0F172A);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);

    return Column(
      children: [
        // Table Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: borderGrey)),
          ),
          child: Row(
            children: const [
              Expanded(flex: 3, child: _TableHeaderText('UPLOAD TIME')),
              Expanded(flex: 3, child: _TableHeaderText('TYPE')),
              Expanded(flex: 3, child: _TableHeaderText('STATUS')),
              Expanded(flex: 4, child: _TableHeaderText('REMARKS')),
            ],
          ),
        ),
        // Table rows list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: borderGrey),
          itemBuilder: (context, index) {
            final job = jobs[index];
            final typeText = job.importType == 'SUPPLIER_INVOICE'
                ? 'Supplier CSV'
                : 'PDF Invoice';

            // Build remark text based on status
            String remarks;
            Color remarkColor;
            if (job.importStatus == 'COMPLETED') {
              remarks = 'Processed successfully';
              remarkColor = const Color(0xFF059669);
            } else if (job.importStatus == 'FAILED') {
              remarks = job.errorMessage ?? 'Parsing failed';
              remarkColor = const Color(0xFFDC2626);
            } else {
              remarks = 'Awaiting parsing queue...';
              remarkColor = softGrey;
            }

            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredRowIndex = index),
              onExit: (_) => setState(() => _hoveredRowIndex = null),
              child: Container(
                color: _hoveredRowIndex == index
                    ? const Color(0xFFF8FAFC)
                    : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Upload Date
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatDate(job.createdAt),
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Type
                    Expanded(
                      flex: 3,
                      child: Text(
                        typeText,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Status Chip
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildStatusChip(job.importStatus),
                      ),
                    ),
                    // Remarks
                    Expanded(
                      flex: 4,
                      child: Text(
                        remarks,
                        style: TextStyle(
                          color: remarkColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String label;
  const _TableHeaderText(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF475569),
        fontSize: 11,
      ),
    );
  }
}
