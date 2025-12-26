import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'core/dio_service.dart';

void main() async {
  // Token'ı kaydet
  const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzNzAyZWNiZi1iNDFiLTQyMjQtOWJjMi0xYTMyMzI1OGEyOTciLCJqdGkiOiJiNGU4ZDIxNC05MzBhLTQ0ZTQtOTVjNS1iZGQzMGQyNjExMTciLCJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1laWRlbnRpZmllciI6IjM3MDJlY2JmLWI0MWItNDIyNC05YmMyLTFhMzIzMjU4YTI5NyIsImh0dHA6Ly9zY2hlbWFzLnhtbHNvYXAub3JnL3dzLzIwMDUvMDUvaWRlbnRpdHkvY2xhaW1zL25hbWUiOiJBbmEgWcO2bmV0aWNpIiwiRnVsbE5hbWUiOiJBbmEgWcO2bmV0aWNpIiwiaHR0cDovL3NjaGVtYXMubWljcm9zb2Z0LmNvbS93cy8yMDA4LzA2L2lkZW50aXR5L2NsYWltcy9yb2xlIjoiQWRtaW4iLCJleHAiOjE3NjkyMzU2NjEsImlzcyI6Ik1hbnVmYWN0dXJpbmdBcHAiLCJhdWQiOiJNYW51ZmFjdHVyaW5nQXBwIn0.4zdssLkJZUdoHUOfY6hAMiyJs0Cge1_bITnKHvvWquw';
  await DioService.saveToken(token);
  print('✅ Token başlangıçta kaydedildi');
  
  runApp(const StockApp());
}

class StockApp extends StatelessWidget {
  const StockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock Manager',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: HomeScreen(),
    );
  }
}
