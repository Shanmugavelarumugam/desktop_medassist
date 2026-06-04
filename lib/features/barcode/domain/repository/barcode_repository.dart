import 'dart:typed_data';
import '../../../inventory/domain/models/medicine.dart';

abstract class BarcodeRepository {
  Future<Uint8List> generateBarcode({required String text, String type = 'code128'});
  Future<Medicine?> lookupMedicineByBarcode(String barcode);
}
