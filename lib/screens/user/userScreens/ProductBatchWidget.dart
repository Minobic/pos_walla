import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../custom/SidebarHeader.dart'; // Import the reusable components
import '../../../services/ApiService.dart'; // Import the ApiService
import '../../../custom/GradientButton.dart'; // Import the GradientButton
import '../../../custom/RedButton.dart'; // Import the RedButton

class ProductBatchWidget extends StatefulWidget {
  final String userName;
  final String userRole;

  const ProductBatchWidget({
    Key? key,
    required this.userName,
    required this.userRole,
  }) : super(key: key);

  @override
  State<ProductBatchWidget> createState() => _ProductBatchWidgetState();
}

class _ProductBatchWidgetState extends State<ProductBatchWidget> {
  bool _isSidebarOpen = false;
  List<dynamic> _productBatches = [];
  List<dynamic> _filteredProductBatches = [];
  List<dynamic> _products = []; // List to hold products
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String _selectedSortOption = 'Default'; // Track selected sorting option
  bool _isLoading = true; // Loading state
  int? _selectedProductId; // Track selected product ID

  @override
  void initState() {
    super.initState();
    _fetchProductBatches();
    _fetchProducts(); // Fetch products on init
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
      _filteredProductBatches = _productBatches
          .where((batch) => batch['p_batch_name']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
      _currentPage = 1; // Reset to the first page when searching
    });
  }

  Future<void> _fetchProductBatches() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });
    try {
      final productBatches = await ApiService.fetchProductBatches();
      setState(() {
        _productBatches = productBatches;
        _filteredProductBatches = productBatches;
      });
    } catch (e) {
      print('Failed to fetch product batches: $e');
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final products =
          await ApiService.fetchProducts(); // Fetch products from API
      setState(() {
        _products = products; // Store products in the list
      });
    } catch (e) {
      print('Failed to fetch products: $e');
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _showAddProductBatchDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController mfgController = TextEditingController();
    final TextEditingController expController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          title: Container(
            alignment: Alignment.center,
            child: const Text(
              'Add New Product Batch',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: Container(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Batch Name',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mfgController,
                    decoration: InputDecoration(
                      labelText: 'Manufacturing Date (YYYY-MM-DD)',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: expController,
                    decoration: InputDecoration(
                      labelText: 'Expiry Date (YYYY-MM-DD)',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dropdown for product selection
                  DropdownButtonFormField<int>(
                    value: _selectedProductId,
                    decoration: InputDecoration(
                      labelText: 'Select Product',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: _products.map((product) {
                      return DropdownMenuItem<int>(
                        value: product['product_id'],
                        child: Text(product['product_name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProductId =
                            value; // Update selected product ID
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a product' : null,
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
              width: 150,
            ),
            GradientButton(
              text: 'Add',
              onPressed: () async {
                if (_selectedProductId == null) {
                  // Show error if no product is selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a product')),
                  );
                  return;
                }
                try {
                  final newBatch = await ApiService.addProductBatch(
                    name: nameController.text,
                    mfgDate: mfgController.text,
                    expDate: expController.text,
                    productId: _selectedProductId!,
                  );
                  setState(() {
                    _productBatches.add(newBatch);
                    _filteredProductBatches = _productBatches;
                  });
                  _fetchProductBatches();
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Failed to add product batch: $e');
                }
              },
              width: 150,
            ),
          ],
        );
      },
    );
  }

  void _showEditProductBatchDialog(dynamic batch) {
    final TextEditingController nameController =
        TextEditingController(text: batch['p_batch_name']);
    final TextEditingController mfgController =
        TextEditingController(text: batch['p_batch_mfg'].toString());
    final TextEditingController expController =
        TextEditingController(text: batch['p_batch_exp'].toString());

    // Set the selected product ID for the batch being edited
    _selectedProductId = batch['p_id'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          title: Container(
            alignment: Alignment.center,
            child: const Text(
              'Edit Product Batch',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: Container(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Batch Name',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mfgController,
                    decoration: InputDecoration(
                      labelText: 'Manufacturing Date (YYYY-MM-DD)',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: expController,
                    decoration: InputDecoration(
                      labelText: 'Expiry Date (YYYY-MM-DD)',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dropdown for product selection
                  DropdownButtonFormField<int>(
                    value: _selectedProductId,
                    decoration: InputDecoration(
                      labelText: 'Select Product',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: _products.map((product) {
                      return DropdownMenuItem<int>(
                        value: product['product_id'],
                        child: Text(product['product_name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProductId =
                            value; // Update selected product ID
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a product' : null,
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
              width: 150,
            ),
            GradientButton(
              text: 'Update',
              onPressed: () async {
                if (_selectedProductId == null) {
                  // Show error if no product is selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a product')),
                  );
                  return;
                }
                try {
                  final updatedBatch = await ApiService.updateProductBatch(
                    batchId: batch['p_batch_id'],
                    name: nameController.text,
                    mfgDate: mfgController.text,
                    expDate: expController.text,
                    productId: _selectedProductId!,
                  );
                  setState(() {
                    // Update the batch in the list
                    int index = _productBatches.indexWhere(
                        (b) => b['p_batch_id'] == batch['p_batch_id']);
                    if (index != -1) {
                      _productBatches[index] = updatedBatch;
                      _filteredProductBatches = _productBatches;
                    }
                  });
                  _fetchProductBatches();
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Failed to update product batch: $e');
                }
              },
              width: 150,
            ),
          ],
        );
      },
    );
  }

  void _deleteProductBatch(int batchId) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
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
          content:
              const Text('Are you sure you want to delete this product batch?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                textAlign: TextAlign.center,
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(160, 53),
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
        await ApiService.deleteProductBatch(batchId);
        setState(() {
          _productBatches.removeWhere((b) => b['p_batch_id'] == batchId);
          _filteredProductBatches = _productBatches;
        });
      } catch (e) {
        print('Failed to delete product batch: $e');
      }
    }
  }

  List<dynamic> _getPaginatedProductBatches() {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _filteredProductBatches.length) {
      endIndex = _filteredProductBatches.length;
    }
    return _filteredProductBatches.sublist(startIndex, endIndex);
  }

  void _nextPage() {
    setState(() {
      if (_currentPage <
          (_filteredProductBatches.length / _itemsPerPage).ceil()) {
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

  void _sortProductBatches(String sortOption) {
    setState(() {
      _selectedSortOption = sortOption;
      switch (sortOption) {
        case 'Recently Added':
          _filteredProductBatches.sort((a, b) => b['p_batch_created_at']
              .compareTo(a['p_batch_created_at'])); // Most recent first
          break;
        case 'Batch Name (A-Z)':
          _filteredProductBatches.sort((a, b) =>
              a['p_batch_name'].compareTo(b['p_batch_name'])); // A-Z sorting
          break;
        case 'Batch Name (Z-A)':
          _filteredProductBatches.sort((a, b) =>
              b['p_batch_name'].compareTo(a['p_batch_name'])); // Z-A sorting
          break;
        default:
          _filteredProductBatches = List.from(_productBatches); // Default order
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paginatedProductBatches = _getPaginatedProductBatches();

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            isSidebarOpen: _isSidebarOpen,
            toggleSidebar: _toggleSidebar,
            userName: widget.userName,
            userRole: widget.userRole,
            selectedMenuItem: 'ProductsBatch',
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
                              hintText: 'Search Product Batch',
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
                          label: const Text('Add New Product Batch',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              )),
                          onPressed: _showAddProductBatchDialog,
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
                                      'Product Batches Table',
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
                                          0.29,
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
                                        onSelected: _sortProductBatches,
                                        itemBuilder: (BuildContext context) {
                                          return [
                                            'Default',
                                            'Recently Added',
                                            'Batch Name (A-Z)',
                                            'Batch Name (Z-A)',
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
                                                'Batch ID',
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
                                                'Product',
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
                                                'Batch Name',
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
                                                'Manufacturing Date',
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
                                                'Expiry Date',
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
                                            : paginatedProductBatches.isEmpty
                                                ? Center(
                                                    child: Text(
                                                        'No product batches yet.')) // No product batches message
                                                : ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    itemCount:
                                                        paginatedProductBatches
                                                            .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final batch =
                                                          paginatedProductBatches[
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
                                                                batch['p_batch_id']
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
                                                                batch['product_name'] ??
                                                                    'N/A', // Display product name
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
                                                              flex: 2,
                                                              child: Text(
                                                                batch[
                                                                    'p_batch_name'],
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
                                                                batch[
                                                                    'p_batch_mfg'],
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
                                                                batch[
                                                                    'p_batch_exp'],
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
                                                                        _showEditProductBatchDialog(
                                                                            batch),
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .delete,
                                                                        color: Colors
                                                                            .red),
                                                                    onPressed: () =>
                                                                        _deleteProductBatch(
                                                                            batch['p_batch_id']),
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
                                        (_filteredProductBatches.length /
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
                              ' of ${(_filteredProductBatches.length / _itemsPerPage).ceil()}',
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _nextPage,
                          color: _currentPage ==
                                  (_filteredProductBatches.length /
                                          _itemsPerPage)
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
