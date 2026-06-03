// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'import_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ImportJob {

 String get id; String get tenantId; String get importType;// SUPPLIER_INVOICE, PDF_INVOICE
 String get importStatus;// UPLOADED, PROCESSING, COMPLETED, FAILED
 String get uploadedBy; String? get fileUrl; String? get fileName; String? get errorMessage; String? get purchaseOrderId; String? get processedAt; String get createdAt; String get updatedAt;
/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportJobCopyWith<ImportJob> get copyWith => _$ImportJobCopyWithImpl<ImportJob>(this as ImportJob, _$identity);

  /// Serializes this ImportJob to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportJob&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.importType, importType) || other.importType == importType)&&(identical(other.importStatus, importStatus) || other.importStatus == importStatus)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.purchaseOrderId, purchaseOrderId) || other.purchaseOrderId == purchaseOrderId)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,importType,importStatus,uploadedBy,fileUrl,fileName,errorMessage,purchaseOrderId,processedAt,createdAt,updatedAt);

@override
String toString() {
  return 'ImportJob(id: $id, tenantId: $tenantId, importType: $importType, importStatus: $importStatus, uploadedBy: $uploadedBy, fileUrl: $fileUrl, fileName: $fileName, errorMessage: $errorMessage, purchaseOrderId: $purchaseOrderId, processedAt: $processedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ImportJobCopyWith<$Res>  {
  factory $ImportJobCopyWith(ImportJob value, $Res Function(ImportJob) _then) = _$ImportJobCopyWithImpl;
@useResult
$Res call({
 String id, String tenantId, String importType, String importStatus, String uploadedBy, String? fileUrl, String? fileName, String? errorMessage, String? purchaseOrderId, String? processedAt, String createdAt, String updatedAt
});




}
/// @nodoc
class _$ImportJobCopyWithImpl<$Res>
    implements $ImportJobCopyWith<$Res> {
  _$ImportJobCopyWithImpl(this._self, this._then);

  final ImportJob _self;
  final $Res Function(ImportJob) _then;

/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tenantId = null,Object? importType = null,Object? importStatus = null,Object? uploadedBy = null,Object? fileUrl = freezed,Object? fileName = freezed,Object? errorMessage = freezed,Object? purchaseOrderId = freezed,Object? processedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,importType: null == importType ? _self.importType : importType // ignore: cast_nullable_to_non_nullable
as String,importStatus: null == importStatus ? _self.importStatus : importStatus // ignore: cast_nullable_to_non_nullable
as String,uploadedBy: null == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,purchaseOrderId: freezed == purchaseOrderId ? _self.purchaseOrderId : purchaseOrderId // ignore: cast_nullable_to_non_nullable
as String?,processedAt: freezed == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ImportJob].
extension ImportJobPatterns on ImportJob {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImportJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImportJob() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImportJob value)  $default,){
final _that = this;
switch (_that) {
case _ImportJob():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImportJob value)?  $default,){
final _that = this;
switch (_that) {
case _ImportJob() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tenantId,  String importType,  String importStatus,  String uploadedBy,  String? fileUrl,  String? fileName,  String? errorMessage,  String? purchaseOrderId,  String? processedAt,  String createdAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImportJob() when $default != null:
return $default(_that.id,_that.tenantId,_that.importType,_that.importStatus,_that.uploadedBy,_that.fileUrl,_that.fileName,_that.errorMessage,_that.purchaseOrderId,_that.processedAt,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tenantId,  String importType,  String importStatus,  String uploadedBy,  String? fileUrl,  String? fileName,  String? errorMessage,  String? purchaseOrderId,  String? processedAt,  String createdAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ImportJob():
return $default(_that.id,_that.tenantId,_that.importType,_that.importStatus,_that.uploadedBy,_that.fileUrl,_that.fileName,_that.errorMessage,_that.purchaseOrderId,_that.processedAt,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tenantId,  String importType,  String importStatus,  String uploadedBy,  String? fileUrl,  String? fileName,  String? errorMessage,  String? purchaseOrderId,  String? processedAt,  String createdAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ImportJob() when $default != null:
return $default(_that.id,_that.tenantId,_that.importType,_that.importStatus,_that.uploadedBy,_that.fileUrl,_that.fileName,_that.errorMessage,_that.purchaseOrderId,_that.processedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImportJob implements ImportJob {
  const _ImportJob({required this.id, required this.tenantId, required this.importType, required this.importStatus, required this.uploadedBy, this.fileUrl, this.fileName, this.errorMessage, this.purchaseOrderId, this.processedAt, required this.createdAt, required this.updatedAt});
  factory _ImportJob.fromJson(Map<String, dynamic> json) => _$ImportJobFromJson(json);

@override final  String id;
@override final  String tenantId;
@override final  String importType;
// SUPPLIER_INVOICE, PDF_INVOICE
@override final  String importStatus;
// UPLOADED, PROCESSING, COMPLETED, FAILED
@override final  String uploadedBy;
@override final  String? fileUrl;
@override final  String? fileName;
@override final  String? errorMessage;
@override final  String? purchaseOrderId;
@override final  String? processedAt;
@override final  String createdAt;
@override final  String updatedAt;

/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImportJobCopyWith<_ImportJob> get copyWith => __$ImportJobCopyWithImpl<_ImportJob>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImportJobToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImportJob&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.importType, importType) || other.importType == importType)&&(identical(other.importStatus, importStatus) || other.importStatus == importStatus)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.purchaseOrderId, purchaseOrderId) || other.purchaseOrderId == purchaseOrderId)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,importType,importStatus,uploadedBy,fileUrl,fileName,errorMessage,purchaseOrderId,processedAt,createdAt,updatedAt);

@override
String toString() {
  return 'ImportJob(id: $id, tenantId: $tenantId, importType: $importType, importStatus: $importStatus, uploadedBy: $uploadedBy, fileUrl: $fileUrl, fileName: $fileName, errorMessage: $errorMessage, purchaseOrderId: $purchaseOrderId, processedAt: $processedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ImportJobCopyWith<$Res> implements $ImportJobCopyWith<$Res> {
  factory _$ImportJobCopyWith(_ImportJob value, $Res Function(_ImportJob) _then) = __$ImportJobCopyWithImpl;
@override @useResult
$Res call({
 String id, String tenantId, String importType, String importStatus, String uploadedBy, String? fileUrl, String? fileName, String? errorMessage, String? purchaseOrderId, String? processedAt, String createdAt, String updatedAt
});




}
/// @nodoc
class __$ImportJobCopyWithImpl<$Res>
    implements _$ImportJobCopyWith<$Res> {
  __$ImportJobCopyWithImpl(this._self, this._then);

  final _ImportJob _self;
  final $Res Function(_ImportJob) _then;

/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tenantId = null,Object? importType = null,Object? importStatus = null,Object? uploadedBy = null,Object? fileUrl = freezed,Object? fileName = freezed,Object? errorMessage = freezed,Object? purchaseOrderId = freezed,Object? processedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ImportJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,importType: null == importType ? _self.importType : importType // ignore: cast_nullable_to_non_nullable
as String,importStatus: null == importStatus ? _self.importStatus : importStatus // ignore: cast_nullable_to_non_nullable
as String,uploadedBy: null == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,purchaseOrderId: freezed == purchaseOrderId ? _self.purchaseOrderId : purchaseOrderId // ignore: cast_nullable_to_non_nullable
as String?,processedAt: freezed == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
