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
      print('🔍 DEBUG: Supplier ID type: ${supplierId.runtimeType}');

      dynamic query = supabase
          .from('orders')
          .select('''
            *,
            order_items (
              *
            )
          ''')
          .eq('supplier_id', supplierId);
      
      print('🔍 DEBUG: Query built, adding status filter: $status');

      if (status != null) {
        query = query.eq('status', status);
      }

      query = query.order('created_at', ascending: false);

      print('🔍 DEBUG: Executing query...');
      final response = await query;
      print('🔍 DEBUG: Query response type: ${response.runtimeType}');
      print('🔍 DEBUG: Found ${response.length} orders');
      if (response.isNotEmpty) {
        print('🔍 DEBUG: First order: ${response[0]}');
      }
      
      // Fetch farmer details separately for each order
      final ordersWithProfiles = await Future.wait(
        response.map<Future<Map<String, dynamic>>>((order) async {
          try {
            final profileResponse = await supabase
                .from('profiles')
                .select('full_name, phone_number')
                .eq('id', order['user_id'])
                .single();
            
            order['profiles'] = profileResponse;
          } catch (e) {
            print('Error fetching profile for order ${order['id']}: $e');
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

      await supabase
          .from('orders')
          .update(updates)
          .eq('id', orderId);

      // Record status change in history
      await _recordStatusChange(
        orderId,
        trackingNumber != null ? 'to_receive' : 'to_ship',
        'Order approved by supplier${trackingNumber != null ? ' and shipped with tracking: $trackingNumber' : ''}',
      );
    } catch (e) {
      print('Error approving order: $e');
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
