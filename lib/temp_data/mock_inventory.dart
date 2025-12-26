class MockInventory {
  // Boş mock veriler - gerçek veriler Backend'den geliyor
  static final List<Map<String, dynamic>> materials = [];
  static final List<Map<String, dynamic>> products = [];

  // Add a new material category
  static void addMaterialCategory(String name) {
    // avoid duplicates
    final exists = materials.any((m) => m['category'] == name);
    if (!exists) {
      materials.add({"category": name, "items": []});
    }
  }

  // Add item to a material category (creates category if missing)
  static void addMaterialItem(String category, Map<String, dynamic> item) {
    addMaterialCategory(category);
    final idx = materials.indexWhere((m) => m['category'] == category);
    if (idx >= 0) {
      materials[idx]['items'].add(item);
    }
  }

  // Ürün ekleme fonksiyonu
  static void addProduct(Map<String, dynamic> newProduct) {
    products.add(newProduct);
  }

  // Stok artırma
  static void increaseStock(Map<String, dynamic> item) {
    item["stock"] += 1;
  }

  // Stok azaltma
  static void decreaseStock(Map<String, dynamic> item) {
    if (item["stock"] > 0) {
      item["stock"] -= 1;
    }
  }

  // Helper: get items by category name
  static List<Map<String, dynamic>> itemsForCategory(String category) {
    final c = materials.firstWhere((m) => m["category"] == category, orElse: () => {"items": []});
    return List<Map<String, dynamic>>.from(c["items"] ?? []);
  }

  // Helper: find product by code
  static Map<String, dynamic>? productByCode(String code) {
    try {
      return products.firstWhere((p) => p["code"] == code);
    } catch (_) {
      return null;
    }
  }
}
