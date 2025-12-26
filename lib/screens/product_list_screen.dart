import 'package:flutter/material.dart';
import '../services/item_service.dart';
import '../services/stock_service.dart';
import '../models/item_model.dart';
import '../models/stock_model.dart';
import '../models/adjust_request_model.dart';
import 'add_item_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ItemService _itemService = ItemService();
  final StockService _stockService = StockService();
  bool loading = true;
  List<ItemModel> allProducts = [];
  List<String> productCategories = []; // Dinamik kategori listesi
  Map<String, List<ItemModel>> productsByCategory = {};
  Map<String, StockModel> stockMap = {};
  Map<String, TextEditingController> _qtyControllers = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    for (var c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => loading = true);
    try {
      final fetched = await _itemService.getItems('Product');
      allProducts = fetched;
      
      // Backend'ten gelen categories'den unique olanları al
      final uniqueCategories = <String>{};
      for (var item in fetched) {
        if (item.categories != null && item.categories!.isNotEmpty) {
          uniqueCategories.add(item.categories!);
        }
      }
      
      // Kategorileri sırala ve listeye çevir
      productCategories = uniqueCategories.toList()..sort();
      
      // Eğer kategoriye sahip ürün yoksa varsayılan "Diğer" ekle
      if (productCategories.isEmpty) {
        productCategories = ["Diğer"];
      }
      
      // Kategoriye göre grupla
      productsByCategory = {};
      for (var category in productCategories) {
        productsByCategory[category] = fetched
            .where((item) => item.categories != null && 
                    item.categories!.toLowerCase() == category.toLowerCase())
            .toList();
      }

      final stocks = await Future.wait(allProducts.map((i) async {
        try {
          return await _stockService.getStockByCode(i.code);
        } catch (_) {
          return StockModel(itemCode: i.code, itemName: i.name, quantity: 0, criticalLevel: i.criticalLevel, isCritical: false);
        }
      }));

      stockMap = {for (var s in stocks) s.itemCode: s};
      // prepare quantity controllers
      _qtyControllers = {for (var it in allProducts) it.code: TextEditingController(text: '1')};
    } catch (e) {
      print('❌ Ürün yükleme hatası: $e');
      allProducts = [];
      productsByCategory = {};
      stockMap = {};
    }
    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (productCategories.isEmpty) {
      return const Center(child: Text('Ürün bulunamadı'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: productCategories.length,
      itemBuilder: (context, index) {
        final categoryName = productCategories[index];
        return _categoryCard(title: categoryName);
      },
    );
  }

  /// CATEGORY CARD - Hammadde ile aynı tasarım
  Widget _categoryCard({required String title}) {
    // Kategori adına göre icon seç
    IconData getIcon(String category) {
      switch (category.toLowerCase()) {
        case 'masa':
          return Icons.table_restaurant;
        case 'dolap':
          return Icons.storage;
        case 'koltuk':
          return Icons.event_seat;
        case 'raf':
          return Icons.shelves;
        case 'çekmece':
          return Icons.inbox;
        default:
          return Icons.more_horiz;
      }
    }

    return InkWell(
      onTap: () {
        // Kategori detay sayfasına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductCategoryDetailScreen(category: title),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 78, 0, 9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(getIcon(title), color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('Tıkla görmek için →', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PRODUCT CATEGORY DETAIL SCREEN
class ProductCategoryDetailScreen extends StatefulWidget {
  final String category;

  const ProductCategoryDetailScreen({super.key, required this.category});

  @override
  State<ProductCategoryDetailScreen> createState() => _ProductCategoryDetailScreenState();
}

class _ProductCategoryDetailScreenState extends State<ProductCategoryDetailScreen> {
  late List<ItemModel> items = [];
  final ItemService _itemService = ItemService();
  final StockService _stockService = StockService();
  bool loading = true;
  Map<String, StockModel> _stockMap = {};
  Map<String, TextEditingController> _qtyControllers = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => loading = true);
    try {
      final fetched = await _itemService.getItems("Product");

      // Kategoriyi kontrol et - sadece ilgili kategoriye ait item'ları göster
      final filteredItems = fetched.where((item) {
        return item.categories != null && 
               item.categories!.toLowerCase() == widget.category.toLowerCase();
      }).toList();

      final stocks = await Future.wait(filteredItems.map((i) async {
        try {
          final s = await _stockService.getStockByCode(i.code);
          return s;
        } catch (_) {
          return StockModel(itemCode: i.code, itemName: i.name, quantity: 0, criticalLevel: i.criticalLevel, isCritical: false);
        }
      }));

      items = filteredItems;
      _stockMap = {for (var s in stocks) s.itemCode: s};
    } catch (e) {
      print('❌ Ürün yükleme hatası: $e');
      items = [];
    }
    if (mounted) {
      setState(() => loading = false);
    }
  }

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
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddItemScreen(initialCategory: widget.category)),
              );
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
                                Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                Text('Stok: $stock', style: TextStyle(color: critical ? Colors.red : Colors.grey)),
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
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteConfirmation(item);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _showDeleteConfirmation(ItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text('${item.name} ürünü silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _itemService.deleteItem(item.code);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.name} silindi')),
                  );
                  await _loadItems();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Silme işlemi başarısız oldu')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
