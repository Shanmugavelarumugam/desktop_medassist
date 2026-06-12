import '../../domain/models/medicine.dart';

abstract class InventoryRepository {
  Future<List<Medicine>> getMedicines({String? search, int? limit});
  Future<List<MedicineCategory>> getCategories();
  Future<List<Manufacturer>> getManufacturers();

  Future<Medicine> createMedicine({
    required String name,
    required String genericName,
    required double mrp,
    required double purchasePrice,
    required String batchNumber,
    required int quantity,
    required String expiryDate,
    required String categoryId,
    String? manufacturerId,
    double? gstPercentage,
    int? reorderLevel,
    bool? prescriptionRequired,
    String? hsnCode,
    String? barcode,
    String? supplier,
    String? notes,
  });

  Future<Medicine> updateMedicine({
    required String id,
    required String name,
    String? genericName,
    String? categoryId,
    String? manufacturerId,
    double? gstPercentage,
    int? reorderLevel,
    bool? prescriptionRequired,
    String? hsnCode,
    String? barcode,
    String? supplier,
    String? notes,
  });

  Future<void> deleteMedicine({required String id});

  Future<Map<String, dynamic>> getSummary();

  Future<void> addBatch({
    required String medicineId,
    required String batchNumber,
    required int quantity,
    required String expiryDate,
    required double purchasePrice,
    required double mrp,
  });
}
