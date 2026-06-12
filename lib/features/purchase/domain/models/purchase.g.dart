// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Supplier _$SupplierFromJson(Map<String, dynamic> json) => _Supplier(
  id: json['id'] as String? ?? '',
  tenantId: json['tenantId'] as String? ?? '',
  name: json['name'] as String,
  phone: json['phone'] as String? ?? '',
  email: json['email'] as String? ?? '',
  gstNumber: json['gstNumber'] as String? ?? '',
  address: json['address'] as String? ?? '',
  createdAt: json['createdAt'] as String? ?? '',
  updatedAt: json['updatedAt'] as String? ?? '',
  supplierCode: json['supplierCode'] as String?,
  supplierType: json['supplierType'] as String?,
  contactPerson: json['contactPerson'] as String?,
  drugLicenseNumber: json['drugLicenseNumber'] as String?,
  licenseExpiry: json['licenseExpiry'] as String?,
  status: json['status'] as String? ?? 'ACTIVE',
  isPreferred: json['isPreferred'] as bool? ?? false,
  rating: _parseDouble(json['rating']),
  leadTimeDays: json['leadTimeDays'] == null
      ? 7
      : _parseIntWithDefault7(json['leadTimeDays']),
  paymentTermsDays: json['paymentTermsDays'] == null
      ? 30
      : _parseIntWithDefault30(json['paymentTermsDays']),
  creditLimit: _parseDouble(json['creditLimit']),
  outstandingBalance: _parseDouble(json['outstandingBalance']),
  totalPurchases: _parseDouble(json['totalPurchases']),
  bankName: json['bankName'] as String?,
  accountNumber: json['accountNumber'] as String?,
  ifscCode: json['ifscCode'] as String?,
);

Map<String, dynamic> _$SupplierToJson(_Supplier instance) => <String, dynamic>{
  'id': instance.id,
  'tenantId': instance.tenantId,
  'name': instance.name,
  'phone': instance.phone,
  'email': instance.email,
  'gstNumber': instance.gstNumber,
  'address': instance.address,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'supplierCode': instance.supplierCode,
  'supplierType': instance.supplierType,
  'contactPerson': instance.contactPerson,
  'drugLicenseNumber': instance.drugLicenseNumber,
  'licenseExpiry': instance.licenseExpiry,
  'status': instance.status,
  'isPreferred': instance.isPreferred,
  'rating': instance.rating,
  'leadTimeDays': instance.leadTimeDays,
  'paymentTermsDays': instance.paymentTermsDays,
  'creditLimit': instance.creditLimit,
  'outstandingBalance': instance.outstandingBalance,
  'totalPurchases': instance.totalPurchases,
  'bankName': instance.bankName,
  'accountNumber': instance.accountNumber,
  'ifscCode': instance.ifscCode,
};

_PurchaseOrderItem _$PurchaseOrderItemFromJson(Map<String, dynamic> json) =>
    _PurchaseOrderItem(
      id: json['id'] as String,
      purchaseOrderId: json['purchaseOrderId'] as String,
      medicineId: json['medicineId'] as String,
      medicineName: json['medicineName'] as String,
      currentStock: (json['currentStock'] as num).toInt(),
      reorderQty: (json['reorderQty'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      receivedQuantity: (json['receivedQuantity'] as num).toInt(),
      unitPrice: json['unitPrice'] as String,
      gstPercentage: (json['gstPercentage'] as num).toDouble(),
      totalAmount: json['totalAmount'] as String,
    );

Map<String, dynamic> _$PurchaseOrderItemToJson(_PurchaseOrderItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'purchaseOrderId': instance.purchaseOrderId,
      'medicineId': instance.medicineId,
      'medicineName': instance.medicineName,
      'currentStock': instance.currentStock,
      'reorderQty': instance.reorderQty,
      'quantity': instance.quantity,
      'receivedQuantity': instance.receivedQuantity,
      'unitPrice': instance.unitPrice,
      'gstPercentage': instance.gstPercentage,
      'totalAmount': instance.totalAmount,
    };

_PurchaseOrder _$PurchaseOrderFromJson(Map<String, dynamic> json) =>
    _PurchaseOrder(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      branchId: json['branchId'] as String?,
      userId: json['userId'] as String,
      supplierId: json['supplierId'] as String,
      orderNumber: json['orderNumber'] as String,
      status: json['status'] as String,
      subtotal: json['subtotal'] as String,
      gstAmount: json['gstAmount'] as String,
      totalAmount: json['totalAmount'] as String,
      notes: json['notes'] as String?,
      expectedDeliveryDate: json['expectedDeliveryDate'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      approvedAt: json['approvedAt'] as String?,
      approvedBy: json['approvedBy'] as String?,
      cancelledAt: json['cancelledAt'] as String?,
      supplier: json['supplier'] == null
          ? null
          : Supplier.fromJson(json['supplier'] as Map<String, dynamic>),
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PurchaseOrderToJson(_PurchaseOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'branchId': instance.branchId,
      'userId': instance.userId,
      'supplierId': instance.supplierId,
      'orderNumber': instance.orderNumber,
      'status': instance.status,
      'subtotal': instance.subtotal,
      'gstAmount': instance.gstAmount,
      'totalAmount': instance.totalAmount,
      'notes': instance.notes,
      'expectedDeliveryDate': instance.expectedDeliveryDate,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'approvedAt': instance.approvedAt,
      'approvedBy': instance.approvedBy,
      'cancelledAt': instance.cancelledAt,
      'supplier': instance.supplier,
      'items': instance.items,
    };
