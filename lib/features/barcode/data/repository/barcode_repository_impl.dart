import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../inventory/domain/models/medicine.dart';
import '../../domain/repository/barcode_repository.dart';
import '../datasource/barcode_remote_datasource.dart';

class BarcodeRepositoryImpl implements BarcodeRepository {
  final BarcodeRemoteDataSource _remoteDataSource;

  BarcodeRepositoryImpl(this._remoteDataSource);

  @override
  Future<Uint8List> generateBarcode({
    required String text,
    String type = 'code128',
  }) {
    return _remoteDataSource.generateBarcode(text: text, type: type);
  }

  @override
  Future<Medicine?> lookupMedicineByBarcode(String barcode) {
    return _remoteDataSource.lookupMedicineByBarcode(barcode);
  }
}

final barcodeRepositoryProvider = Provider<BarcodeRepository>((ref) {
  final dataSource = ref.watch(barcodeRemoteDataSourceProvider);
  return BarcodeRepositoryImpl(dataSource);
});
