class StockMovementModel {
  String itemCode;
  String itemName;
  double quantity;
  String movement; // "In", "Out", "Adjust"
  int movementType; // 1=Giriş, 2=Çıkış, 3=Düzeltme
  String? note;
  DateTime createdAt;

  StockMovementModel({
    required this.itemCode,
    this.itemName = '',
    required this.quantity,
    required this.movement,
    this.movementType = 0,
    this.note,
    required this.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    // Movement String'i ("In", "Out", "Adjust") int'e çevir
    int _parseMovementType(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        switch (value.toLowerCase()) {
          case 'in':
          case 'giriş':
          case 'entry':
            return 1;
          case 'out':
          case 'çıkış':
          case 'exit':
            return 2;
          case 'adjust':
          case 'düzeltme':
          case 'adjustment':
            return 3;
          default:
            return 0;
        }
      }
      return 0;
    }

    return StockMovementModel(
      itemCode: json["itemCode"] ?? '',
      itemName: json["itemName"] ?? '',
      quantity: (json["quantity"] ?? 0).toDouble(),
      movement: json["movement"] ?? '',
      movementType: json["movementType"] != null 
          ? (json["movementType"] is int ? json["movementType"] : _parseMovementType(json["movementType"]))
          : _parseMovementType(json["movement"]),
      note: json["note"],
      createdAt: DateTime.parse(json["createdAt"] ?? DateTime.now().toIso8601String()),
    );
  }

  String get movementLabel {
    switch (movementType) {
      case 1:
        return "📥 Giriş";
      case 2:
        return "📤 Çıkış";
      case 3:
        return "⚙️ Düzeltme";
      default:
        return "❓ Bilinmiyor";
    }
  }

  Map<String, dynamic> toJson() => {
        "itemCode": itemCode,
        "itemName": itemName,
        "quantity": quantity,
        "movement": movement,
        "movementType": movementType,
        "note": note,
        "createdAt": createdAt.toIso8601String(),
      };
}
