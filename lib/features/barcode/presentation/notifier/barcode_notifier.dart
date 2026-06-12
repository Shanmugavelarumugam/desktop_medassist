import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository/barcode_repository_impl.dart';
import '../../domain/repository/barcode_repository.dart';
import '../state/barcode_state.dart';

class BarcodeNotifier extends Notifier<BarcodeState> {
  late BarcodeRepository _repository;

  @override
  BarcodeState build() {
    _repository = ref.watch(barcodeRepositoryProvider);
    return const BarcodeState();
  }

  Future<void> generateBarcode(String text, {String? format}) async {
    final activeFormat = format ?? state.selectedFormat;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      selectedFormat: activeFormat,
    );
    try {
      final bytes = await _repository.generateBarcode(
        text: text,
        type: activeFormat,
      );
      state = state.copyWith(generatedBarcodeBytes: bytes, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> lookupBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final medicine = await _repository.lookupMedicineByBarcode(
        barcode.trim(),
      );
      state = state.copyWith(
        lookupResult: medicine,
        lookupBarcode: barcode.trim(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setSelectedMedicine(String? medicineId) {
    state = state.copyWith(selectedMedicineId: medicineId);
  }

  void setFormat(String format) {
    state = state.copyWith(selectedFormat: format);
  }

  void clearLookup() {
    state = state.copyWith(clearLookupResult: true);
  }

  void clearGenerated() {
    state = state.copyWith(clearGeneratedBytes: true);
  }
}

final barcodeNotifierProvider = NotifierProvider<BarcodeNotifier, BarcodeState>(
  BarcodeNotifier.new,
);
