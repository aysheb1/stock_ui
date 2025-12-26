import '../core/dio_service.dart';
import '../models/stock_model.dart';
import '../models/adjust_request_model.dart';
import '../temp_data/mock_inventory.dart';

class StockService {
  Future<List<StockModel>> getStocks() async {
    final res = await DioService.dio.get("api/stocks");
    return (res.data as List)
        .map((e) => StockModel.fromJson(e))
        .toList();
  }

  Future<StockModel> getStockByCode(String code) async {
    try {
      final res = await DioService.dio.get("api/stocks/$code");
      return StockModel.fromJson(res.data);
    } catch (e) {
      // Fallback: find in mock products first
      final p = MockInventory.productByCode(code);
      if (p != null) {
        return StockModel(itemCode: p['code'], itemName: p['name'], quantity: (p['stock'] ?? 0).toDouble(), criticalLevel: (p['critical'] ?? 0).toDouble(), isCritical: (p['stock'] ?? 0) <= (p['critical'] ?? 0));
      }

      // Otherwise search materials
      for (var cat in MockInventory.materials) {
        for (var it in cat['items']) {
          if (it['code'] == code) {
            return StockModel(itemCode: it['code'], itemName: it['name'], quantity: (it['stock'] ?? 0).toDouble(), criticalLevel: (it['critical'] ?? 0).toDouble(), isCritical: (it['stock'] ?? 0) <= (it['critical'] ?? 0));
          }
        }
      }

      // fallback empty
      return StockModel(itemCode: code, itemName: '', quantity: 0, criticalLevel: 0, isCritical: true);
    }
  }

  Future<Map<String, dynamic>> adjustStock(AdjustRequestModel model) async {
    try {
      print('📤 Stok Ayarlama: ${model.itemCode} | Movement: ${model.movement} | Qty: ${model.quantity}');
      final res = await DioService.dio.post("api/stocks/adjust", data: model.toJson());
      print('✅ Response: ${res.data}');
      return res.data;
    } catch (e) {
      print('❌ Offline fallback: $e');
      // Apply change to mock inventory so UI can reflect adjustments while offline
      final code = model.itemCode;
      double qty = model.quantity;
      final movement = model.movement.toUpperCase();

      // Try products
      final p = MockInventory.productByCode(code);
      if (p != null) {
        if (movement == 'IN') {
          p['stock'] = (p['stock'] ?? 0) + qty.toInt();
        } else {
          p['stock'] = ((p['stock'] ?? 0) - qty.toInt()).clamp(0, 1 << 30);
        }
        return {'success': true, 'newStock': p['stock']};
      }

      // Try materials
      for (var cat in MockInventory.materials) {
        for (var it in cat['items']) {
          if (it['code'] == code) {
            if (movement == 'IN') {
              it['stock'] = (it['stock'] ?? 0) + qty.toInt();
            } else {
              it['stock'] = ((it['stock'] ?? 0) - qty.toInt()).clamp(0, 1 << 30);
            }
            return {'success': true, 'newStock': it['stock']};
          }
        }
      }

      return {'success': false};
    }
  }
}
