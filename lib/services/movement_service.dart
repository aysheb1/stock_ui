import '../core/dio_service.dart';
import '../models/stock_movement_model.dart';
import '../models/stock_movement_request_model.dart';

class MovementService {
  Future<List<StockMovementModel>> getMovements() async {
    final res = await DioService.dio.get("api/stockmovement");
    return (res.data as List)
        .map((e) => StockMovementModel.fromJson(e))
        .toList();
  }

  Future<void> recordMovement(StockMovementRequestModel movement) async {
    try {
      print('📝 Hareket Kaydı: ${movement.itemCode} | Type: ${movement.movementType} | Qty: ${movement.quantity}');
      // ⏸️ Backend'de POST endpoint'i eklenene kadar devre dışı
      // await DioService.dio.post("api/stockmovement", data: movement.toJson());
      print('✅ Hareket (mock) kaydedildi - Backend hareket kaydı yapacak');
    } catch (e) {
      print('❌ Hareket kaydı hatası: $e');
    }
  }
}
