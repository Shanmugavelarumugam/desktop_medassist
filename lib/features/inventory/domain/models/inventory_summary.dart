class InventorySummary {
  final int totalSKU;
  final int inStock;
  final int lowStock;
  final int outOfStock;
  final int expired;
  final double inventoryValue;

  const InventorySummary({
    this.totalSKU = 0,
    this.inStock = 0,
    this.lowStock = 0,
    this.outOfStock = 0,
    this.expired = 0,
    this.inventoryValue = 0.0,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    int getInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    double getDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return InventorySummary(
      totalSKU: getInt(
        json['totalSKU'] ??
            json['totalSKUs'] ??
            json['totalProducts'] ??
            json['totalItems'],
      ),
      inStock: getInt(
        json['inStock'] ?? json['inStockCount'] ?? json['activeStock'],
      ),
      lowStock: getInt(
        json['lowStock'] ?? json['lowStockCount'] ?? json['warningStock'],
      ),
      outOfStock: getInt(json['outOfStock'] ?? json['outOfStockCount']),
      expired: getInt(
        json['expired'] ?? json['expiredCount'] ?? json['expiredStock'],
      ),
      inventoryValue: getDouble(
        json['inventoryValue'] ?? json['totalValue'] ?? json['value'],
      ),
    );
  }
}
