import 'package:flutter/material.dart';
import '../services/item_service.dart';
import '../services/stock_service.dart';
import '../services/movement_service.dart';
import '../models/item_model.dart';
import '../models/stock_model.dart';
import '../models/stock_movement_model.dart';
import 'category_detail_screen.dart';
import 'product_list_screen.dart';

class AllItemsListScreen extends StatefulWidget {
  const AllItemsListScreen({super.key});

  @override
  State<AllItemsListScreen> createState() => _AllItemsListScreenState();
}

class _AllItemsListScreenState extends State<AllItemsListScreen> {
  final ItemService _itemService = ItemService();
  final StockService _stockService = StockService();
  final MovementService _movementService = MovementService();
  
  bool loading = true;
  List<ItemModel> allItems = [];
  Map<String, StockModel> stockMap = {};
  Map<String, List<StockMovementModel>> movementsByItem = {};
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllItems();
  }

  Future<void> _loadAllItems() async {
    setState(() => loading = true);
    try {
      // Material ve Product ürünlerini al
      final materials = await _itemService.getItems('Material');
      final products = await _itemService.getItems('Product');
      allItems = [...materials, ...products];

      // Tüm ürünlerin stok bilgilerini al
      final stocks = await Future.wait(allItems.map((item) async {
        try {
          return await _stockService.getStockByCode(item.code);
        } catch (_) {
          return StockModel(
            itemCode: item.code,
            itemName: item.name,
            quantity: 0,
            criticalLevel: item.criticalLevel,
            isCritical: false,
          );
        }
      }));
      stockMap = {for (var s in stocks) s.itemCode: s};

      // Stok hareketlerini al
      try {
        final movements = await _movementService.getMovements();
        print('✅ Toplam hareket: ${movements.length}');
        for (var m in movements.take(3)) {
          print('🔍 Hareket: ${m.itemCode} | Type: ${m.movementType} | Label: ${m.movementLabel}');
        }
        movementsByItem = {};
        for (var movement in movements) {
          if (!movementsByItem.containsKey(movement.itemCode)) {
            movementsByItem[movement.itemCode] = [];
          }
          movementsByItem[movement.itemCode]!.add(movement);
        }
      } catch (e) {
        print('❌ Hareket yükleme hatası: $e');
      }
    } catch (e) {
      print('❌ Ürün yükleme hatası: $e');
      allItems = [];
      stockMap = {};
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  List<ItemModel> get filteredItems {
    if (searchQuery.isEmpty) {
      return allItems;
    }
    return allItems.where((item) {
      return item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.code.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tüm Ürünler'),
      ),
      body: Column(
        children: [
          // Arama kutusu
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Ürün adı veya kod ara...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Ürün listesi
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          searchQuery.isEmpty
                              ? 'Ürün bulunamadı'
                              : 'Eşleşen ürün yok',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final stock = stockMap[item.code];
                          final movements = movementsByItem[item.code] ?? [];

                          return _buildItemCard(item, stock, movements);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    ItemModel item,
    StockModel? stock,
    List<StockMovementModel> movements,
  ) {
    final quantity = stock?.quantity ?? 0;
    final isCritical = (stock?.criticalLevel ?? 0) > 0 && quantity <= (stock?.criticalLevel ?? 0);

    return GestureDetector(
      onTap: () {
        // Ürün türüne göre ilgili kategoriye git
        if (item.itemType == 1) {
          // Material
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryDetailScreen(category: item.categories ?? 'Diğer'),
            ),
          );
        } else if (item.itemType == 2) {
          // Product
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductCategoryDetailScreen(category: item.categories ?? 'Diğer'),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün Bilgisi
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kod: ${item.code}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Kategori: ${item.categories ?? 'Bilinmiyor'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Stok Bilgisi
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCritical ? Colors.red.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Stok: $quantity',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCritical ? Colors.red : Colors.blue,
                        ),
                      ),
                      Text(
                        item.unit,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (isCritical)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '⚠️ Kritik',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
