import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../custom/SidebarHeader.dart'; // Import the reusable components
import '../../../services/ApiService.dart'; // Import the ApiService
import '../../../custom/GradientButton.dart'; // Import the GradientButton
import '../../../custom/RedButton.dart'; // Import the RedButton

class ProductWidget extends StatefulWidget {
  final String userName;
  final String userRole;
  final int userId;

  const ProductWidget({
    Key? key,
    required this.userName,
    required this.userRole,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProductWidget> createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> {
  bool _isSidebarOpen = false;
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  List<dynamic> _categories = []; // List to hold categories
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String _selectedSortOption = 'Default'; // Track selected sorting option
  bool _isLoading = true; // Loading state
  int? _selectedCategoryId; // Track selected category ID

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCategories(); // Fetch categories on init
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredProducts = _products
          .where((product) => product['product_name']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
      _currentPage = 1; // Reset to the first page when searching
    });
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });
    try {
      final products = await ApiService.fetchProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
      });
    } catch (e) {
      print('Failed to fetch products: $e');
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories =
          await ApiService.fetchCategories(); // Fetch categories from API
      setState(() {
        _categories = categories; // Store categories in the list
      });
    } catch (e) {
      print('Failed to fetch categories: $e');
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _showAddProductDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController mrpController = TextEditingController();
    final TextEditingController sellPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15), // Match the category dialog
          ),
          backgroundColor: Colors.white,
          title: Container(
            alignment: Alignment.center,
            child: const Text(
              'Add New Product',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: Container(
            width: 400, // Set a fixed width for the dialog
            child: SingleChildScrollView(
              // Make the content scrollable
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12), // Space between fields
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mrpController,
                    decoration: InputDecoration(
                      labelText: 'MRP',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sellPriceController,
                    decoration: InputDecoration(
                      labelText: 'Sell Price',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  // Dropdown for category selection
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Select Category',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category['cat_id'],
                        child: Text(category['cat_name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId =
                            value; // Update selected category ID
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            RedButton(
              text: 'Cancel',
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              width: 150, // Set the desired width
            ),
            GradientButton(
              text: 'Add',
              onPressed: () async {
                if (_selectedCategoryId == null) {
                  // Show error if no category is selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a category')),
                  );
                  return;
                }
                try {
                  final newProduct = await ApiService.addProduct(
                    name: nameController.text,
                    description: descriptionController.text,
                    mrpPrice: double.parse(mrpController.text),
                    salePrice: double.parse(sellPriceController.text),
                    categoryId:
                        _selectedCategoryId!, // Pass the selected category ID
                  );
                  setState(() {
                    _products.add(newProduct);
                    _filteredProducts = _products;
                  });
                  _fetchProducts();
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Failed to add product: $e');
                }
              },
              width: 150,
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(dynamic product) {
    final TextEditingController nameController =
        TextEditingController(text: product['product_name']);
    final TextEditingController descriptionController =
        TextEditingController(text: product['product_description']);
    final TextEditingController mrpController =
        TextEditingController(text: product['mrp_price'].toString());
    final TextEditingController sellPriceController =
        TextEditingController(text: product['sale_price'].toString());

    // Set the selected category ID for the product being edited
    _selectedCategoryId = product['category_id'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15), // Match the add product dialog
          ),
          backgroundColor: Colors.white,
          title: Container(
            alignment: Alignment.center,
            child: const Text(
              'Edit Product',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: Container(
            width: 400, // Set a fixed width for the dialog
            child: SingleChildScrollView(
              // Make the content scrollable
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12), // Space between fields
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mrpController,
                    decoration: InputDecoration(
                      labelText: 'MRP',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sellPriceController,
                    decoration: InputDecoration(
                      labelText: 'Sell Price',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  // Dropdown for category selection
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Select Category',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category['cat_id'],
                        child: Text(category['cat_name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId =
                            value; // Update selected category ID
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            RedButton(
              text: 'Cancel',
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              width: 150, // Set the desired width
            ),
            GradientButton(
              text: 'Update',
              onPressed: () async {
                if (_selectedCategoryId == null) {
                  // Show error if no category is selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a category')),
                  );
                  return;
                }
                try {
                  final updatedProduct = await ApiService.updateProduct(
                    productId: product['product_id'],
                    name: nameController.text,
                    description: descriptionController.text,
                    mrpPrice: double.parse(mrpController.text),
                    salePrice: double.parse(sellPriceController.text),
                    categoryId:
                        _selectedCategoryId!, // Pass the selected category ID
                  );
                  setState(() {
                    // Update the product in the list
                    int index = _products.indexWhere(
                        (prod) => prod['product_id'] == product['product_id']);
                    if (index != -1) {
                      _products[index] = updatedProduct;
                      _filteredProducts = _products;
                    }
                  });
                  _fetchProducts();
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Failed to update product: $e');
                }
              },
              width: 150,
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(int productId) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15), // Match the category dialog
          ),
          backgroundColor: Colors.white,
          title: Container(
            alignment: Alignment.center,
            child: const Text(
              'Confirm Delete',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                textAlign: TextAlign.center,
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(160, 53), // Set the desired width
              ),
            ),
            RedButton(
              text: 'Delete',
              onPressed: () => Navigator.of(context).pop(true),
              width: 150,
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await ApiService.deleteProduct(productId);
        setState(() {
          _products.removeWhere((prod) => prod['product_id'] == productId);
          _filteredProducts = _products;
        });
      } catch (e) {
        print('Failed to delete product: $e');
      }
    }
  }

  List<dynamic> _getPaginatedProducts() {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _filteredProducts.length) {
      endIndex = _filteredProducts.length;
    }
    return _filteredProducts.sublist(startIndex, endIndex);
  }

  void _nextPage() {
    setState(() {
      if (_currentPage < (_filteredProducts.length / _itemsPerPage).ceil()) {
        _currentPage++;
      }
    });
  }

  void _previousPage() {
    setState(() {
      if (_currentPage > 1) {
        _currentPage--;
      }
    });
  }

  void _sortProducts(String sortOption) {
    setState(() {
      _selectedSortOption = sortOption;
      switch (sortOption) {
        case 'Recently Added':
          _filteredProducts.sort((a, b) =>
              b['created_at'].compareTo(a['created_at'])); // Most recent first
          break;
        case 'Product Name (A-Z)':
          _filteredProducts.sort((a, b) =>
              a['product_name'].compareTo(b['product_name'])); // A-Z sorting
          break;
        case 'Product Name (Z-A)':
          _filteredProducts.sort((a, b) =>
              b['product_name'].compareTo(a['product_name'])); // Z-A sorting
          break;
        default:
          _filteredProducts = List.from(_products); // Default order
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paginatedProducts = _getPaginatedProducts();

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            isSidebarOpen: _isSidebarOpen,
            toggleSidebar: _toggleSidebar,
            userName: widget.userName,
            userRole: widget.userRole,
            userId: widget.userId,
            selectedMenuItem: 'Products',
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Header(
                    userName: widget.userName,
                    userRole: widget.userRole,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search Product',
                              hintStyle: TextStyle(fontFamily: 'Poppins'),
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add New Product',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              )),
                          onPressed: _showAddProductDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white,
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  const Center(
                                    child: Text(
                                      'Products Table',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  // Dropdown for sorting
                                  Center(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.29, // Set width to 40% of screen width
                                      child: PopupMenuButton<String>(
                                        icon: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text('Sort by - ',
                                                style: TextStyle(
                                                    fontFamily: 'Poppins')),
                                            Text(
                                              _selectedSortOption,
                                              style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const Icon(Icons.arrow_drop_down),
                                          ],
                                        ),
                                        onSelected: _sortProducts,
                                        itemBuilder: (BuildContext context) {
                                          return [
                                            'Default',
                                            'Recently Added',
                                            'Product Name (A-Z)',
                                            'Product Name (Z-A)',
                                          ].map((String option) {
                                            return PopupMenuItem<String>(
                                              value: option,
                                              child: Text(option),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white,
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Fixed Header with Gradient
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF2196F3),
                                              Color(0xFF1976D2)
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(25),
                                            topRight: Radius.circular(25),
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'P.ID',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Product Name',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Category',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'Description',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'MRP',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Sell Price',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Action',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Scrollable Data
                                      Expanded(
                                        child: _isLoading
                                            ? Center(
                                                child:
                                                    CircularProgressIndicator()) // Loading indicator
                                            : paginatedProducts.isEmpty
                                                ? Center(
                                                    child: Text(
                                                        'No products yet.')) // No products message
                                                : ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    itemCount: paginatedProducts
                                                        .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final product =
                                                          paginatedProducts[
                                                              index];
                                                      return Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 5),
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade300),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              flex: 1,
                                                              child: Text(
                                                                product['product_id']
                                                                    .toString(),
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Text(
                                                                product[
                                                                    'product_name'],
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Text(
                                                                product['category_name'] ??
                                                                    'N/A', // Display category name
                                                                style:
                                                                    const TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 3,
                                                              child: Text(
                                                                product[
                                                                    'product_description'],
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Text(
                                                                product['mrp_price']
                                                                    .toString(),
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Text(
                                                                product['sale_price']
                                                                    .toString(),
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .edit,
                                                                        color: Colors
                                                                            .green),
                                                                    onPressed: () =>
                                                                        _showEditProductDialog(
                                                                            product),
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .delete,
                                                                        color: Colors
                                                                            .red),
                                                                    onPressed: () =>
                                                                        _deleteProduct(
                                                                            product['product_id']),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Pagination Buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _previousPage,
                          color: _currentPage == 1 ? Colors.grey : Colors.blue,
                        ),
                        // Editable page number in a box
                        Row(
                          children: [
                            const Text(
                              'Page ',
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey), // Add a border
                                borderRadius:
                                    BorderRadius.circular(5), // Rounded corners
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: SizedBox(
                                width: 20, // Adjust width as needed
                                child: TextField(
                                  controller:
                                      _pageController, // Controller for the input
                                  keyboardType: TextInputType
                                      .number, // Only allow numbers
                                  textAlign:
                                      TextAlign.center, // Center the text
                                  decoration: InputDecoration(
                                    hintText:
                                        '$_currentPage', // Show current page as hint
                                    border: InputBorder
                                        .none, // Remove the default TextField border
                                    contentPadding:
                                        EdgeInsets.zero, // Remove extra padding
                                    isDense:
                                        true, // Reduce the height of the input field
                                  ),
                                  onSubmitted: (value) {
                                    final int totalPages =
                                        (_filteredProducts.length /
                                                _itemsPerPage)
                                            .ceil();
                                    final int pageNumber =
                                        int.tryParse(value) ?? _currentPage;

                                    if (pageNumber >= 1 &&
                                        pageNumber <= totalPages) {
                                      setState(() {
                                        _currentPage = pageNumber;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Please enter a valid page number between 1 and $totalPages.'),
                                        ),
                                      );
                                    }
                                    _pageController
                                        .clear(); // Clear the input field
                                  },
                                ),
                              ),
                            ),
                            Text(
                              ' of ${(_filteredProducts.length / _itemsPerPage).ceil()}',
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _nextPage,
                          color: _currentPage ==
                                  (_filteredProducts.length / _itemsPerPage)
                                      .ceil()
                              ? Colors.grey
                              : Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
