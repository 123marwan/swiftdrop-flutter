import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  List<dynamic> _pendingOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingOrders();
  }

  Future<void> _fetchPendingOrders() async {
    try {
      final response = await DioClient.dio.get(ApiEndpoints.ordersPending);
      if (response.statusCode == 200) {
        setState(() {
          _pendingOrders = response.data;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل جلب الطلبات المتاحة: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _acceptOrder(dynamic orderId) async {
    try {
      final response = await DioClient.dio.put(
        ApiEndpoints.ordersUpdateStatus(orderId),
        queryParameters: {'status': 'ACCEPTED'},
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم قبول الطلب بنجاح! توجه للاستلام 🛵'), backgroundColor: Colors.green),
        );
        _fetchPendingOrders(); // تحديث القائمة
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في قبول الطلب: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم السائقين 🛵'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _pendingOrders.isEmpty
          ? const Center(child: Text('لا توجد طلبات متاحة حالياً للتوصيل', style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
        itemCount: _pendingOrders.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final order = _pendingOrders[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 15),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('طلب توصيل رقم #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('التفاصيل: ${order['orderDetails']}'),
                  const SizedBox(height: 8),
                  Text('السعر الإجمالي: ${order['totalPrice']} EGP', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(order['id']),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('قبول الطلب والتوجه للتوصيل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}