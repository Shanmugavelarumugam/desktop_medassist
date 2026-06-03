// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'import_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImportState {

 bool get isLoading; bool get isUploading; String? get errorMessage; List<ImportJob> get importJobs;// Interactive ETL fields
 List<Map<String, String>> get parsedCsvData; List<String> get csvHeaders; List<Map<String, String>> get previewRows; Map<String, String> get columnMapping; String get supplier; String get duplicateStrategy; Map<String, dynamic> get barcodeOptions; Map<String, dynamic>? get analysisSummary; String get currentStep;// idle, parsed, checking, importing, complete
 String? get jobId; double get uploadProgress; String? get fileName; String? get fileSizeStr;
/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportStateCopyWith<ImportState> get copyWith => _$ImportStateCopyWithImpl<ImportState>(this as ImportState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isUploading, isUploading) || other.isUploading == isUploading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other.importJobs, importJobs)&&const DeepCollectionEquality().equals(other.parsedCsvData, parsedCsvData)&&const DeepCollectionEquality().equals(other.csvHeaders, csvHeaders)&&const DeepCollectionEquality().equals(other.previewRows, previewRows)&&const DeepCollectionEquality().equals(other.columnMapping, columnMapping)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.duplicateStrategy, duplicateStrategy) || other.duplicateStrategy == duplicateStrategy)&&const DeepCollectionEquality().equals(other.barcodeOptions, barcodeOptions)&&const DeepCollectionEquality().equals(other.analysisSummary, analysisSummary)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.uploadProgress, uploadProgress) || other.uploadProgress == uploadProgress)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileSizeStr, fileSizeStr) || other.fileSizeStr == fileSizeStr));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isUploading,errorMessage,const DeepCollectionEquality().hash(importJobs),const DeepCollectionEquality().hash(parsedCsvData),const DeepCollectionEquality().hash(csvHeaders),const DeepCollectionEquality().hash(previewRows),const DeepCollectionEquality().hash(columnMapping),supplier,duplicateStrategy,const DeepCollectionEquality().hash(barcodeOptions),const DeepCollectionEquality().hash(analysisSummary),currentStep,jobId,uploadProgress,fileName,fileSizeStr);

@override
String toString() {
  return 'ImportState(isLoading: $isLoading, isUploading: $isUploading, errorMessage: $errorMessage, importJobs: $importJobs, parsedCsvData: $parsedCsvData, csvHeaders: $csvHeaders, previewRows: $previewRows, columnMapping: $columnMapping, supplier: $supplier, duplicateStrategy: $duplicateStrategy, barcodeOptions: $barcodeOptions, analysisSummary: $analysisSummary, currentStep: $currentStep, jobId: $jobId, uploadProgress: $uploadProgress, fileName: $fileName, fileSizeStr: $fileSizeStr)';
}


}

/// @nodoc
abstract mixin class $ImportStateCopyWith<$Res>  {
  factory $ImportStateCopyWith(ImportState value, $Res Function(ImportState) _then) = _$ImportStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isUploading, String? errorMessage, List<ImportJob> importJobs, List<Map<String, String>> parsedCsvData, List<String> csvHeaders, List<Map<String, String>> previewRows, Map<String, String> columnMapping, String supplier, String duplicateStrategy, Map<String, dynamic> barcodeOptions, Map<String, dynamic>? analysisSummary, String currentStep, String? jobId, double uploadProgress, String? fileName, String? fileSizeStr
});




}
/// @nodoc
class _$ImportStateCopyWithImpl<$Res>
    implements $ImportStateCopyWith<$Res> {
  _$ImportStateCopyWithImpl(this._self, this._then);

  final ImportState _self;
  final $Res Function(ImportState) _then;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isUploading = null,Object? errorMessage = freezed,Object? importJobs = null,Object? parsedCsvData = null,Object? csvHeaders = null,Object? previewRows = null,Object? columnMapping = null,Object? supplier = null,Object? duplicateStrategy = null,Object? barcodeOptions = null,Object? analysisSummary = freezed,Object? currentStep = null,Object? jobId = freezed,Object? uploadProgress = null,Object? fileName = freezed,Object? fileSizeStr = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isUploading: null == isUploading ? _self.isUploading : isUploading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,importJobs: null == importJobs ? _self.importJobs : importJobs // ignore: cast_nullable_to_non_nullable
as List<ImportJob>,parsedCsvData: null == parsedCsvData ? _self.parsedCsvData : parsedCsvData // ignore: cast_nullable_to_non_nullable
as List<Map<String, String>>,csvHeaders: null == csvHeaders ? _self.csvHeaders : csvHeaders // ignore: cast_nullable_to_non_nullable
as List<String>,previewRows: null == previewRows ? _self.previewRows : previewRows // ignore: cast_nullable_to_non_nullable
as List<Map<String, String>>,columnMapping: null == columnMapping ? _self.columnMapping : columnMapping // ignore: cast_nullable_to_non_nullable
as Map<String, String>,supplier: null == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as String,duplicateStrategy: null == duplicateStrategy ? _self.duplicateStrategy : duplicateStrategy // ignore: cast_nullable_to_non_nullable
as String,barcodeOptions: null == barcodeOptions ? _self.barcodeOptions : barcodeOptions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,analysisSummary: freezed == analysisSummary ? _self.analysisSummary : analysisSummary // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as String,jobId: freezed == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as String?,uploadProgress: null == uploadProgress ? _self.uploadProgress : uploadProgress // ignore: cast_nullable_to_non_nullable
as double,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,fileSizeStr: freezed == fileSizeStr ? _self.fileSizeStr : fileSizeStr // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ImportState].
extension ImportStatePatterns on ImportState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImportState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImportState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImportState value)  $default,){
final _that = this;
switch (_that) {
case _ImportState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImportState value)?  $default,){
final _that = this;
switch (_that) {
case _ImportState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isUploading,  String? errorMessage,  List<ImportJob> importJobs,  List<Map<String, String>> parsedCsvData,  List<String> csvHeaders,  List<Map<String, String>> previewRows,  Map<String, String> columnMapping,  String supplier,  String duplicateStrategy,  Map<String, dynamic> barcodeOptions,  Map<String, dynamic>? analysisSummary,  String currentStep,  String? jobId,  double uploadProgress,  String? fileName,  String? fileSizeStr)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImportState() when $default != null:
return $default(_that.isLoading,_that.isUploading,_that.errorMessage,_that.importJobs,_that.parsedCsvData,_that.csvHeaders,_that.previewRows,_that.columnMapping,_that.supplier,_that.duplicateStrategy,_that.barcodeOptions,_that.analysisSummary,_that.currentStep,_that.jobId,_that.uploadProgress,_that.fileName,_that.fileSizeStr);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isUploading,  String? errorMessage,  List<ImportJob> importJobs,  List<Map<String, String>> parsedCsvData,  List<String> csvHeaders,  List<Map<String, String>> previewRows,  Map<String, String> columnMapping,  String supplier,  String duplicateStrategy,  Map<String, dynamic> barcodeOptions,  Map<String, dynamic>? analysisSummary,  String currentStep,  String? jobId,  double uploadProgress,  String? fileName,  String? fileSizeStr)  $default,) {final _that = this;
switch (_that) {
case _ImportState():
return $default(_that.isLoading,_that.isUploading,_that.errorMessage,_that.importJobs,_that.parsedCsvData,_that.csvHeaders,_that.previewRows,_that.columnMapping,_that.supplier,_that.duplicateStrategy,_that.barcodeOptions,_that.analysisSummary,_that.currentStep,_that.jobId,_that.uploadProgress,_that.fileName,_that.fileSizeStr);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isUploading,  String? errorMessage,  List<ImportJob> importJobs,  List<Map<String, String>> parsedCsvData,  List<String> csvHeaders,  List<Map<String, String>> previewRows,  Map<String, String> columnMapping,  String supplier,  String duplicateStrategy,  Map<String, dynamic> barcodeOptions,  Map<String, dynamic>? analysisSummary,  String currentStep,  String? jobId,  double uploadProgress,  String? fileName,  String? fileSizeStr)?  $default,) {final _that = this;
switch (_that) {
case _ImportState() when $default != null:
return $default(_that.isLoading,_that.isUploading,_that.errorMessage,_that.importJobs,_that.parsedCsvData,_that.csvHeaders,_that.previewRows,_that.columnMapping,_that.supplier,_that.duplicateStrategy,_that.barcodeOptions,_that.analysisSummary,_that.currentStep,_that.jobId,_that.uploadProgress,_that.fileName,_that.fileSizeStr);case _:
  return null;

}
}

}

/// @nodoc


class _ImportState implements ImportState {
  const _ImportState({this.isLoading = false, this.isUploading = false, this.errorMessage, final  List<ImportJob> importJobs = const [], final  List<Map<String, String>> parsedCsvData = const [], final  List<String> csvHeaders = const [], final  List<Map<String, String>> previewRows = const [], final  Map<String, String> columnMapping = const {}, this.supplier = 'None', this.duplicateStrategy = 'Skip', final  Map<String, dynamic> barcodeOptions = const {'autoGen' : true, 'overwrite' : false, 'validate' : true}, final  Map<String, dynamic>? analysisSummary, this.currentStep = 'idle', this.jobId, this.uploadProgress = 0.0, this.fileName, this.fileSizeStr}): _importJobs = importJobs,_parsedCsvData = parsedCsvData,_csvHeaders = csvHeaders,_previewRows = previewRows,_columnMapping = columnMapping,_barcodeOptions = barcodeOptions,_analysisSummary = analysisSummary;
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isUploading;
@override final  String? errorMessage;
 final  List<ImportJob> _importJobs;
@override@JsonKey() List<ImportJob> get importJobs {
  if (_importJobs is EqualUnmodifiableListView) return _importJobs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_importJobs);
}

// Interactive ETL fields
 final  List<Map<String, String>> _parsedCsvData;
// Interactive ETL fields
@override@JsonKey() List<Map<String, String>> get parsedCsvData {
  if (_parsedCsvData is EqualUnmodifiableListView) return _parsedCsvData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parsedCsvData);
}

 final  List<String> _csvHeaders;
@override@JsonKey() List<String> get csvHeaders {
  if (_csvHeaders is EqualUnmodifiableListView) return _csvHeaders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_csvHeaders);
}

 final  List<Map<String, String>> _previewRows;
@override@JsonKey() List<Map<String, String>> get previewRows {
  if (_previewRows is EqualUnmodifiableListView) return _previewRows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_previewRows);
}

 final  Map<String, String> _columnMapping;
@override@JsonKey() Map<String, String> get columnMapping {
  if (_columnMapping is EqualUnmodifiableMapView) return _columnMapping;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_columnMapping);
}

@override@JsonKey() final  String supplier;
@override@JsonKey() final  String duplicateStrategy;
 final  Map<String, dynamic> _barcodeOptions;
@override@JsonKey() Map<String, dynamic> get barcodeOptions {
  if (_barcodeOptions is EqualUnmodifiableMapView) return _barcodeOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_barcodeOptions);
}

 final  Map<String, dynamic>? _analysisSummary;
@override Map<String, dynamic>? get analysisSummary {
  final value = _analysisSummary;
  if (value == null) return null;
  if (_analysisSummary is EqualUnmodifiableMapView) return _analysisSummary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  String currentStep;
// idle, parsed, checking, importing, complete
@override final  String? jobId;
@override@JsonKey() final  double uploadProgress;
@override final  String? fileName;
@override final  String? fileSizeStr;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImportStateCopyWith<_ImportState> get copyWith => __$ImportStateCopyWithImpl<_ImportState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImportState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isUploading, isUploading) || other.isUploading == isUploading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other._importJobs, _importJobs)&&const DeepCollectionEquality().equals(other._parsedCsvData, _parsedCsvData)&&const DeepCollectionEquality().equals(other._csvHeaders, _csvHeaders)&&const DeepCollectionEquality().equals(other._previewRows, _previewRows)&&const DeepCollectionEquality().equals(other._columnMapping, _columnMapping)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.duplicateStrategy, duplicateStrategy) || other.duplicateStrategy == duplicateStrategy)&&const DeepCollectionEquality().equals(other._barcodeOptions, _barcodeOptions)&&const DeepCollectionEquality().equals(other._analysisSummary, _analysisSummary)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.uploadProgress, uploadProgress) || other.uploadProgress == uploadProgress)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileSizeStr, fileSizeStr) || other.fileSizeStr == fileSizeStr));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isUploading,errorMessage,const DeepCollectionEquality().hash(_importJobs),const DeepCollectionEquality().hash(_parsedCsvData),const DeepCollectionEquality().hash(_csvHeaders),const DeepCollectionEquality().hash(_previewRows),const DeepCollectionEquality().hash(_columnMapping),supplier,duplicateStrategy,const DeepCollectionEquality().hash(_barcodeOptions),const DeepCollectionEquality().hash(_analysisSummary),currentStep,jobId,uploadProgress,fileName,fileSizeStr);

@override
String toString() {
  return 'ImportState(isLoading: $isLoading, isUploading: $isUploading, errorMessage: $errorMessage, importJobs: $importJobs, parsedCsvData: $parsedCsvData, csvHeaders: $csvHeaders, previewRows: $previewRows, columnMapping: $columnMapping, supplier: $supplier, duplicateStrategy: $duplicateStrategy, barcodeOptions: $barcodeOptions, analysisSummary: $analysisSummary, currentStep: $currentStep, jobId: $jobId, uploadProgress: $uploadProgress, fileName: $fileName, fileSizeStr: $fileSizeStr)';
}


}

/// @nodoc
abstract mixin class _$ImportStateCopyWith<$Res> implements $ImportStateCopyWith<$Res> {
  factory _$ImportStateCopyWith(_ImportState value, $Res Function(_ImportState) _then) = __$ImportStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isUploading, String? errorMessage, List<ImportJob> importJobs, List<Map<String, String>> parsedCsvData, List<String> csvHeaders, List<Map<String, String>> previewRows, Map<String, String> columnMapping, String supplier, String duplicateStrategy, Map<String, dynamic> barcodeOptions, Map<String, dynamic>? analysisSummary, String currentStep, String? jobId, double uploadProgress, String? fileName, String? fileSizeStr
});




}
/// @nodoc
class __$ImportStateCopyWithImpl<$Res>
    implements _$ImportStateCopyWith<$Res> {
  __$ImportStateCopyWithImpl(this._self, this._then);

  final _ImportState _self;
  final $Res Function(_ImportState) _then;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isUploading = null,Object? errorMessage = freezed,Object? importJobs = null,Object? parsedCsvData = null,Object? csvHeaders = null,Object? previewRows = null,Object? columnMapping = null,Object? supplier = null,Object? duplicateStrategy = null,Object? barcodeOptions = null,Object? analysisSummary = freezed,Object? currentStep = null,Object? jobId = freezed,Object? uploadProgress = null,Object? fileName = freezed,Object? fileSizeStr = freezed,}) {
  return _then(_ImportState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isUploading: null == isUploading ? _self.isUploading : isUploading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,importJobs: null == importJobs ? _self._importJobs : importJobs // ignore: cast_nullable_to_non_nullable
as List<ImportJob>,parsedCsvData: null == parsedCsvData ? _self._parsedCsvData : parsedCsvData // ignore: cast_nullable_to_non_nullable
as List<Map<String, String>>,csvHeaders: null == csvHeaders ? _self._csvHeaders : csvHeaders // ignore: cast_nullable_to_non_nullable
as List<String>,previewRows: null == previewRows ? _self._previewRows : previewRows // ignore: cast_nullable_to_non_nullable
as List<Map<String, String>>,columnMapping: null == columnMapping ? _self._columnMapping : columnMapping // ignore: cast_nullable_to_non_nullable
as Map<String, String>,supplier: null == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as String,duplicateStrategy: null == duplicateStrategy ? _self.duplicateStrategy : duplicateStrategy // ignore: cast_nullable_to_non_nullable
as String,barcodeOptions: null == barcodeOptions ? _self._barcodeOptions : barcodeOptions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,analysisSummary: freezed == analysisSummary ? _self._analysisSummary : analysisSummary // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as String,jobId: freezed == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as String?,uploadProgress: null == uploadProgress ? _self.uploadProgress : uploadProgress // ignore: cast_nullable_to_non_nullable
as double,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,fileSizeStr: freezed == fileSizeStr ? _self.fileSizeStr : fileSizeStr // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
