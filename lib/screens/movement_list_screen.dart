import 'package:flutter/material.dart';
import '../services/movement_service.dart';
import '../models/stock_movement_model.dart';

class MovementListScreen extends StatefulWidget {
  @override
  _MovementListScreenState createState() => _MovementListScreenState();
}

class _MovementListScreenState extends State<MovementListScreen> {
  final MovementService _service = MovementService();
  List<StockMovementModel> movements = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final res = await _service.getMovements();
    if (mounted) {
      setState(() => movements = res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hareket Listesi")),
      body: ListView.builder(
        itemCount: movements.length,
        itemBuilder: (context, i) {
          final m = movements[i];
          return ListTile(
            title: Text("${m.itemCode} - ${m.movement} (${m.quantity})"),
            subtitle: Text("${m.createdAt}"),
          );
        },
      ),
    );
  }
}
