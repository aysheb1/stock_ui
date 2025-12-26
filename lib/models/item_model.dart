class ItemModel {
  String code;
  String name;
  String unit;
  double criticalLevel;
  dynamic itemType;
  String? categories; // Sunta, Paketleme vb.

  ItemModel({
    required this.code,
    required this.name,
    required this.unit,
    required this.criticalLevel,
    required this.itemType,
    this.categories,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
        code: json["code"],
        name: json["name"],
        unit: json["unit"],
        itemType: json["itemType"],
        categories: json["categories"], // Backend'den categories al
        criticalLevel: (json["criticalLevel"] ?? 0).toDouble(),
      );

  // itemType'ı string'e dönüştür
  String get itemTypeLabel {
    if (itemType is int) {
      switch (itemType) {
        case 1:
          return "Material";
        case 2:
          return "Product";
        default:
          return "Bilinmiyor";
      }
    }
    return itemType.toString();
  }

  Map<String, dynamic> toJson() => {
        "code": code,
        "name": name,
        "unit": unit,
        "criticalLevel": criticalLevel,
        "itemType": itemType,
        "categories": categories,
      };
}
