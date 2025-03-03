import 'dart:convert';
import 'package:crypto/crypto.dart'; // Import the crypto package
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL of your Flask backend
  static const String _baseUrl = 'http://127.0.0.1:5000';

  // Register a new user
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert password to bytes
    final digest = sha256.convert(bytes); // Hash the bytes
    return digest.toString(); // Return the hashed password as a string
  }

  // Register a new user
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    // Hash the password before sending it to the backend
    final hashedPassword = _hashPassword(password);

    final url = Uri.parse('$_baseUrl/register');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'password': hashedPassword, // Send the hashed password
        'confirmPassword': hashedPassword, // Send the hashed confirm password
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      // Registration successful
      return jsonDecode(response.body);
    } else {
      // Registration failed
      throw Exception('Failed to register user: ${response.body}');
    }
  }

  // Login a user
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    // Hash the password before sending it to the backend
    final hashedPassword = _hashPassword(password);

    final url = Uri.parse('$_baseUrl/login');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': hashedPassword, // Send the hashed password
      }),
    );

    if (response.statusCode == 200) {
      // Login successful
      return jsonDecode(response.body);
    } else {
      // Login failed
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // Add this function to your ApiService class
  static Future<Map<String, dynamic>> updateCategory({
    required int catId,
    required String name,
    required String description,
  }) async {
    final url = Uri.parse('$_baseUrl/categories/$catId');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'cat_name': name,
        'cat_description': description,
      }),
    );

    if (response.statusCode == 200) {
      // Successfully updated category
      return jsonDecode(response.body);
    } else {
      // Failed to update category
      throw Exception('Failed to update category: ${response.body}');
    }
  }

// Add this function to your ApiService class
  static Future<void> deleteCategory(int catId) async {
    final url = Uri.parse('$_baseUrl/categories/$catId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      // Failed to delete category
      throw Exception('Failed to delete category: ${response.body}');
    }
  }

  // Add this function to your ApiService class
  static Future<List<dynamic>> fetchCategories() async {
    final url = Uri.parse('$_baseUrl/categories');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Successfully fetched categories
      return jsonDecode(response.body);
    } else {
      // Failed to fetch categories
      throw Exception('Failed to fetch categories: ${response.body}');
    }
  }

  // Add this function to your ApiService class
  static Future<Map<String, dynamic>> addCategory({
    required String name,
    required String description,
  }) async {
    final url =
        Uri.parse('$_baseUrl/categories'); // Adjust the endpoint as needed
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'cat_name': name,
        'cat_description': description,
      }),
    );

    if (response.statusCode == 201) {
      // Successfully added category
      return jsonDecode(response.body);
    } else {
      // Failed to add category
      throw Exception('Failed to add category: ${response.body}');
    }
  }

  static Future<List<dynamic>> fetchProducts() async {
    final url = Uri.parse('$_baseUrl/products');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch products: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addProduct({
    required String name,
    required String description,
    required double salePrice,
    required double mrpPrice,
    required int categoryId,
  }) async {
    final url = Uri.parse('$_baseUrl/products');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'product_name': name,
        'product_description': description,
        'sale_price': salePrice,
        'mrp_price': mrpPrice,
        'category_id': categoryId,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add product: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String name,
    required String description,
    required double salePrice,
    required double mrpPrice,
    required int categoryId,
  }) async {
    final url = Uri.parse('$_baseUrl/products/$productId');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'product_name': name,
        'product_description': description,
        'sale_price': salePrice,
        'mrp_price': mrpPrice,
        'category_id': categoryId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update product: ${response.body}');
    }
  }

  static Future<void> deleteProduct(int productId) async {
    final url = Uri.parse('$_baseUrl/products/$productId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }

// Fetch product batches
  static Future<List<dynamic>> fetchProductBatches() async {
    final url =
        Uri.parse('$_baseUrl/product_batches'); // Adjust the endpoint as needed
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch product batches: ${response.body}');
    }
  }

// Add a new product batch
  static Future<Map<String, dynamic>> addProductBatch({
    required String name,
    required String mfgDate,
    required String expDate,
    required int productId,
  }) async {
    final url =
        Uri.parse('$_baseUrl/product_batches'); // Adjust the endpoint as needed
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'p_batch_name': name,
        'p_batch_mfg': mfgDate,
        'p_batch_exp': expDate,
        'p_id': productId,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add product batch: ${response.body}');
    }
  }

// Update a product batch
  static Future<Map<String, dynamic>> updateProductBatch({
    required int batchId,
    required String name,
    required String mfgDate,
    required String expDate,
    required int productId,
  }) async {
    final url = Uri.parse(
        '$_baseUrl/product_batches/$batchId'); // Adjust the endpoint as needed
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'p_batch_name': name,
        'p_batch_mfg': mfgDate,
        'p_batch_exp': expDate,
        'p_id': productId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update product batch: ${response.body}');
    }
  }

// Delete a product batch
  static Future<void> deleteProductBatch(int batchId) async {
    final url = Uri.parse('$_baseUrl/product_batches/$batchId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product batch: ${response.body}');
    }
  }

  // Fetch product batches for a specific product
  static Future<List<dynamic>> fetchProductBatchesForProduct(
      int productId) async {
    final url = Uri.parse(
        '$_baseUrl/product_batches?product_id=$productId'); // Adjust the endpoint as needed
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch product batches: ${response.body}');
    }
  }

  // Fetch all inventories
  static Future<List<dynamic>> fetchInventories() async {
    final url = Uri.parse('$_baseUrl/inventories');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch inventories: ${response.body}');
    }
  }

  // Fetch product batches by product ID
  static Future<List<dynamic>> fetchProductBatchesByProductId(
      int productId) async {
    final url = Uri.parse('$_baseUrl/product_batches?product_id=$productId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch product batches: ${response.body}');
    }
  }

  // Add a new inventory
  static Future<Map<String, dynamic>> addInventory({
    required int productId,
    required int batchId,
    required String stockLevel,
    required int quantity,
  }) async {
    final url = Uri.parse('$_baseUrl/inventories');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'p_id': productId,
        'p_batch_id': batchId,
        'stock_level': stockLevel,
        'p_batch_quantity': quantity,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add inventory: ${response.body}');
    }
  }

  // Update an existing inventory
  static Future<Map<String, dynamic>> updateInventory({
    required int inventoryId,
    required int productId,
    required int batchId,
    required String stockLevel,
    required int quantity,
  }) async {
    final url = Uri.parse('$_baseUrl/inventories/$inventoryId');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'p_id': productId,
        'p_batch_id': batchId,
        'stock_level': stockLevel,
        'p_batch_quantity': quantity,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update inventory: ${response.body}');
    }
  }

  // Delete an inventory
  static Future<void> deleteInventory(int inventoryId) async {
    final url = Uri.parse('$_baseUrl/inventories/$inventoryId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete inventory: ${response.body}');
    }
  }

  static Future<List<dynamic>> fetchBarcodes() async {
    final url = Uri.parse('$_baseUrl/barcodes');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch barcodes: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addBarcode({
    required String productName,
    required String barcodeHeader,
    required String barcodeNumber,
    String? line1,
    String? line2,
  }) async {
    final url = Uri.parse('$_baseUrl/barcodes');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'product_name': productName,
        'barcode_header': barcodeHeader,
        'barcode_number': barcodeNumber,
        'line_1': line1,
        'line_2': line2,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add barcode: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> updateBarcode({
    required int barcodeId,
    required String barcodeNumber,
    String? productName,
    String? barcodeHeader,
    String? line1,
    String? line2,
  }) async {
    final url = Uri.parse('$_baseUrl/barcodes/$barcodeId');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'barcode_number': barcodeNumber,
        'product_name': productName,
        'barcode_header': barcodeHeader,
        'line_1': line1,
        'line_2': line2,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update barcode: ${response.body}');
    }
  }

  static Future<void> deleteBarcode(int barcodeId) async {
    final url = Uri.parse('$_baseUrl/barcodes/$barcodeId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete barcode: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>?> fetchProductByBarcode(
      String barcode) async {
    final url = Uri.parse('$_baseUrl/barcodes/$barcode');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> product = jsonDecode(response.body);
      return product;
    }
    return null;
  }

  // Apply promo code
  static Future<double> applyPromoCode(
      String promoCode, double subtotal) async {
    final url = Uri.parse('$_baseUrl/promocode/$promoCode');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      double discount = data['discount_amount'];
      return discount;
    }
    return 0.0;
  }

  // Create invoice
  static Future<Map<String, dynamic>> createInvoice({
    required int userId,
    required String customerName,
    required String customerMobile,
    required double totalAmount,
    required double subTotal,
    required double discountAmount,
    required double taxAmount,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = Uri.parse('$_baseUrl/invoices');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'user_id': userId,
        'customer_name': customerName,
        'customer_mobile': customerMobile,
        'total_amount': totalAmount,
        'sub_total': subTotal,
        'discount_amount': discountAmount,
        'tax_amount': taxAmount,
        'payment_method': paymentMethod,
        'items': items,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create invoice: ${response.body}');
    }
  }

  // Fetch payment methods
  static Future<List<dynamic>> fetchPaymentMethods() async {
    final url = Uri.parse('$_baseUrl/payment_methods');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch payment methods: ${response.body}');
    }
  }
}
