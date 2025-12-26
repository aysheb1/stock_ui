import 'package:flutter/material.dart';
import '../services/item_service.dart';
import '../services/stock_service.dart';
import 'add_item_screen.dart';
import '../models/item_model.dart';
import '../models/stock_model.dart';
import '../models/adjust_request_model.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late List<ItemModel> items = [];
  final ItemService _itemService = ItemService();
  final StockService _stockService = StockService();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => loading = true);
    try {
      // Always fetch Material type items
      final fetched = await _itemService.getItems("Material");

      // Kategoriyi kontrol et - sadece ilgili kategoriye ait item'ları göster
      final filteredItems = fetched.where((item) {
        return item.categories != null && 
               item.categories!.toLowerCase() == widget.category.toLowerCase();
      }).toList();

      // For each filtered item fetch stock by code in parallel
      final stocks = await Future.wait(filteredItems.map((i) async {
        try {
          final s = await _stockService.getStockByCode(i.code);
          return s;
        } catch (_) {
          return StockModel(itemCode: i.code, itemName: i.name, quantity: 0, criticalLevel: i.criticalLevel, isCritical: false);
        }
      }));

      // merge into a single list representation by attaching stock
      items = filteredItems;  // Filtrelenmiş item'ları kullan
      // attach quantities to a local map using a Map<String, double>
      // We'll keep stocks in a map for quick access
      _stockMap = {for (var s in stocks) s.itemCode: s};
    } catch (e) {
      print('❌ Item yükleme hatası: $e');
      items = [];
    }
    if (mounted) {
      setState(() => loading = false);
    }
  }

  Map<String, StockModel> _stockMap = {};
  Map<String, TextEditingController> _qtyControllers = {};

  Future<void> _adjust(ItemModel item, double qty, String movement) async {
    // + ve - butonları için doğrudan işlem yap
    final adj = AdjustRequestModel(itemCode: item.code, quantity: qty, movement: movement);
    try {
      await _stockService.adjustStock(adj);
      final cur = _stockMap[item.code]?.quantity ?? 0;
      final newQty = movement == 'IN' ? cur + qty : cur - qty;
      if (mounted) {
        setState(() => _stockMap[item.code] = StockModel(itemCode: item.code, itemName: item.name, quantity: newQty, criticalLevel: item.criticalLevel, isCritical: newQty <= item.criticalLevel));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok güncellenemedi')));
    }
  }

  // Input alanında Enter basılınca çağrılacak - confirmation gösterecek
  Future<void> _adjustWithConfirmation(ItemModel item, double inputValue) async {
    final currentStock = _stockMap[item.code]?.quantity ?? 0;
    
    // Input değeri ile mevcut stok aynıysa dialog gösterme
    if ((inputValue - currentStock).abs() < 0.01) {
      return;
    }

    // Dialog göster
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stok Güncellemesi'),
        content: Text(
          '${item.name} için stoku ${currentStock.toStringAsFixed(2)} → ${inputValue.toStringAsFixed(2)} olarak ayarlamak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSetStock(item, currentStock, inputValue);
            },
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSetStock(ItemModel item, double currentStock, double newValue) async {
    try {
      // Farkı hesapla
      final difference = newValue - currentStock;
      final quantity = difference.abs();
      final movement = difference > 0 ? 'IN' : 'OUT';

      final adj = AdjustRequestModel(itemCode: item.code, quantity: quantity, movement: movement);
      await _stockService.adjustStock(adj);

      if (mounted) {
        setState(() => _stockMap[item.code] = StockModel(itemCode: item.code, itemName: item.name, quantity: newValue, criticalLevel: item.criticalLevel, isCritical: newValue <= item.criticalLevel));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} stoku ${newValue.toStringAsFixed(2)} olarak güncellendi')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok güncellenemedi')));
    }
  }

  @override
  void dispose() {
    for (var c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Open AddItemScreen prefilled for this category
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddItemScreen(initialCategory: widget.category)),
              );
              // reload list after potential add
              await _loadItems();
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        '${widget.category} kategorisine ait\nürün bulunamadı',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final stock = _stockMap[item.code]?.quantity ?? 0;
                final critical = stock <= item.criticalLevel;

                // ensure controller exists
                _qtyControllers.putIfAbsent(item.code, () => TextEditingController(text: '1'));

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Stok: $stock",
                              style: TextStyle(
                                color: critical ? Colors.red : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          _adjust(item, 1, 'OUT');
                        },
                      ),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _qtyControllers[item.code],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          onSubmitted: (value) {
                            final v = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                            if (v > 0) {
                              _adjustWithConfirmation(item, v);
                            }
                          },
                          decoration: const InputDecoration(border: UnderlineInputBorder()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _adjust(item, 1, 'IN');
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
