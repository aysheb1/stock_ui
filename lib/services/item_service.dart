
import '../core/dio_service.dart';
import '../models/item_model.dart';
import '../temp_data/mock_inventory.dart';

class ItemService {
  Future<List<ItemModel>> getItems(String type) async {
    try {
      final res = await DioService.dio.get(
        "api/item/items",
        queryParameters: {"itemType": type},
      );
      return (res.data as List).map((e) => ItemModel.fromJson(e)).toList();
    } catch (e) {
      // Fallback to mock data when backend unavailable
      if (type == 'PRODUCT') {
        return MockInventory.products.map((p) {
          return ItemModel(
            code: p['code'] ?? '',
            name: p['name'] ?? '',
            unit: p['unit'] ?? 'adet',
            criticalLevel: (p['critical'] ?? 0).toDouble(),
            itemType: 'PRODUCT',
          );
        }).toList();
      } else {
        final list = MockInventory.itemsForCategory(type);
        return list.map((m) {
          return ItemModel(
            code: m['code'] ?? '',
            name: m['name'] ?? '',
            unit: m['unit'] ?? 'adet',
            criticalLevel: (m['critical'] ?? 0).toDouble(),
            itemType: type,
          );
        }).toList();
      }
    }
  }

  Future<ItemModel> getItem(String code) async {
    final res = await DioService.dio.get("api/item/$code");
    return ItemModel.fromJson(res.data);
  }

  Future<String> createItem(ItemModel item) async {
    try {
      final res = await DioService.dio.post("api/item", data: item.toJson());
      // ensure success status
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        return res.data;
      }
      throw Exception('Server returned ${res.statusCode}');
    } catch (e) {
      // Fallback: add to MockInventory so UI reflects created item when offline
      if (item.itemType == 'PRODUCT') {
        MockInventory.addProduct({
          'name': item.name,
          'code': item.code,
          'unit': item.unit,
          'stock': 0,
          'critical': item.criticalLevel.toInt(),
        });
      } else {
        MockInventory.addMaterialItem(item.itemType, {
          'code': item.code,
          'name': item.name,
          'unit': item.unit,
          'stock': 0,
          'critical': item.criticalLevel.toInt(),
        });
      }
      return 'mock-added';
    }
  }

  Future<void> deleteItem(String code) async {
    try {
      await DioService.dio.delete("api/item/$code");
    } catch (e) {
      print('Silme hatası: $e');
      throw Exception('Ürün silinirken hata oluştu');
    }
  }
}
