import 'package:flutter/material.dart';
import '../services/item_service.dart';
import '../models/item_model.dart';

class SearchItemScreen extends StatefulWidget {
  @override
  _SearchItemScreenState createState() => _SearchItemScreenState();
}

class _SearchItemScreenState extends State<SearchItemScreen> {
  final _codeController = TextEditingController();
  final ItemService _service = ItemService();

  ItemModel? result;

  Future<void> searchItem() async {
    try {
      final item = await _service.getItem(_codeController.text);
      if (mounted) {
        setState(() => result = item);
      }
    } catch (e) {
      if (mounted) {
        setState(() => result = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ürün bulunamadı.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ürün Ara")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: "Ürün Kodu"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: searchItem,
              child: Text("Ara"),
            ),
            const SizedBox(height: 20),
            if (result != null)
              Card(
                child: ListTile(
                  title: Text(result!.name),
                  subtitle: Text("Tip: ${result!.itemType}"),
                ),
              )
          ],
        ),
      ),
    );
  }
}
