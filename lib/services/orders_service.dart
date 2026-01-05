import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';

class OrdersService {
  final supabase = SupabaseConfig.client;

  // Fetch all orders for the current user
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('orders')
          .select('''
            *,
            order_items (
              *
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final orders = List<Map<String, dynamic>>.from(response);
      await _attachOrderItemsIfMissing(orders);

      if (kDebugMode) {
        debugPrint('Orders fetched: ${orders.length}');
        for (final o in orders) {
          final items = o['order_items'];
          debugPrint('Order ${o['id']}: items type=${items.runtimeType}, count=${items is List ? items.length : 'n/a'}');
        }
      }

      return orders;
    } catch (e) {
      print('Error fetching user orders: $e');
      rethrow;
    }
  }

  // Get orders by status
  Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('orders')
          .select('''
            *,
            order_items (
              *
            )
          ''')
          .eq('user_id', userId)
          .eq('status', status)
          .order('created_at', ascending: false);

      final orders = List<Map<String, dynamic>>.from(response);
      await _attachOrderItemsIfMissing(orders);

      if (kDebugMode) {
        debugPrint('Orders by status "$status": ${orders.length}');
        for (final o in orders) {
          final items = o['order_items'];
          debugPrint('Order ${o['id']}: items type=${items.runtimeType}, count=${items is List ? items.length : 'n/a'}');
        }
      }

      return orders;
    } catch (e) {
      print('Error fetching orders by status: $e');
      rethrow;
    }
  }

  // Fallback: if nested order_items comes back empty, fetch them explicitly
  Future<void> _attachOrderItemsIfMissing(List<Map<String, dynamic>> orders) async {
    if (orders.isEmpty) return;

    final missingIds = orders
        .where((o) => (o['order_items'] is! List) || (o['order_items'] as List).isEmpty)
        .map((o) => o['id'])
        .where((id) => id != null)
        .toList();

    if (missingIds.isEmpty) return;

    final itemsResponse = await supabase
        .from('order_items')
        .select('*')
        .inFilter('order_id', missingIds);

    final items = List<Map<String, dynamic>>.from(itemsResponse);
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final orderId = item['order_id'];
      if (orderId == null) continue;
      final key = orderId.toString();
      grouped.putIfAbsent(key, () => []).add(item);
    }

    for (final order in orders) {
      final id = order['id'];
      if (id == null) continue;
      final key = id.toString();
      order['order_items'] = grouped[key] ?? (order['order_items'] ?? []);
    }

    if (kDebugMode) {
      debugPrint('Fallback fetched ${items.length} order_items for ${missingIds.length} orders');
      if (items.isNotEmpty) {
        debugPrint('First item sample: ${items.first}');
      }
      for (final entry in grouped.entries) {
        debugPrint('Grouped order_id ${entry.key}: ${entry.value.length} items');
      }
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await supabase
          .from('orders')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // Get order count by status
  Future<Map<String, int>> getOrderStatusCounts() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final orders = await supabase
          .from('orders')
          .select('status')
          .eq('user_id', userId);

      final counts = {
        'to_pay': 0,
        'to_ship': 0,
        'to_receive': 0,
        'to_review': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (var order in orders) {
        final status = order['status'] as String?;
        if (status != null && counts.containsKey(status)) {
          counts[status] = (counts[status] ?? 0) + 1;
        }
      }

      return counts;
    } catch (e) {
      print('Error getting order status counts: $e');
      return {
        'to_pay': 0,
        'to_ship': 0,
        'to_receive': 0,
        'to_review': 0,
        'completed': 0,
        'cancelled': 0,
      };
    }
  }

  // Calculate total spent
  Future<double> getTotalSpent() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      final orders = await supabase
          .from('orders')
          .select('total_amount')
          .eq('user_id', userId)
          .inFilter('status', ['completed', 'to_ship', 'to_receive', 'to_review']);

      double total = 0.0;
      for (var order in orders) {
        total += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
      }

      return total;
    } catch (e) {
      print('Error calculating total spent: $e');
      return 0.0;
    }
  }
}
