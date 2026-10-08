import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await DioClient.dio.get(ApiEndpoints.ordersAll);
      if (response.statusCode == 200) {
        setState(() {
          _orders = response.data;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل الطلبات: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي الحالية'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(child: Text('لا توجد طلبات حالية', style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
        itemCount: _orders.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final order = _orders[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 15),
            child: ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.deepOrange, size: 30),
              title: Text('طلب رقم #${order['id'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text('التفاصيل: ${order['orderDetails'] ?? ''}'),
                  const SizedBox(height: 5),
                  Text('الحالة: ${order['status'] ?? 'PENDING'}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: Text('${order['totalPrice'] ?? 0.0} EGP', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}