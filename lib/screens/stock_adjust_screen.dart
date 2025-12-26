import 'package:flutter/material.dart';
import '../models/adjust_request_model.dart';
import '../services/stock_service.dart';

class StockAdjustScreen extends StatefulWidget {
  final String itemCode;

  StockAdjustScreen({required this.itemCode});

  @override
  _StockAdjustScreenState createState() => _StockAdjustScreenState();
}

class _StockAdjustScreenState extends State<StockAdjustScreen> {
  final _qtyController = TextEditingController();
  String _movement = "In";
  final StockService _service = StockService();

  Future<void> adjust() async {
    final model = AdjustRequestModel(
      itemCode: widget.itemCode,
      quantity: double.parse(_qtyController.text),
      movement: _movement,
      note: "",
    );

    try {
      await _service.adjustStock(model);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Stok güncellendi")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Stok Düzenle - ${widget.itemCode}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _qtyController,
              decoration: InputDecoration(labelText: "Miktar"),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField(
              value: _movement,
              onChanged: (v) => setState(() => _movement = v!),
              items: const [
                DropdownMenuItem(value: "In", child: Text("Giriş")),
                DropdownMenuItem(value: "Out", child: Text("Çıkış")),
                DropdownMenuItem(value: "Adjust", child: Text("Düzeltme")),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: adjust,
              child: Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}
