import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../inventory/presentation/notifier/inventory_notifier.dart';
import '../../../inventory/domain/models/medicine.dart';
import '../notifier/barcode_notifier.dart';
import '../state/barcode_state.dart';

class BarcodeScreen extends ConsumerStatefulWidget {
  const BarcodeScreen({super.key});

  @override
  ConsumerState<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends ConsumerState<BarcodeScreen>
    with SingleTickerProviderStateMixin {
  final _lookupController = TextEditingController();
  final _generatorTextController = TextEditingController();
  String? _selectedMedicineId;
  String _selectedFormat = 'code128';
  int _activeTab = 0;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _lookupController.dispose();
    _generatorTextController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _simulateBarcodeScan(List<Medicine> medicines) {
    final medicinesWithBarcode =
        medicines.where((m) => m.barcode != null && m.barcode!.isNotEmpty).toList();
    if (medicinesWithBarcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No medicines have barcodes. Register one in Stock first.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final randomMed = (medicinesWithBarcode..shuffle()).first;
    final barcode = randomMed.barcode!;
    _lookupController.text = barcode;
    ref.read(barcodeNotifierProvider.notifier).lookupBarcode(barcode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulated scan: "${randomMed.name}" barcode detected.'),
        backgroundColor: const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _downloadBarcode(Uint8List bytes, String filenameText) async {
    try {
      final Directory dir;
      if (Platform.isWindows) {
        dir = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
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

  void _showPrintLabelDialog(
      String medName, String genericName, double mrp, Uint8List barcodeBytes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              icon:
                  const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
              onPressed: () => Navigator.of(ctx).pop(),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFCBD5E1), width: 0.8),
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'VIYAN MEDASSIST',
                                  style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0D9488)),
                                ),
                                Text(
                                  '\u{20B9}${mrp.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A)),
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
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                  color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Print job submitted. 24-Label sheet printed.'),
                  backgroundColor: Color(0xFF0D9488),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print Label Sheet',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);
    const primaryDark = Color(0xFF0F766E);
    const textDark = Color(0xFF1E293B);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF8FAFC);

    final state = ref.watch(barcodeNotifierProvider);
    final inventoryState = ref.watch(inventoryNotifierProvider);
    final medicines = inventoryState.medicines;

    final categoryMap = {
      for (var c in inventoryState.categories) c.id: c.name
    };
    final manufacturerMap = {
      for (var m in inventoryState.manufacturers) m.id: m.name
    };

    final totalSKU = medicines.length;
    final medicinesWithBarcode =
        medicines.where((m) => m.barcode != null && m.barcode!.isNotEmpty).length;
    final medicinesMissingBarcode = totalSKU - medicinesWithBarcode;

    final tabs = ['Scan & Lookup', 'Generate Codes'];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: bgGrey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [primaryTeal, primaryDark],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Barcode & QR Management',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              'Search product codes, generate labels, and manage your inventory barcodes.',
                              style: TextStyle(color: softGrey, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: primaryTeal.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref
                                .read(inventoryNotifierProvider.notifier)
                                .loadInventory();
                            ref
                                .read(barcodeNotifierProvider.notifier)
                                .clearLookup();
                            ref
                                .read(barcodeNotifierProvider.notifier)
                                .clearGenerated();
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Refresh Catalog',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── METRICS ROW ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      title: 'Total Medicines',
                      value: totalSKU.toString(),
                      icon: Icons.medication_outlined,
                      gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _metricCard(
                      title: 'With Barcodes',
                      value: medicinesWithBarcode.toString(),
                      icon: Icons.qr_code_2_rounded,
                      gradientColors: const [primaryTeal, primaryDark],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _metricCard(
                      title: 'Missing Barcodes',
                      value: medicinesMissingBarcode.toString(),
                      icon: Icons.qr_code_scanner_rounded,
                      gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── CUSTOM TAB BAR ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final isActive = _activeTab == index;
                    final icon = index == 0
                        ? Icons.search_rounded
                        : Icons.qr_code_2_rounded;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isActive
                                ? primaryTeal.withValues(alpha: 0.06)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: isActive
                                ? Border.all(
                                    color: primaryTeal.withValues(alpha: 0.15))
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: 18,
                                color: isActive ? primaryTeal : softGrey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tabs[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isActive ? primaryTeal : softGrey,
                                ),
                              ),
                              if (isActive)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: primaryTeal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── TAB CONTENT ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _activeTab == 0
                      ? _buildScanTab(
                          state, medicines, categoryMap, manufacturerMap)
                      : _buildGenerateTab(state, medicines),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SCAN TAB ──
  Widget _buildScanTab(BarcodeState state, List<Medicine> medicines,
      Map<String, String> catMap, Map<String, String> mfgMap) {
    const primaryTeal = Color(0xFF0D9488);
    const textDark = Color(0xFF1E293B);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF8FAFC);

    return Row(
      key: const ValueKey('scan'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderGrey),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: borderGrey.withValues(alpha: 0.5))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.search_rounded,
                            color: primaryTeal, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Scan & Lookup Product',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textDark),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _lookupController,
                              style:
                                  const TextStyle(fontSize: 13, color: textDark),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Enter or scan medicine barcode...',
                                hintStyle:
                                    const TextStyle(color: softGrey, fontSize: 13),
                                prefixIcon: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    size: 18,
                                    color: softGrey),
                                filled: true,
                                fillColor: bgGrey,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: borderGrey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: borderGrey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: primaryTeal, width: 1.5),
                                ),
                              ),
                              onSubmitted: (val) {
                                ref
                                    .read(barcodeNotifierProvider.notifier)
                                    .lookupBarcode(val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryTeal.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => ref
                                  .read(barcodeNotifierProvider.notifier)
                                  .lookupBarcode(_lookupController.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryTeal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: const Text('Search',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _simulateBarcodeScan(medicines),
                          icon: const Icon(Icons.flash_on_rounded,
                              size: 16, color: primaryTeal),
                          label: const Text('Simulate Scanner Receipt',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryTeal)),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: primaryTeal),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Results
                Expanded(
                  child: state.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation(primaryTeal),
                          ),
                        )
                      : state.lookupResult != null
                          ? _buildLookupResultCard(
                              state.lookupResult!, catMap, mfgMap)
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner_outlined,
                                    size: 52,
                                    color: softGrey.withValues(alpha: 0.35),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.errorMessage ??
                                        'Search a barcode or tap "Simulate Scanner"\nto begin lookup.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: state.errorMessage != null
                                          ? const Color(0xFFEF4444)
                                          : softGrey,
                                      height: 1.5,
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
      ],
    );
  }

  // ── GENERATE TAB ──
  Widget _buildGenerateTab(BarcodeState state, List<Medicine> medicines) {
    const primaryTeal = Color(0xFF0D9488);
    const textDark = Color(0xFF1E293B);
    const borderGrey = Color(0xFFE2E8F0);
    const softGrey = Color(0xFF64748B);
    const bgGrey = Color(0xFFF8FAFC);

    return Row(
      key: const ValueKey('generate'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Form Panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderGrey),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: borderGrey.withValues(alpha: 0.5))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded,
                            color: primaryTeal, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Generate Labels & Codes',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textDark),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine selector
                      const Text(
                        'Select Medicine',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textDark),
                      ),
                      const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedMedicineId,
                        isExpanded: true,
                        style: const TextStyle(fontSize: 13, color: textDark),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: bgGrey,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: borderGrey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: borderGrey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: primaryTeal, width: 1.5),
                          ),
                        ),
                        hint: const Text('Choose product from catalog...'),
                        items: medicines.map((med) {
                          return DropdownMenuItem<String>(
                            value: med.id,
                            child: Text(
                                '${med.name} (Barcode: ${med.barcode ?? "None"})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedMedicineId = val;
                            final med =
                                medicines.firstWhere((m) => m.id == val);
                            _generatorTextController.text = med.barcode ??
                                med.id.substring(0, 8).toUpperCase();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Code value + format
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Code / Value',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textDark),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _generatorTextController,
                                  style: const TextStyle(
                                      fontSize: 13, color: textDark),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Enter code value...',
                                    hintStyle: const TextStyle(
                                        color: softGrey, fontSize: 13),
                                    filled: true,
                                    fillColor: bgGrey,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: borderGrey),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: borderGrey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: primaryTeal, width: 1.5),
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
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textDark),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedFormat,
                                  style: const TextStyle(
                                      fontSize: 13, color: textDark),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    filled: true,
                                    fillColor: bgGrey,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: borderGrey),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: borderGrey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: primaryTeal, width: 1.5),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'code128',
                                        child: Text('Code 128')),
                                    DropdownMenuItem(
                                        value: 'qr',
                                        child: Text('QR Code')),
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
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: primaryTeal.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_generatorTextController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Please enter code text to generate.'),
                                    backgroundColor: Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              ref
                                  .read(barcodeNotifierProvider.notifier)
                                  .generateBarcode(
                                    _generatorTextController.text.trim(),
                                    format: _selectedFormat,
                                  );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTeal,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.bolt, size: 18),
                            label: const Text('Generate Code',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Preview area
                Expanded(
                  child: state.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation(primaryTeal),
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
                                  Icon(
                                    Icons.image_aspect_ratio_rounded,
                                    size: 52,
                                    color: softGrey.withValues(alpha: 0.35),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Generated barcode/QR code preview\nwill appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: softGrey,
                                        height: 1.5),
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
    );
  }

  // ── METRIC CARD ──
  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── LOOKUP RESULT CARD ──
  Widget _buildLookupResultCard(
      Medicine med, Map<String, String> catMap, Map<String, String> mfgMap) {
    const textDark = Color(0xFF1E293B);
    const softGrey = Color(0xFF64748B);
    const borderGrey = Color(0xFFE2E8F0);
    const primaryTeal = Color(0xFF0D9488);

    final categoryName = catMap[med.categoryId] ?? 'General Category';
    final manufacturerName = mfgMap[med.manufacturerId] ?? 'Unknown Manufacturer';
    final hasStock = med.stock > 0;
    final isLowStock =
        med.stock > 0 && med.stock <= (med.reorderLevel ?? 10);

    Color stockColor = const Color(0xFF10B981);
    String stockText = 'In Stock';
    if (!hasStock) {
      stockColor = const Color(0xFFEF4444);
      stockText = 'Out of Stock';
    } else if (isLowStock) {
      stockColor = const Color(0xFFF59E0B);
      stockText = 'Low Stock';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name.toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textDark,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        med.genericName ?? 'Generic Name Not Specified',
                        style: const TextStyle(
                            color: softGrey,
                            fontSize: 12,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: stockColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: stockColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    stockText.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: stockColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: borderGrey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            // Details grid
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                      Icons.category_outlined, 'Category', categoryName),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailRow(Icons.business_outlined,
                      'Manufacturer', manufacturerName),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(Icons.warehouse_outlined, 'Stock',
                      '${med.stock} units (Avail: ${med.availableStock})'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailRow(Icons.payments_outlined, 'MRP',
                      '\u{20B9}${med.mrp.toStringAsFixed(2)}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                      Icons.tag_outlined, 'HSN Code', med.hsnCode ?? '--'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailRow(
                      Icons.qr_code_scanner, 'Barcode ID', med.barcode ?? '--'),
                ),
              ],
            ),
            if (med.notes != null && med.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(Icons.notes_outlined, 'Notes', med.notes!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedMedicineId = med.id;
                    _generatorTextController.text =
                        med.barcode ?? med.id.substring(0, 8).toUpperCase();
                    _activeTab = 1;
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                label: const Text('Load into Label Generator',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    );
  }

  // ── GENERATED CODE CARD ──
  Widget _buildGeneratedCodeCard(
      Uint8List bytes, String text, List<Medicine> medicines) {
    const textDark = Color(0xFF1E293B);
    const borderGrey = Color(0xFFE2E8F0);
    const primaryTeal = Color(0xFF0D9488);

    Medicine? matchedMed;
    if (_selectedMedicineId != null) {
      final matches = medicines.where((m) => m.id == _selectedMedicineId);
      if (matches.isNotEmpty) matchedMed = matches.first;
    }

    final medicineName = matchedMed?.name ?? 'MedAssist Product';
    final genericName = matchedMed?.genericName ?? 'Pharmaceutical Item';
    final mrp = matchedMed?.mrp ?? 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderGrey),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          medicineName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textDark,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          genericName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.memory(
                            bytes,
                            height: 72,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadBarcode(bytes, text),
                      icon: const Icon(Icons.download_rounded,
                          size: 16, color: primaryTeal),
                      label: const Text('Save PNG',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryTeal)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: primaryTeal),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: primaryTeal.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _showPrintLabelDialog(
                            medicineName, genericName, mrp, bytes),
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('Print Labels',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
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
    );
  }
}
