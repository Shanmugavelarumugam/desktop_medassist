// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvoiceItem _$InvoiceItemFromJson(Map<String, dynamic> json) => _InvoiceItem(
  id: json['id'] as String,
  medicineId: json['medicineId'] as String,
  name: json['name'] as String,
  qty: (json['qty'] as num).toInt(),
  price: json['price'] as num,
  mrp: json['mrp'] as num,
  gst: json['gst'] as num,
  gstAmount: json['gstAmount'] as num,
  total: json['total'] as num,
  batchId: json['batchId'] as String,
  batchNumber: json['batchNumber'] as String,
);

Map<String, dynamic> _$InvoiceItemToJson(_InvoiceItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'medicineId': instance.medicineId,
      'name': instance.name,
      'qty': instance.qty,
      'price': instance.price,
      'mrp': instance.mrp,
      'gst': instance.gst,
      'gstAmount': instance.gstAmount,
      'total': instance.total,
      'batchId': instance.batchId,
      'batchNumber': instance.batchNumber,
    };

_Invoice _$InvoiceFromJson(Map<String, dynamic> json) => _Invoice(
  id: json['id'] as String,
  invoiceNumber: json['invoiceNumber'] as String,
  date: json['date'] as String,
  status: json['status'] as String,
  paymentStatus: json['paymentStatus'] as String,
  paymentMethod: json['paymentMethod'] as String,
  patientName: json['patientName'] as String,
  patientPhone: json['patientPhone'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  subtotal: json['subtotal'] as num,
  discount: json['discount'] as num,
  gst: json['gst'] as num,
  total: json['total'] as num,
  paidAmount: json['paidAmount'] as num,
  balanceAmount: json['balanceAmount'] as num,
  notes: json['notes'] as String?,
  pdfUrl: json['pdfUrl'] as String?,
);

Map<String, dynamic> _$InvoiceToJson(_Invoice instance) => <String, dynamic>{
  'id': instance.id,
  'invoiceNumber': instance.invoiceNumber,
  'date': instance.date,
  'status': instance.status,
  'paymentStatus': instance.paymentStatus,
  'paymentMethod': instance.paymentMethod,
  'patientName': instance.patientName,
  'patientPhone': instance.patientPhone,
  'items': instance.items,
  'subtotal': instance.subtotal,
  'discount': instance.discount,
  'gst': instance.gst,
  'total': instance.total,
  'paidAmount': instance.paidAmount,
  'balanceAmount': instance.balanceAmount,
  'notes': instance.notes,
  'pdfUrl': instance.pdfUrl,
};

_MedicineBatch _$MedicineBatchFromJson(Map<String, dynamic> json) =>
    _MedicineBatch(
      id: json['id'] as String,
      medicineId: json['medicineId'] as String,
      batchNumber: json['batchNumber'] as String,
      quantity: (json['quantity'] as num).toInt(),
      availableQuantity: (json['availableQuantity'] as num).toInt(),
      expiryDate: json['expiryDate'] as String,
      mrp: json['mrp'] as String,
      purchasePrice: json['purchasePrice'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$MedicineBatchToJson(_MedicineBatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'medicineId': instance.medicineId,
      'batchNumber': instance.batchNumber,
      'quantity': instance.quantity,
      'availableQuantity': instance.availableQuantity,
      'expiryDate': instance.expiryDate,
      'mrp': instance.mrp,
      'purchasePrice': instance.purchasePrice,
      'status': instance.status,
    };
