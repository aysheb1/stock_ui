import 'package:flutter/material.dart';
import 'category_detail_screen.dart';
import 'product_list_screen.dart';
import 'add_item_screen.dart';
import 'all_items_list_screen.dart';
import 'critical_items_screen.dart';
import '../core/dio_service.dart';
import '../services/item_service.dart';
import '../services/stock_service.dart';
import '../models/item_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedType = "Material";
  
  final ItemService _itemService = ItemService();
  final StockService _stockService = StockService();
  
  List<ItemModel> allItems = [];
  Map<String, int> stockMap = {};

  // Material kategorileri - Backend'den verileri çekecek
  final List<String> materialCategories = [
    "Sunta",
    "Profil",
    "Paketleme",
    "Hırdavat",
    "Diğer"
  ];

  @override
  void initState() {
    super.initState();
    _loadCriticalItems();
  }
  
  Future<void> _loadCriticalItems() async {
    try {
      // Load all items (both Material and Product)
      final materials = await _itemService.getItems("Material");
      final products = await _itemService.getItems("Product");
      final allItemsList = [...materials, ...products];
      
      // Load stock for each item
      final stocks = <String, int>{};
      for (var item in allItemsList) {
        try {
          final stockModel = await _stockService.getStockByCode(item.code);
          stocks[item.code] = stockModel.quantity.toInt();
        } catch (e) {
          stocks[item.code] = 0;
        }
      }
      
      if (mounted) {
        setState(() {
          allItems = allItemsList;
          stockMap = stocks;
        });
      }
    } catch (e) {
      print('Error loading items: $e');
    }
  }
  
  List<ItemModel> get criticalItems {
    return allItems.where((item) {
      final stock = stockMap[item.code] ?? 0;
      final critical = item.criticalLevel.toInt();
      return stock <= critical && critical > 0;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      
      // Genel Ekle Butonu
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // AddItemScreen'e git (kategori seçimi yok, kullanıcı seçsin)
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
        },
        tooltip: 'Yeni Ürün Ekle',
        backgroundColor: const Color.fromARGB(255, 11, 26, 94),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // (Settings UI removed) — backend URL is managed internally; users don't need to see or edit it.

                /// TABBAR
                DefaultTabController(
                  length: 2,
                  initialIndex: selectedType == "Material" ? 0 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          // daha ince görünmesi için dikey padding azaltıldı
                          labelPadding: const EdgeInsets.symmetric(vertical: 6),
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey.shade600,
                          tabs: const [
                            Tab(child: Text('Hammaddeler', style: TextStyle(fontSize: 13))),
                            Tab(child: Text('Ürünler', style: TextStyle(fontSize: 13))),
                          ],
                          onTap: (idx) => setState(() => selectedType = idx == 0 ? 'Material' : 'Product'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

                /// LIST
                Expanded(
                  child: selectedType == "Material"
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: materialCategories.length,
                          itemBuilder: (context, index) {
                            final categoryName = materialCategories[index];
                            return _categoryCard(title: categoryName);
                          },
                        )
                      : const ProductListScreen(),
                ),
              ],
            ),
            
            // Kritik Ürünler Floating Button - Sol Altta (FAB gibi)
            if (criticalItems.isNotEmpty)
              Positioned(
                left: 16,
                bottom: 16,
                right: null,
                child: GestureDetector(
                  onTap: () {
                    // Yeni sayfaya git
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CriticalItemsScreen(
                          criticalItems: criticalItems,
                          stockMap: stockMap,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 11, 26, 94),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 11, 26, 94).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 28,
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '${criticalItems.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Tüm Ürünleri Listele Butonu - Aşağıda Ortada (Alert ile FAB arasında)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllItemsListScreen()),
                    );
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('Tüm Ürünleri Listele'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 11, 26, 94),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SEGMENT BUTTON
  // kept for reference; TabBar is used now
  // segment helper removed; TabBar handles switching now.

  /// CATEGORY CARD (TIKLANABİLİR)
  Widget _categoryCard({required String title}) {
    // Kategori adına göre icon seç
    IconData getIcon(String category) {
      switch (category.toLowerCase()) {
        case 'sunta':
          return Icons.dashboard;
        case 'profil':
          return Icons.view_column;
        case 'paketleme':
          return Icons.inventory_2;
        case 'hırdavat':
          return Icons.construction;
        default:
          return Icons.more_horiz;
      }
    }

    return InkWell(
      onTap: () {
        // open detail and refresh when returning (in case new items/categories were added)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(category: title),
          ),
        ).then((_) => setState(() {}));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 11, 26, 94),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(getIcon(title), color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Kategorinin detayını görmek için tıkla
                  Text(
                    'Tıkla görmek için →',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // no inline add on category card; add is only available on detail screen
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
