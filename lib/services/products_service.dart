import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ProductsService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Upload product image to Supabase storage
  Future<String?> uploadProductImage(File imageFile, String productId) async {
    try {
      // Check if file exists
      if (!imageFile.existsSync()) {
        print('❌ Image file does not exist: ${imageFile.path}');
        return null;
      }

      final String fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'products/$fileName';

      print('📤 Uploading image to bucket: product-image');
      print('📤 File path: $filePath');
      print('📤 Local file size: ${imageFile.lengthSync()} bytes');
      
      // Upload the file
      final response = await _client.storage
          .from('product-image')
          .upload(filePath, imageFile, fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ));

      print('📤 Upload response: $response');

      // Get public URL
      final String publicUrl = _client.storage
          .from('product-image')
          .getPublicUrl(filePath);

      print('✅ Image uploaded successfully');
      print('🔗 Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      // Try to get more specific error information
      if (e.toString().contains('not found')) {
        print('❌ Bucket "product-image" not found. Please create it in Supabase Dashboard.');
      } else if (e.toString().contains('permission')) {
        print('❌ Permission denied. Check storage policies.');
      }
      
      return null;
    }
  }

  // Create a new product
  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required String supplierId,
    String? imageUrl,
    List<String>? diseases,
    bool inStock = true,
  }) async {
    try {
      print('📦 Creating product: $name');
      
      final response = await _client.from('products').insert({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'supplier_id': supplierId,
        'image_url': imageUrl,
        'diseases': diseases,
        'in_stock': inStock,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      print('✅ Product created successfully');
      return {
        'success': true,
        'product': response,
        'message': 'Product created successfully',
      };
    } catch (e) {
      print('❌ Error creating product: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get products by supplier (simplified - no join to avoid foreign key issues)
  Future<List<Map<String, dynamic>>> getProductsBySupplier(String supplierId) async {
    try {
      print('🔍 Getting products for supplier: $supplierId');
      
      final response = await _client
          .from('products')
          .select()
          .eq('supplier_id', supplierId)
          .order('created_at', ascending: false);

      print('✅ Retrieved ${response.length} products');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting supplier products: $e');
      return [];
    }
  }

  // Get all products for marketplace (simplified - no join initially)
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      print('🛒 Getting all products for marketplace');
      
      final response = await _client
          .from('products')
          .select()
          .eq('in_stock', true)
          .order('created_at', ascending: false);

      print('✅ Retrieved ${response.length} products for marketplace');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting marketplace products: $e');
      return [];
    }
  }

  // Update product
  Future<Map<String, dynamic>> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    List<String>? diseases,
    bool? inStock,
  }) async {
    try {
      print('📝 Updating product: $productId');
      
      Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (category != null) updateData['category'] = category;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (diseases != null) updateData['diseases'] = diseases;
      if (inStock != null) updateData['in_stock'] = inStock;

      final response = await _client
          .from('products')
          .update(updateData)
          .eq('id', productId)
          .select()
          .single();

      print('✅ Product updated successfully');
      return {
        'success': true,
        'product': response,
        'message': 'Product updated successfully',
      };
    } catch (e) {
      print('❌ Error updating product: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Delete product
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      print('🗑️ Deleting product: $productId');
      
      await _client
          .from('products')
          .delete()
          .eq('id', productId);

      print('✅ Product deleted successfully');
      return {
        'success': true,
        'message': 'Product deleted successfully',
      };
    } catch (e) {
      print('❌ Error deleting product: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Search products
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      print('🔍 Searching products: $query');
      
      final response = await _client
          .from('products')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%')
          .eq('in_stock', true)
          .order('created_at', ascending: false);

      print('✅ Found ${response.length} products matching: $query');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error searching products: $e');
      return [];
    }
  }

  // Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    try {
      print('📂 Getting products by category: $category');
      
      final response = await _client
          .from('products')
          .select()
          .eq('category', category)
          .eq('in_stock', true)
          .order('created_at', ascending: false);

      print('✅ Retrieved ${response.length} products in category: $category');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting products by category: $e');
      return [];
    }
  }

  // Get products for specific disease
  Future<List<Map<String, dynamic>>> getProductsForDisease(String disease) async {
    try {
      print('🦠 Getting products for disease: $disease');
      
      final response = await _client
          .from('products')
          .select()
          .contains('diseases', [disease])
          .eq('in_stock', true)
          .order('created_at', ascending: false);

      print('✅ Retrieved ${response.length} products for disease: $disease');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting products for disease: $e');
      return [];
    }
  }
}