class AdjustRequestModel {
  String itemCode;
  double quantity;
  String movement;
  String? note;

  AdjustRequestModel({
    required this.itemCode,
    required this.quantity,
    required this.movement,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        "itemCode": itemCode,
        "quantity": quantity,
        "movement": movement,
        "note": note,
      };
}
