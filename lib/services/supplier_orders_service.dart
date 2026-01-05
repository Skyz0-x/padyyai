import '../config/supabase_config.dart';

class SupplierOrdersService {
  final supabase = SupabaseConfig.client;

  // Get all orders for a supplier
  Future<List<Map<String, dynamic>>> getSupplierOrders({String? status}) async {
    try {
      final supplierId = supabase.auth.currentUser?.id;
      if (supplierId == null) {
        throw Exception('User not authenticated');
      }

      print('🔍 DEBUG: Fetching orders for supplier: $supplierId');

      // Strategy 1: Get orders directly from order_items.supplier_id
      final supplierOrderIds = <String>{};
      try {
        final orderItemsResponse = await supabase
            .from('order_items')
            .select('order_id, product_name, supplier_id')
            .eq('supplier_id', supplierId);

        print('🔍 DEBUG: order_items query returned ${orderItemsResponse.length} items');
        if (orderItemsResponse.isNotEmpty) {
          print('🔍 DEBUG: Sample item: ${orderItemsResponse.first}');
        }
        
        for (var item in orderItemsResponse) {
          if (item['order_id'] != null) {
            supplierOrderIds.add(item['order_id'].toString());
          }
        }

        print('🔍 DEBUG: Found ${supplierOrderIds.length} unique orders from order_items.supplier_id');
      } catch (e) {
        print('🔍 DEBUG: Error querying order_items.supplier_id: $e');
      }

      // Strategy 2: Fallback - get from products -> order_items
      if (supplierOrderIds.isEmpty) {
        print('🔍 DEBUG: No supplier_id in order_items, trying products approach...');
        
        // Get all products from this supplier
        final productsResponse = await supabase
            .from('products')
            .select('id')
            .eq('supplier_id', supplierId);

        final supplierProductIds = <String>{};
        for (var product in productsResponse) {
          supplierProductIds.add(product['id'].toString());
        }

        print('🔍 DEBUG: Found ${supplierProductIds.length} products from this supplier');

        if (supplierProductIds.isNotEmpty) {
          // Get all order_items with these products
          final itemsResponse = await supabase
              .from('order_items')
              .select('order_id, product_id, product_name')
              .inFilter('product_id', supplierProductIds.toList());

          print('🔍 DEBUG: Found ${itemsResponse.length} order items with supplier products');
          
          for (var item in itemsResponse) {
            if (item['order_id'] != null) {
              supplierOrderIds.add(item['order_id'].toString());
            }
          }

          print('🔍 DEBUG: Total ${supplierOrderIds.length} unique orders after products fallback');
        }
      }

      if (supplierOrderIds.isEmpty) {
        print('🔍 DEBUG: No orders found for supplier');
        return [];
      }

      final orderIdsList = supplierOrderIds.toList();
      print('🔍 DEBUG: Fetching full order details for ${orderIdsList.length} orders');
      print('🔍 DEBUG: Order IDs to fetch: $orderIdsList');

      // Now fetch the full order details
      dynamic query = supabase
          .from('orders')
          .select('''
            *,
            order_items (
              *
            )
          ''')
          .inFilter('id', orderIdsList);
      
      print('🔍 DEBUG: Status filter: $status');
      if (status != null) {
        query = query.eq('status', status);
      }

      query = query.order('created_at', ascending: false);

      print('🔍 DEBUG: Executing query...');
      final response = await query;
      print('🔍 DEBUG: Found ${response.length} orders');
      if (response.isNotEmpty) {
        print('🔍 DEBUG: First order: ${response[0]['order_number']} - Status: ${response[0]['status']}');
      }
      
      // Fetch farmer details separately for each order
      final ordersWithProfiles = await Future.wait(
        response.map<Future<Map<String, dynamic>>>((order) async {
          try {
            // Try to get from public.users table
            final userResponse = await supabase
                .from('users')
                .select('*')
                .eq('id', order['user_id'])
                .single();
            
            order['profiles'] = {
              'full_name': userResponse['full_name'] ?? 'Unknown',
              'phone_number': userResponse['phone_number']
            };
          } catch (e) {
            print('Error fetching user for order ${order['id']}: $e');
            order['profiles'] = {'full_name': 'Unknown', 'phone_number': null};
          }
          return order as Map<String, dynamic>;
        }).toList(),
      );
      
      return List<Map<String, dynamic>>.from(ordersWithProfiles);
    } catch (e) {
      print('Error fetching supplier orders: $e');
      rethrow;
    }
  }

  // Get pending orders awaiting supplier approval
  Future<List<Map<String, dynamic>>> getPendingApprovalOrders() async {
    return getSupplierOrders(status: 'to_ship');
  }

  // Approve order and mark as ready to ship
  Future<void> approveOrder(String orderId, {String? trackingNumber}) async {
    try {
      print('🔍 APPROVE: Starting approval for order: $orderId');
      print('🔍 APPROVE: Current supplier ID: ${supabase.auth.currentUser?.id}');
      
      final updates = <String, dynamic>{
        'status': 'to_ship',
        'approved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (trackingNumber != null && trackingNumber.isNotEmpty) {
        updates['tracking_number'] = trackingNumber;
        updates['status'] = 'to_receive'; // Move to shipped status if tracking provided
        updates['shipped_at'] = DateTime.now().toIso8601String();
      }

      print('🔍 APPROVE: Updates to apply: $updates');

      final response = await supabase
          .from('orders')
          .update(updates)
          .eq('id', orderId)
          .select();

      print('🔍 APPROVE: Update response: $response');

      // Record status change in history
      await _recordStatusChange(
        orderId,
        trackingNumber != null ? 'to_receive' : 'to_ship',
        'Order approved by supplier${trackingNumber != null ? ' and shipped with tracking: $trackingNumber' : ''}',
      );
      
      print('🔍 APPROVE: Order approved successfully');
    } catch (e) {
      print('❌ APPROVE ERROR: $e');
      rethrow;
    }
  }

  // Mark order as shipped with tracking number
  Future<void> shipOrder(String orderId, String trackingNumber) async {
    try {
      await supabase.rpc('update_order_status_with_history', params: {
        'order_id_param': orderId,
        'new_status_param': 'to_receive',
        'notes_param': 'Shipped with tracking number: $trackingNumber',
      });

      await supabase
          .from('orders')
          .update({
            'tracking_number': trackingNumber,
            'shipped_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      print('Error shipping order: $e');
      rethrow;
    }
  }

  // Get supplier notifications
  Future<List<Map<String, dynamic>>> getSupplierNotifications({bool? unreadOnly}) async {
    try {
      final supplierId = supabase.auth.currentUser?.id;
      if (supplierId == null) {
        throw Exception('User not authenticated');
      }

      dynamic query = supabase
          .from('order_notifications')
          .select('''
            *,
            orders (
              id,
              order_number,
              total_amount,
              status
            )
          ''')
          .eq('supplier_id', supplierId);

      if (unreadOnly == true) {
        query = query.eq('is_read', false);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await supabase
          .from('order_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final supplierId = supabase.auth.currentUser?.id;
      if (supplierId == null) return 0;

      final response = await supabase
          .from('order_notifications')
          .select('id')
          .eq('supplier_id', supplierId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Cancel order (supplier side)
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await supabase.rpc('update_order_status_with_history', params: {
        'order_id_param': orderId,
        'new_status_param': 'cancelled',
        'notes_param': 'Cancelled by supplier: $reason',
      });
    } catch (e) {
      print('Error cancelling order: $e');
      rethrow;
    }
  }

  // Get order status history
  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) async {
    try {
      final response = await supabase
          .from('order_status_history')
          .select('*')
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching order history: $e');
      rethrow;
    }
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final supplierId = supabase.auth.currentUser?.id;
      if (supplierId == null) {
        throw Exception('User not authenticated');
      }

      // Get active orders (to_pay, to_ship, to_receive)
      final activeOrdersResponse = await supabase
          .from('orders')
          .select('id')
          .eq('supplier_id', supplierId)
          .inFilter('status', ['to_pay', 'to_ship', 'to_receive']);
      
      final activeOrdersCount = activeOrdersResponse.length;

      // Get monthly sales (current month)
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final monthlySalesResponse = await supabase
          .from('orders')
          .select('total_amount')
          .eq('supplier_id', supplierId)
          .gte('created_at', firstDayOfMonth.toIso8601String())
          .lte('created_at', lastDayOfMonth.toIso8601String())
          .inFilter('status', ['to_ship', 'to_receive', 'completed']); // Exclude cancelled and unpaid

      double monthlySales = 0;
      for (var order in monthlySalesResponse) {
        monthlySales += (order['total_amount'] as num?)?.toDouble() ?? 0;
      }

      // Get unique customers count (all time)
      final customersResponse = await supabase
          .from('orders')
          .select('user_id')
          .eq('supplier_id', supplierId);
      
      final uniqueCustomers = <String>{};
      for (var order in customersResponse) {
        if (order['user_id'] != null) {
          uniqueCustomers.add(order['user_id'].toString());
        }
      }

      return {
        'activeOrders': activeOrdersCount,
        'monthlySales': monthlySales,
        'customers': uniqueCustomers.length,
      };
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {
        'activeOrders': 0,
        'monthlySales': 0.0,
        'customers': 0,
      };
    }
  }

  // Private helper to record status changes
  Future<void> _recordStatusChange(String orderId, String newStatus, String notes) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      
      await supabase
          .from('order_status_history')
          .insert({
            'order_id': orderId,
            'new_status': newStatus,
            'changed_by': userId,
            'notes': notes,
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error recording status change: $e');
      // Don't throw, this is just for logging
    }
  }
}
