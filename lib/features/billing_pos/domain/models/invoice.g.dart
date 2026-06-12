// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

// Helper: safely parse a value that may be String or num into num
num _safeNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

// Helper: safely parse a value that may be String or num into int
int _safeInt(dynamic v) => _safeNum(v).toInt();

_InvoiceItem _$InvoiceItemFromJson(Map<String, dynamic> json) => _InvoiceItem(
  id: json['id']?.toString() ?? '',
  medicineId: json['medicineId']?.toString() ?? '',
  name: json['name']?.toString() ?? '',
  qty: _safeInt(json['qty']),
  price: _safeNum(json['price']),
  mrp: _safeNum(json['mrp']),
  gst: _safeNum(json['gst']),
  gstAmount: _safeNum(json['gstAmount']),
  total: _safeNum(json['total']),
  batchId: json['batchId']?.toString() ?? '',
  batchNumber: json['batchNumber']?.toString() ?? '',
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
  id: json['id']?.toString() ?? '',
  invoiceNumber: json['invoiceNumber']?.toString() ?? '',
  date: json['date']?.toString() ?? '',
  status: json['status']?.toString() ?? '',
  paymentStatus: json['paymentStatus']?.toString() ?? '',
  paymentMethod: json['paymentMethod']?.toString() ?? '',
  patientName: json['patientName']?.toString() ?? '',
  patientPhone: json['patientPhone']?.toString() ?? '',
  items: ((json['items'] as List<dynamic>?) ?? [])
      .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  subtotal: _safeNum(json['subtotal']),
  discount: _safeNum(json['discount']),
  gst: _safeNum(json['gst']),
  total: _safeNum(json['total']),
  paidAmount: _safeNum(json['paidAmount']),
  balanceAmount: _safeNum(json['balanceAmount']),
  notes: json['notes']?.toString(),
  pdfUrl: json['pdfUrl']?.toString(),
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
      id: json['id']?.toString() ?? '',
      medicineId: json['medicineId']?.toString() ?? '',
      batchNumber: json['batchNumber']?.toString() ?? '',
      quantity: _safeInt(json['quantity']),
      availableQuantity: _safeInt(json['availableQuantity']),
      expiryDate: json['expiryDate']?.toString() ?? '',
      mrp: json['mrp'],
      purchasePrice: json['purchasePrice'],
      status: json['status']?.toString(),
      medicineName: json['medicineName']?.toString(),
      medicine: json['medicine'] as Map<String, dynamic>?,
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
      'medicineName': instance.medicineName,
      'medicine': instance.medicine,
    };
