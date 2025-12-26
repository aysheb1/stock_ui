import 'package:flutter/material.dart';
import '../services/stock_service.dart';
import '../models/stock_model.dart';
import 'stock_adjust_screen.dart';

class StockListScreen extends StatefulWidget {
  @override
  _StockListScreenState createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  final StockService _service = StockService();
  List<StockModel> stockList = [];

  @override
  void initState() {
    super.initState();
    loadStocks();
  }

  Future<void> loadStocks() async {
    final res = await _service.getStocks();
    if (mounted) {
      setState(() => stockList = res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Stok Listesi")),
      body: ListView.builder(
        itemCount: stockList.length,
        itemBuilder: (context, i) {
          final s = stockList[i];
          return ListTile(
            title: Text("${s.itemName} - ${s.quantity}"),
            subtitle: Text("Kod: ${s.itemCode}"),
            trailing: Icon(
              Icons.warning,
              color: s.isCritical ? Colors.red : Colors.transparent,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StockAdjustScreen(itemCode: s.itemCode)),
            ),
          );
        },
      ),
    );
  }
}
