// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ImportJob _$ImportJobFromJson(Map<String, dynamic> json) => _ImportJob(
  id: json['id'] as String,
  tenantId: json['tenantId'] as String,
  importType: json['importType'] as String,
  importStatus: json['importStatus'] as String,
  uploadedBy: json['uploadedBy'] as String,
  fileUrl: json['fileUrl'] as String?,
  fileName: json['fileName'] as String?,
  errorMessage: json['errorMessage'] as String?,
  purchaseOrderId: json['purchaseOrderId'] as String?,
  processedAt: json['processedAt'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$ImportJobToJson(_ImportJob instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'importType': instance.importType,
      'importStatus': instance.importStatus,
      'uploadedBy': instance.uploadedBy,
      'fileUrl': instance.fileUrl,
      'fileName': instance.fileName,
      'errorMessage': instance.errorMessage,
      'purchaseOrderId': instance.purchaseOrderId,
      'processedAt': instance.processedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
