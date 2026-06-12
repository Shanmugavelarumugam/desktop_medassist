import 'dart:typed_data';
import '../../../inventory/domain/models/medicine.dart';

class BarcodeState {
  final bool isLoading;
  final String? errorMessage;
  final Uint8List? generatedBarcodeBytes;
  final Medicine? lookupResult;
  final String? lookupBarcode;
  final String selectedFormat; // 'code128', 'qr'
  final String? selectedMedicineId;

  const BarcodeState({
    this.isLoading = false,
    this.errorMessage,
    this.generatedBarcodeBytes,
    this.lookupResult,
    this.lookupBarcode,
    this.selectedFormat = 'code128',
    this.selectedMedicineId,
  });

  BarcodeState copyWith({
    bool? isLoading,
    String? errorMessage,
    Uint8List? generatedBarcodeBytes,
    Medicine? lookupResult,
    String? lookupBarcode,
    String? selectedFormat,
    String? selectedMedicineId,
    bool clearGeneratedBytes = false,
    bool clearLookupResult = false,
  }) {
    return BarcodeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // We explicitly set to null/new error
      generatedBarcodeBytes: clearGeneratedBytes
          ? null
          : (generatedBarcodeBytes ?? this.generatedBarcodeBytes),
      lookupResult: clearLookupResult
          ? null
          : (lookupResult ?? this.lookupResult),
      lookupBarcode: clearLookupResult
          ? null
          : (lookupBarcode ?? this.lookupBarcode),
      selectedFormat: selectedFormat ?? this.selectedFormat,
      selectedMedicineId: selectedMedicineId ?? this.selectedMedicineId,
    );
  }
}
