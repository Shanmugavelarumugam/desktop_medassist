import 'package:freezed_annotation/freezed_annotation.dart';

part 'medicine.freezed.dart';
part 'medicine.g.dart';

@freezed
abstract class MedicineCategory with _$MedicineCategory {
  const factory MedicineCategory({
    required String id,
    required String tenantId,
    required String name,
    String? description,
    String? parentId,
    required String createdAt,
    required String updatedAt,
  }) = _MedicineCategory;

  factory MedicineCategory.fromJson(Map<String, dynamic> json) =>
      _$MedicineCategoryFromJson(json);
}

@freezed
abstract class Manufacturer with _$Manufacturer {
  const factory Manufacturer({
    required String id,
    required String tenantId,
    required String name,
    String? contactEmail,
    String? phone,
    String? address,
    String? licenseNumber,
    String? gstNumber,
    required String createdAt,
    required String updatedAt,
  }) = _Manufacturer;

  factory Manufacturer.fromJson(Map<String, dynamic> json) =>
      _$ManufacturerFromJson(json);
}

@freezed
abstract class Medicine with _$Medicine {
  const factory Medicine({
    required String id,
    required String tenantId,
    required String name,
    String? genericName,
    String? categoryId,
    String? manufacturerId,
    num? gstPercentage,
    int? reorderLevel,
    bool? prescriptionRequired,
    bool? isActive,
    required String createdAt,
    required String updatedAt,
    required String status,
    MedicineCategory? category,
    Manufacturer? manufacturer,
    @Default(0) int stock,
    @Default(0) int availableStock,
    @Default(0) int reservedStock,
    String? batchId,
    String? batchNumber,
    String? expiryDate,
    @Default(0.0) double mrp,
    @Default(0.0) double purchasePrice,
  }) = _Medicine;

  factory Medicine.fromJson(Map<String, dynamic> json) =>
      _$MedicineFromJson(json);
}
