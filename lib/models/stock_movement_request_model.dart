class StockMovementRequestModel {
  String itemCode;
  int quantity;
  int movementType; // 1=Giriş, 2=Çıkış, 3=Düzeltme
  String? note;

  StockMovementRequestModel({
    required this.itemCode,
    required this.quantity,
    required this.movementType,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        "itemCode": itemCode,
        "quantity": quantity,
        "movementType": movementType,
        "note": note,
      };
}
