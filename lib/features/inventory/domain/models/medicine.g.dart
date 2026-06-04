// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MedicineCategory _$MedicineCategoryFromJson(Map<String, dynamic> json) =>
    _MedicineCategory(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parentId: json['parentId'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$MedicineCategoryToJson(_MedicineCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'name': instance.name,
      'description': instance.description,
      'parentId': instance.parentId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_Manufacturer _$ManufacturerFromJson(Map<String, dynamic> json) =>
    _Manufacturer(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      name: json['name'] as String,
      contactEmail: json['contactEmail'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      gstNumber: json['gstNumber'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$ManufacturerToJson(_Manufacturer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'name': instance.name,
      'contactEmail': instance.contactEmail,
      'phone': instance.phone,
      'address': instance.address,
      'licenseNumber': instance.licenseNumber,
      'gstNumber': instance.gstNumber,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_Medicine _$MedicineFromJson(Map<String, dynamic> json) => _Medicine(
  id: json['id'] as String,
  tenantId: json['tenantId'] as String,
  name: json['name'] as String,
  genericName: json['genericName'] as String?,
  categoryId: json['categoryId'] as String?,
  manufacturerId: json['manufacturerId'] as String?,
  gstPercentage: json['gstPercentage'] as num?,
  reorderLevel: (json['reorderLevel'] as num?)?.toInt(),
  prescriptionRequired: json['prescriptionRequired'] as bool?,
  isActive: json['isActive'] as bool?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  status: json['status'] as String,
  category: json['category'] == null
      ? null
      : MedicineCategory.fromJson(json['category'] as Map<String, dynamic>),
  manufacturer: json['manufacturer'] == null
      ? null
      : Manufacturer.fromJson(json['manufacturer'] as Map<String, dynamic>),
  stock: (json['stock'] as num?)?.toInt() ?? 0,
  availableStock: (json['availableStock'] as num?)?.toInt() ?? 0,
  reservedStock: (json['reservedStock'] as num?)?.toInt() ?? 0,
  batchId: json['batchId'] as String?,
  batchNumber: json['batchNumber'] as String?,
  expiryDate: json['expiryDate'] as String?,
  mrp: (json['mrp'] as num?)?.toDouble() ?? 0.0,
  purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
  hsnCode: json['hsnCode'] as String?,
  barcode: json['barcode'] as String?,
  supplier: json['supplier'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$MedicineToJson(_Medicine instance) => <String, dynamic>{
  'id': instance.id,
  'tenantId': instance.tenantId,
  'name': instance.name,
  'genericName': instance.genericName,
  'categoryId': instance.categoryId,
  'manufacturerId': instance.manufacturerId,
  'gstPercentage': instance.gstPercentage,
  'reorderLevel': instance.reorderLevel,
  'prescriptionRequired': instance.prescriptionRequired,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'status': instance.status,
  'category': instance.category,
  'manufacturer': instance.manufacturer,
  'stock': instance.stock,
  'availableStock': instance.availableStock,
  'reservedStock': instance.reservedStock,
  'batchId': instance.batchId,
  'batchNumber': instance.batchNumber,
  'expiryDate': instance.expiryDate,
  'mrp': instance.mrp,
  'purchasePrice': instance.purchasePrice,
  'hsnCode': instance.hsnCode,
  'barcode': instance.barcode,
  'supplier': instance.supplier,
  'notes': instance.notes,
};
