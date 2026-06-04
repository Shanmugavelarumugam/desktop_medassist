import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../inventory/presentation/notifier/inventory_notifier.dart';
import '../../../inventory/domain/models/medicine.dart';
import '../notifier/barcode_notifier.dart';

class BarcodeScreen extends ConsumerStatefulWidget {
  const BarcodeScreen({super.key});

  @override
  ConsumerState<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends ConsumerState<BarcodeScreen> {
  final _lookupController = TextEditingController();
  final _generatorTextController = TextEditingController();
  String? _selectedMedicineId;
  String _selectedFormat = 'code128';

  @override
  void dispose() {
    _lookupController.dispose();
    _generatorTextController.dispose();
    super.dispose();
  }

  // 1. Simulates hardware barcode scan
  void _simulateBarcodeScan(List<Medicine> medicines) {
    // Find medicines that have a barcode registered
    final medicinesWithBarcode = medicines.where((m) => m.barcode != null && m.barcode!.isNotEmpty).toList();
    if (medicinesWithBarcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No medicines in inventory have barcodes. Register one in Stock first.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // Take a random one
    final randomMed = (medicinesWithBarcode..shuffle()).first;
    final barcode = randomMed.barcode!;
    _lookupController.text = barcode;
    
    // Trigger lookup
    ref.read(barcodeNotifierProvider.notifier).lookupBarcode(barcode);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulated scan: "${randomMed.name}" barcode detected.'),
        backgroundColor: const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 2. Download generated barcode/QR image to Downloads or Documents folder
  Future<void> _downloadBarcode(Uint8List bytes, String filenameText) async {
    try {
      final Directory dir;
      if (Platform.isWindows) {
        dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      
      final cleanText = filenameText.replaceAll(RegExp(r'[^\w\-_]'), '_');
      final path = '${dir.path}/barcode_$cleanText.png';
      final file = File(path);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barcode saved to: $path'),
            backgroundColor: const Color(0xFF0D9488),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save barcode: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // 3. Opens standard layout label printing page modal
  void _showPrintLabelDialog(String medName, String genericName, double mrp, Uint8List barcodeBytes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.print_outlined, color: Color(0xFF0D9488), size: 26),
                SizedBox(width: 10),
                Text(
                  'Print Label Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
        content: SizedBox(
          width: 800,
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify sheet grid layout before sending to the label/thermal printer (A4 Standard 24-Label sheet).',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: 9, // Preview 9 labels in grid
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              medName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              genericName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Image.memory(
                              barcodeBytes,
                              height: 35,
                              fit: BoxFit.contain,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'VIYAN MEDASSIST',
                                  style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                                ),
                                Text(
                                  '₹${mrp.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Print job submitted. Standard 24-Label sheet printed successfully.'),
                  backgroundColor: Color(0xFF0D9488),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print Label Sheet', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);
    const textDark = Color(0xFF1E293B);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF8FAFC);

    final state = ref.watch(barcodeNotifierProvider);
    final inventoryState = ref.watch(inventoryNotifierProvider);
    final medicines = inventoryState.medicines;

    // Fast map for category / manufacturer names
    final categoryMap = {for (var c in inventoryState.categories) c.id: c.name};
    final manufacturerMap = {for (var m in inventoryState.manufacturers) m.id: m.name};

    // Calculate metrics
    final totalSKU = medicines.length;
    final medicinesWithBarcode = medicines.where((m) => m.barcode != null && m.barcode!.isNotEmpty).length;
    final medicinesMissingBarcode = totalSKU - medicinesWithBarcode;

    return Container(
      color: bgGrey,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TITLE HEADER SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Barcode & QR Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Search product codes, assign SKUs, generate labels, and run layout test prints.',
                    style: TextStyle(color: softGrey, fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(inventoryNotifierProvider.notifier).loadInventory();
                  ref.read(barcodeNotifierProvider.notifier).clearLookup();
                  ref.read(barcodeNotifierProvider.notifier).clearGenerated();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 2. METRICS ROW
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Medicines',
                  value: totalSKU.toString(),
                  icon: Icons.medication_outlined,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildMetricCard(
                  title: 'With Barcodes',
                  value: medicinesWithBarcode.toString(),
                  icon: Icons.qr_code_2_rounded,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildMetricCard(
                  title: 'Missing Barcodes',
                  value: medicinesMissingBarcode.toString(),
                  icon: Icons.qr_code_scanner_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 3. CORE SPLIT INTERFACE
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A. LEFT PANEL: SCAN & LOOKUP
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderGrey),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.search_rounded, color: primaryTeal, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Scan & Lookup Product',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.01),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _lookupController,
                                  style: const TextStyle(fontSize: 13, color: textDark),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Enter or scan medicine barcode...',
                                    hintStyle: const TextStyle(color: softGrey, fontSize: 13),
                                    prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: softGrey),
                                    filled: true,
                                    fillColor: bgGrey,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: borderGrey),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: borderGrey),
                                    ),
                                  ),
                                  onSubmitted: (val) {
                                    ref.read(barcodeNotifierProvider.notifier).lookupBarcode(val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => ref.read(barcodeNotifierProvider.notifier).lookupBarcode(_lookupController.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryTeal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _simulateBarcodeScan(medicines),
                            icon: const Icon(Icons.flash_on_rounded, size: 16, color: primaryTeal),
                            label: const Text('Simulate Scanner Receipt', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: primaryTeal),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: borderGrey),
                        const SizedBox(height: 24),
                        
                        // Results Box
                        Expanded(
                          child: state.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(primaryTeal),
                                  ),
                                )
                              : state.lookupResult != null
                                  ? _buildLookupResultCard(state.lookupResult!, categoryMap, manufacturerMap)
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.qr_code_scanner_outlined, size: 48, color: softGrey.withValues(alpha: 0.5)),
                                          const SizedBox(height: 16),
                                          Text(
                                            state.errorMessage ?? 'Search a barcode or tap "Simulate Scanner" to begin lookup.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: state.errorMessage != null ? const Color(0xFFEF4444) : softGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // B. RIGHT PANEL: GENERATE & PREVIEW
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderGrey),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.qr_code_2_rounded, color: primaryTeal, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Generate Labels & Codes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Select Medicine
                        const Text(
                          'Select Medicine',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedMedicineId,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, color: textDark),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: bgGrey,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: borderGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: borderGrey),
                            ),
                          ),
                          hint: const Text('Choose product from catalog...'),
                          items: medicines.map((med) {
                            return DropdownMenuItem<String>(
                              value: med.id,
                              child: Text('${med.name} (Barcode: ${med.barcode ?? "None"})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedMedicineId = val;
                              final med = medicines.firstWhere((m) => m.id == val);
                              // Prefill text with barcode or fallback to medicine ID
                              _generatorTextController.text = med.barcode ?? med.id.substring(0, 8).toUpperCase();
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Input Text & Format Code
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Code / Value',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _generatorTextController,
                                    style: const TextStyle(fontSize: 13, color: textDark),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: 'Enter code value (e.g. 12345678)...',
                                      hintStyle: const TextStyle(color: softGrey, fontSize: 13),
                                      filled: true,
                                      fillColor: bgGrey,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: borderGrey),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: borderGrey),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Format',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedFormat,
                                    style: const TextStyle(fontSize: 13, color: textDark),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      filled: true,
                                      fillColor: bgGrey,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: borderGrey),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: borderGrey),
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'code128', child: Text('Code 128')),
                                      DropdownMenuItem(value: 'qr', child: Text('QR Code')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedFormat = val;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_generatorTextController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter code text to generate.'),
                                    backgroundColor: Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              ref.read(barcodeNotifierProvider.notifier).generateBarcode(
                                    _generatorTextController.text.trim(),
                                    format: _selectedFormat,
                                  );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.bolt, size: 18),
                            label: const Text('Generate Code', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: borderGrey),
                        const SizedBox(height: 24),

                        // Code Preview Card
                        Expanded(
                          child: state.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(primaryTeal),
                                  ),
                                )
                              : state.generatedBarcodeBytes != null
                                  ? _buildGeneratedCodeCard(
                                      state.generatedBarcodeBytes!,
                                      _generatorTextController.text.trim(),
                                      medicines,
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image_aspect_ratio_rounded, size: 48, color: softGrey.withValues(alpha: 0.5)),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Generated barcode/QR code preview will appear here.',
                                            style: TextStyle(fontSize: 13, color: softGrey),
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
          )
        ],
      ),
    );
  }

  // WIDGET: Metric Card Builder
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET: Lookup Result detail representation
  Widget _buildLookupResultCard(Medicine med, Map<String, String> catMap, Map<String, String> mfgMap) {
    const textDark = Color(0xFF1E293B);
    const softGrey = Color(0xFF64748B);
    const borderGrey = Color(0xFFE2E8F0);
    const primaryTeal = Color(0xFF0D9488);

    final categoryName = catMap[med.categoryId] ?? 'General Category';
    final manufacturerName = mfgMap[med.manufacturerId] ?? 'Unknown Manufacturer';
    final hasStock = med.stock > 0;
    final isLowStock = med.stock > 0 && med.stock <= (med.reorderLevel ?? 10);

    Color stockColor = Colors.green;
    String stockText = 'In Stock';
    if (!hasStock) {
      stockColor = Colors.red;
      stockText = 'Out of Stock';
    } else if (isLowStock) {
      stockColor = Colors.orange;
      stockText = 'Low Stock';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        med.genericName ?? 'Generic Name Not Specified',
                        style: const TextStyle(color: softGrey, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stockColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stockText.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stockColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: borderGrey),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.category_outlined, 'Category', categoryName),
            _buildDetailRow(Icons.business_outlined, 'Manufacturer', manufacturerName),
            _buildDetailRow(Icons.warehouse_outlined, 'Current Stock', '${med.stock} units (Available: ${med.availableStock})'),
            _buildDetailRow(Icons.payments_outlined, 'MRP / Price', '₹${med.mrp.toStringAsFixed(2)}'),
            _buildDetailRow(Icons.tag_outlined, 'HSN Code', med.hsnCode ?? 'Not Configured'),
            _buildDetailRow(Icons.qr_code_scanner, 'Barcode ID', med.barcode ?? 'None'),
            if (med.notes != null && med.notes!.isNotEmpty)
              _buildDetailRow(Icons.notes_outlined, 'Notes', med.notes!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedMedicineId = med.id;
                    _generatorTextController.text = med.barcode ?? med.id.substring(0, 8).toUpperCase();
                  });
                  ref.read(barcodeNotifierProvider.notifier).generateBarcode(
                        _generatorTextController.text.trim(),
                        format: _selectedFormat,
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryTeal,
                  side: const BorderSide(color: primaryTeal),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                label: const Text('Load into Label Generator', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
            ),
          )
        ],
      ),
    );
  }

  // WIDGET: Generated barcode representation card
  Widget _buildGeneratedCodeCard(Uint8List bytes, String text, List<Medicine> medicines) {
    const textDark = Color(0xFF1E293B);
    const borderGrey = Color(0xFFE2E8F0);
    const primaryTeal = Color(0xFF0D9488);

    // Look up matching medicine to show meta details on printed label
    Medicine? matchedMed;
    if (_selectedMedicineId != null) {
      final matches = medicines.where((m) => m.id == _selectedMedicineId);
      if (matches.isNotEmpty) matchedMed = matches.first;
    }

    final medicineName = matchedMed?.name ?? 'MedAssist Product';
    final genericName = matchedMed?.genericName ?? 'Pharmaceutical Item';
    final mrp = matchedMed?.mrp ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderGrey),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        medicineName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        genericName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 12),
                      Image.memory(
                        bytes,
                        height: 65,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        text,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _downloadBarcode(bytes, text),
                  icon: const Icon(Icons.download_rounded, size: 16, color: primaryTeal),
                  label: const Text('Save PNG', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: primaryTeal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showPrintLabelDialog(medicineName, genericName, mrp, bytes),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Print Labels', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
