import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/medicine.dart';
import '../../domain/repository/inventory_repository.dart';
import '../datasource/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource _remoteDataSource;

  InventoryRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Medicine>> getMedicines() {
    return _remoteDataSource.getMedicines();
  }

  @override
  Future<List<MedicineCategory>> getCategories() {
    return _remoteDataSource.getCategories();
  }

  @override
  Future<List<Manufacturer>> getManufacturers() {
    return _remoteDataSource.getManufacturers();
  }

  @override
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
  }) {
    return _remoteDataSource.createMedicine(
      name: name,
      genericName: genericName,
      mrp: mrp,
      purchasePrice: purchasePrice,
      batchNumber: batchNumber,
      quantity: quantity,
      expiryDate: expiryDate,
      categoryId: categoryId,
      manufacturerId: manufacturerId,
    );
  }

  @override
  Future<Medicine> updateMedicine({
    required String id,
    required String name,
    String? genericName,
    String? categoryId,
    String? manufacturerId,
  }) {
    return _remoteDataSource.updateMedicine(
      id: id,
      name: name,
      genericName: genericName,
      categoryId: categoryId,
      manufacturerId: manufacturerId,
    );
  }

  @override
  Future<void> deleteMedicine({required String id}) {
    return _remoteDataSource.deleteMedicine(id: id);
  }

  @override
  Future<void> addBatch({
    required String medicineId,
    required String batchNumber,
    required int quantity,
    required String expiryDate,
    required double purchasePrice,
    required double mrp,
  }) {
    return _remoteDataSource.addBatch(
      medicineId: medicineId,
      batchNumber: batchNumber,
      quantity: quantity,
      expiryDate: expiryDate,
      purchasePrice: purchasePrice,
      mrp: mrp,
    );
  }
}

// Global Injectable InventoryRepository Provider
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final remoteDataSource = ref.watch(inventoryRemoteDataSourceProvider);
  return InventoryRepositoryImpl(remoteDataSource);
});
