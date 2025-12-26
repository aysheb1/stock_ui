import 'package:flutter/material.dart';
import '../services/item_service.dart';
import '../services/stock_service.dart';
import '../models/item_model.dart';
import '../models/adjust_request_model.dart';

class AddItemScreen extends StatefulWidget {
  final String? initialCategory;
  const AddItemScreen({super.key, this.initialCategory});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController unitCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController();
  final TextEditingController criticalCtrl = TextEditingController(text: '5');
  final TextEditingController newCategoryCtrl = TextEditingController();
  
  // Ürün tipi seçimi
  String itemType = "Material"; // Material veya Product
  String category = "Sunta"; // Başlangıç kategorisi
  
  // Kategori listesi - ürün tipine göre değişir
  Map<String, List<String>> categoriesByType = {
    "Material": ["Sunta", "Profil", "Paketleme", "Hırdavat", "Diğer"],
    "Product": ["Masa", "Dolap", "Koltuk", "Raf", "Çekmece", "Diğer"], // Daha fazla seçenek
  };
  
  final ItemService _itemService = ItemService();
  final StockService _stockService = StockService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // göstergeyi sadeleştiriyoruz; başlığı kaldırdık
        title: const SizedBox.shrink(),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Yeni Ürün Ekle", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            _buildField("Ürün Adı", nameCtrl),
            const SizedBox(height: 16),
            _buildField("Ürün Kodu", codeCtrl),
            const SizedBox(height: 16),
            _buildField("Birim", unitCtrl),
            const SizedBox(height: 16),
            _buildField("Stok Miktarı", stockCtrl, keyboard: TextInputType.number),
            const SizedBox(height: 16),
            _buildField('Kritik Seviye (sayı)', criticalCtrl, keyboard: TextInputType.number),
            const SizedBox(height: 16),
            // Ürün Tipi Seçimi
            const Text("Ürün Tipi", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: itemType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: "Material", child: Text("Hammadde")),
                    DropdownMenuItem(value: "Product", child: Text("Ürün")),
                  ],
                  onChanged: (v) {
                    setState(() {
                      itemType = v!;
                      category = categoriesByType[itemType]!.first; // İlk kategoriyi seç
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Dinamik Kategori Seçimi
            const Text("Kategori", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  items: categoriesByType[itemType]!
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (v) => setState(() => category = v!),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildField('Yeni Kategori (opsiyonel)', newCategoryCtrl),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _addProduct,
                child: const Text(
                  "Ürünü Ekle",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // If parent passed an initial category, use it
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      category = widget.initialCategory!;
    }
  }

  Widget _buildField(String label, TextEditingController ctrl, {TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboard,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  // critical value is entered numerically now

  void _addProduct() {
    final String name = nameCtrl.text.trim();
    final String code = codeCtrl.text.trim();
    final String unit = unitCtrl.text.trim();
    final int stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
    final int critical = int.tryParse(criticalCtrl.text.trim()) ?? 0;

    if (name.isEmpty || code.isEmpty || unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    // determine final category: use newCategory if provided, otherwise selected
    final finalCategory = (newCategoryCtrl.text.trim().isNotEmpty) ? newCategoryCtrl.text.trim() : category;

    _createItem(name: name, code: code, unit: unit, stock: stock, critical: critical, categoryOverride: finalCategory);
  }

  Future<void> _createItem({required String name, required String code, required String unit, required int stock, required int critical, String? categoryOverride}) async {
    // Prefix haritası - kategori ve ürün tipine göre
    final prefixMap = {
      // Hammadde
      'Sunta': 'S',
      'Profil': 'P',
      'Paketleme': 'PK',
      'Hırdavat': 'H',
      // Ürün
      'Masa': 'M',
      'Dolap': 'D',
      'Koltuk': 'K',
      'Raf': 'RF',
      'Çekmece': 'ÇK',
      'Diğer': 'X',
    };
    
    final usedCategory = categoryOverride ?? category;
    final prefix = prefixMap[usedCategory] ?? 'X';
    final finalCode = code.isNotEmpty ? code : '$prefix${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    // ItemType'ı seçilen ürün tipine göre belirle
    // Material = 1, Product = 2
    int itemTypeValue = itemType == "Product" ? 2 : 1;

    final item = ItemModel(
      code: finalCode,
      name: name,
      unit: unit,
      criticalLevel: critical.toDouble(),
      itemType: itemTypeValue,
      categories: usedCategory,
    );

    try {
      await _itemService.createItem(item);

      // Eğer başlangıç stoğu verilmişse, backend'e stoğu arttırmak için bir hareket gönder
      if (stock > 0) {
        final adj = AdjustRequestModel(itemCode: finalCode, quantity: stock.toDouble(), movement: 'IN');
        await _stockService.adjustStock(adj);
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ürün başarıyla eklendi.")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ürün eklenirken hata oluştu.")));
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    codeCtrl.dispose();
    unitCtrl.dispose();
    stockCtrl.dispose();
    criticalCtrl.dispose();
    newCategoryCtrl.dispose();
    super.dispose();
  }
}
