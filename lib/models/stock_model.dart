class StockModel {
  String itemCode;
  String itemName;
  double quantity;
  double? criticalLevel;
  bool isCritical;

  StockModel({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    this.criticalLevel,
    required this.isCritical,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) => StockModel(
        itemCode: json["itemCode"],
        itemName: json["itemName"],
        quantity: (json["quantity"] ?? 0).toDouble(),
        criticalLevel: (json["criticalLevel"] ?? 0).toDouble(),
        isCritical: json["isCritical"],
      );
}
