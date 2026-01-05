import 'package:supabase_flutter/supabase_flutter.dart';

class CartService {
  final SupabaseClient _client = Supabase.instance.client;

  // Add item to cart or update quantity if already exists
  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required String productName,
    required double productPrice,
    String? productImage,
    String? productCategory,
    int quantity = 1,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if item already exists in cart
      final existingItem = await _client
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingItem != null) {
        // Update quantity if item exists
        final newQuantity = (existingItem['quantity'] as int) + quantity;
        final updated = await _client
            .from('cart_items')
            .update({
              'quantity': newQuantity,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingItem['id'])
            .select()
            .single();
        
        return {
          'success': true,
          'message': 'Cart updated',
          'data': updated,
          'isNew': false,
        };
      } else {
        // Insert new item
        final inserted = await _client.from('cart_items').insert({
          'user_id': userId,
          'product_id': productId,
          'product_name': productName,
          'product_price': productPrice,
          'product_image': productImage,
          'product_category': productCategory,
          'quantity': quantity,
        }).select().single();

        return {
          'success': true,
          'message': 'Added to cart',
          'data': inserted,
          'isNew': true,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add to cart: $e',
      };
    }
  }

  // Get all cart items for current user
  Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final items = await _client
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      print('Error fetching cart items: $e');
      return [];
    }
  }

  // Update cart item quantity
  Future<bool> updateQuantity(String cartItemId, int quantity) async {
    try {
      if (quantity <= 0) {
        return await removeFromCart(cartItemId);
      }

      await _client
          .from('cart_items')
          .update({
            'quantity': quantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cartItemId);

      return true;
    } catch (e) {
      print('Error updating quantity: $e');
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeFromCart(String cartItemId) async {
    try {
      await _client.from('cart_items').delete().eq('id', cartItemId);
      return true;
    } catch (e) {
      print('Error removing from cart: $e');
      return false;
    }
  }

  // Clear all cart items for current user
  Future<bool> clearCart() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('cart_items').delete().eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error clearing cart: $e');
      return false;
    }
  }

  // Get cart summary (total items, total price)
  Future<Map<String, dynamic>> getCartSummary() async {
    try {
      final items = await getCartItems();
      
      int totalItems = 0;
      double totalPrice = 0.0;

      for (var item in items) {
        final quantity = item['quantity'] as int;
        final price = (item['product_price'] as num).toDouble();
        
        totalItems += quantity;
        totalPrice += price * quantity;
      }

      return {
        'totalItems': totalItems,
        'totalPrice': totalPrice,
        'itemCount': items.length,
      };
    } catch (e) {
      return {
        'totalItems': 0,
        'totalPrice': 0.0,
        'itemCount': 0,
      };
    }
  }

  // Get cart item count (for badge)
  Future<int> getCartItemCount() async {
    try {
      final items = await getCartItems();
      return items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
    } catch (e) {
      return 0;
    }
  }

  // Create order from cart
  Future<Map<String, dynamic>> createOrder({
    required String shippingName,
    required String shippingPhone,
    required String shippingAddress,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get cart items
      final cartItems = await getCartItems();
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Calculate totals
      double subtotal = 0.0;
      for (var item in cartItems) {
        final quantity = item['quantity'] as int;
        final price = (item['product_price'] as num).toDouble();
        subtotal += price * quantity;
      }

      final tax = subtotal * 0.0; // 0% tax, adjust as needed
      final shippingFee = subtotal > 1000 ? 0.0 : 6.0; // Free shipping over RM 1000, RM 6 otherwise
      final totalAmount = subtotal + tax + shippingFee;

      // Generate order number
      final orderNumberResult = await _client.rpc('generate_order_number');
      final orderNumber = orderNumberResult as String;

      // Get supplier_id from first product (assuming single supplier per order)
      String? orderSupplierId;
      if (cartItems.isNotEmpty) {
        try {
          final firstProductResponse = await _client
              .from('products')
              .select('supplier_id')
              .eq('id', cartItems.first['product_id'])
              .single();
          orderSupplierId = firstProductResponse['supplier_id'] as String?;
        } catch (e) {
          print('Warning: Could not fetch supplier_id for order: $e');
        }
      }

      // Create order
      final order = await _client.from('orders').insert({
        'user_id': userId,
        'order_number': orderNumber,
        'total_amount': totalAmount,
        'subtotal': subtotal,
        'tax': tax,
        'shipping_fee': shippingFee,
        'status': paymentMethod == 'cash_on_delivery' ? 'to_pay' : 'to_ship', // Set initial status based on payment
        'payment_method': paymentMethod,
        'payment_status': paymentMethod == 'cash_on_delivery' ? 'pending' : 'completed', // COD is pending, others are completed
        'shipping_name': shippingName,
        'shipping_phone': shippingPhone,
        'shipping_address': shippingAddress,
        'notes': notes,
        'supplier_id': orderSupplierId, // Set supplier_id in orders table
      }).select().single();

      // Create order items
      for (var item in cartItems) {
        final quantity = item['quantity'] as int;
        final price = (item['product_price'] as num).toDouble();
        final itemSubtotal = price * quantity;

        // Get product to get supplier_id
        final productResponse = await _client
            .from('products')
            .select('supplier_id')
            .eq('id', item['product_id'])
            .single();
        
        final supplierId = productResponse['supplier_id'] as String?;

        await _client.from('order_items').insert({
          'order_id': order['id'],
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'product_price': price,
          'product_image': item['product_image'],
          'product_category': item['product_category'],
          'quantity': quantity,
          'subtotal': itemSubtotal,
          'supplier_id': supplierId,
        });
      }

      // Clear cart after successful order
      await clearCart();

      return {
        'success': true,
        'message': 'Order created successfully',
        'order': order,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create order: $e',
      };
    }
  }

  // Get user's orders
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final orders = await _client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(orders);
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  // Get order items for a specific order
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final items = await _client
          .from('order_items')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      print('Error fetching order items: $e');
      return [];
    }
  }
}
