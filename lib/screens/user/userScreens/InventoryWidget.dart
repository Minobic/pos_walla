import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../custom/SidebarHeader.dart'; // Import the reusable components
import '../../../services/ApiService.dart'; // Import the ApiService
import '../../../custom/GradientButton.dart'; // Import the GradientButton
import '../../../custom/RedButton.dart'; // Import the RedButton
import '../../../custom/CustomDropdown.dart'; // Import the CustomDropdown

class InventoryWidget extends StatefulWidget {
  final String userName;
  final String userRole;
  final int userId;

  const InventoryWidget({
    Key? key,
    required this.userName,
    required this.userRole,
    required this.userId,
  }) : super(key: key);

  @override
  State<InventoryWidget> createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget> {
  bool _isSidebarOpen = false;
  List<dynamic> _inventories = [];
  List<dynamic> _products = [];
  List<dynamic> _allBatches = []; // Store all batches
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String _selectedSortOption = 'Default'; // Track selected sorting option
  bool _isLoading = true; // Loading state
  int? _selectedProductId; // Track selected product ID
  int? _selectedBatchId; // Track selected batch ID
  String? _selectedStockLevel; // Track selected stock level

  @override
  void initState() {
    super.initState();
    _fetchInventories();
    _fetchProducts(); // Fetch products on init
    _fetchAllBatches(); // Fetch all batches on init
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
      // Filter inventories based on search input
      // Implement filtering logic if needed
    });
  }

  Future<void> _fetchInventories() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });
    try {
      final inventories = await ApiService.fetchInventories();
      setState(() {
        _inventories = inventories;
      });
    } catch (e) {
      print('Failed to fetch inventories: $e');
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await ApiService.fetchProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      print('Failed to fetch products: $e');
    }
  }

  Future<void> _fetchAllBatches() async {
    try {
      final batches = await ApiService.fetchProductBatches();
      setState(() {
        _allBatches = batches;
      });
    } catch (e) {
      print('Failed to fetch batches: $e');
    }
  }

  // Modify the _getBatchesForProduct method to exclude used batches
  List<dynamic> _getBatchesForProduct(int productId) {
    // Get all batches for the product
    List<dynamic> allBatches =
        _allBatches.where((batch) => batch['p_id'] == productId).toList();

    // Get the batch IDs that are already in use by any inventory
    Set usedBatchIds =
        _inventories.map((inventory) => inventory['p_batch_id']).toSet();

    // Filter out the used batches
    return allBatches
        .where((batch) => !usedBatchIds.contains(batch['p_batch_id']))
        .toList();
  }

  String? _getBatchExpiry(int batchId) {
    final batch = _allBatches.firstWhere(
        (batch) => batch['p_batch_id'] == batchId,
        orElse: () => null);
    return batch != null ? batch['p_batch_exp'] : null;
  }

  // Function to determine the color based on stock level
  Color _getStockLevelColor(String? stockLevel) {
    switch (stockLevel) {
      case 'low':
        return Colors.red; // Red for low stock
      case 'medium':
        return Colors.yellow; // Yellow for medium stock
      case 'high':
        return Colors.green; // Green for high stock
      default:
        return Colors.grey; // Default color for unknown stock levels
    }
  }

  void _showAddInventoryDialog() async {
    // Fetch products and batches before showing the dialog
    final products = await ApiService.fetchProducts();
    final batches = await ApiService.fetchProductBatches();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Initialize state variables within the dialog
        int? selectedProductId;
        int? selectedBatchId;
        String? selectedStockLevel;
        final TextEditingController quantityController =
            TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: Colors.white,
              title: Container(
                alignment: Alignment.center,
                child: const Text(
                  'Add New Inventory',
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
                      // Custom Dropdown for product selection
                      CustomDropdown<int>(
                        items: products
                            .map((product) => product['product_id'] as int)
                            .toList(),
                        selectedItem: selectedProductId,
                        onChanged: (value) {
                          setState(() {
                            selectedProductId = value;
                            selectedBatchId = null; // Reset batch selection
                            selectedStockLevel =
                                null; // Reset stock level selection
                          });
                        },
                        itemAsString: (item) => products.firstWhere((product) =>
                            product['product_id'] == item)['product_name'],
                        label: 'Select Product',
                      ),
                      const SizedBox(height: 12),
                      // Conditionally render batch selection dropdown
                      if (selectedProductId != null)
                        CustomDropdown<int>(
                          items: _getBatchesForProduct(selectedProductId!)
                              .map((batch) => batch['p_batch_id'] as int)
                              .toList(),
                          selectedItem: selectedBatchId,
                          onChanged: (value) {
                            setState(() {
                              selectedBatchId = value;
                            });
                          },
                          itemAsString: (item) => _allBatches.firstWhere(
                              (batch) =>
                                  batch['p_batch_id'] == item)['p_batch_name'],
                          label: 'Select Batch',
                        ),
                      const SizedBox(height: 12),
                      // Conditionally render remaining fields after batch selection
                      if (selectedBatchId != null) ...[
                        // Read-only field for batch expiry date
                        TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Batch Expiry Date',
                            labelStyle: TextStyle(fontFamily: 'Poppins'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          controller: TextEditingController(
                            text: _getBatchExpiry(selectedBatchId!) ?? '',
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Dropdown for stock level selection
                        DropdownButtonFormField<String>(
                          value: selectedStockLevel,
                          decoration: InputDecoration(
                            labelText: 'Select Stock Level',
                            labelStyle: TextStyle(fontFamily: 'Poppins'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: ['high', 'medium', 'low'].map((level) {
                            return DropdownMenuItem<String>(
                              value: level,
                              child: Text(level),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStockLevel = value;
                            });
                          },
                          validator: (value) => value == null
                              ? 'Please select a stock level'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        // Quantity input field
                        TextField(
                          controller: quantityController,
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            labelStyle: TextStyle(fontFamily: 'Poppins'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
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
                    if (selectedProductId == null ||
                        selectedBatchId == null ||
                        selectedStockLevel == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }
                    try {
                      final newInventory = await ApiService.addInventory(
                        productId: selectedProductId!,
                        batchId: selectedBatchId!,
                        stockLevel: selectedStockLevel!,
                        quantity: int.parse(quantityController.text),
                      );
                      setState(() {
                        _inventories.add(newInventory);
                      });
                      _fetchInventories();
                      Navigator.of(context).pop();
                    } catch (e) {
                      print('Failed to add inventory: $e');
                    }
                  },
                  width: 150,
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditInventoryDialog(dynamic inventory) {
    final TextEditingController quantityController =
        TextEditingController(text: inventory['p_batch_quantity'].toString());

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
              'Edit Inventory',
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
                  // Custom Dropdown for product selection
                  CustomDropdown<int>(
                    items: _products
                        .map((product) => product['product_id'] as int)
                        .toList(),
                    selectedItem: inventory['p_id'],
                    onChanged: (value) {
                      setState(() {
                        _selectedProductId = value;
                      });
                    },
                    itemAsString: (item) => _products.firstWhere((product) =>
                        product['product_id'] == item)['product_name'],
                    label: 'Select Product',
                  ),
                  const SizedBox(height: 12),
                  // Dropdown for batch selection
                  CustomDropdown<int>(
                    items: _getBatchesForProduct(inventory['p_id'])
                        .map((batch) => batch['p_batch_id'] as int)
                        .toList(),
                    selectedItem: inventory['p_batch_id'],
                    onChanged: (value) {
                      setState(() {
                        _selectedBatchId = value;
                      });
                    },
                    itemAsString: (item) => _allBatches.firstWhere(
                        (batch) => batch['p_batch_id'] == item)['p_batch_name'],
                    label: 'Select Batch',
                  ),
                  const SizedBox(height: 12),
                  // Read-only field for batch expiry date
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Batch Expiry Date',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    controller: TextEditingController(
                      text: _getBatchExpiry(inventory['p_batch_id']) ?? '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dropdown for stock level selection
                  DropdownButtonFormField<String>(
                    value: inventory['stock_level'],
                    decoration: InputDecoration(
                      labelText: 'Select Stock Level',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: ['high', 'medium', 'low'].map((level) {
                      return DropdownMenuItem<String>(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStockLevel = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a stock level' : null,
                  ),
                  const SizedBox(height: 12),
                  // Quantity input field
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    keyboardType: TextInputType.number,
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
                if (_selectedProductId == null ||
                    _selectedBatchId == null ||
                    _selectedStockLevel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                try {
                  final updatedInventory = await ApiService.updateInventory(
                    inventoryId: inventory['inventory_id'],
                    productId: _selectedProductId!,
                    batchId: _selectedBatchId!,
                    stockLevel: _selectedStockLevel!,
                    quantity: int.parse(quantityController.text),
                  );
                  setState(() {
                    // Update the inventory in the list
                    int index = _inventories.indexWhere((inv) =>
                        inv['inventory_id'] == inventory['inventory_id']);
                    if (index != -1) {
                      _inventories[index] = updatedInventory;
                    }
                  });
                  _fetchInventories();
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Failed to update inventory: $e');
                }
              },
              width: 150,
            ),
          ],
        );
      },
    );
  }

  void _deleteInventory(int inventoryId) async {
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
          content: const Text(
              'Are you sure you want to delete this inventory item?'),
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
        await ApiService.deleteInventory(inventoryId);
        setState(() {
          _inventories.removeWhere((inv) => inv['inventory_id'] == inventoryId);
        });
      } catch (e) {
        print('Failed to delete inventory: $e');
      }
    }
  }

  List<dynamic> _getPaginatedInventories() {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _inventories.length) {
      endIndex = _inventories.length;
    }
    return _inventories.sublist(startIndex, endIndex);
  }

  void _nextPage() {
    setState(() {
      if (_currentPage < (_inventories.length / _itemsPerPage).ceil()) {
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

  void _sortInventories(String sortOption) {
    setState(() {
      _selectedSortOption = sortOption;
      // Implement sorting logic if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    final paginatedInventories = _getPaginatedInventories();

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            isSidebarOpen: _isSidebarOpen,
            toggleSidebar: () {
              setState(() {
                _isSidebarOpen = !_isSidebarOpen;
              });
            },
            userName: widget.userName,
            userRole: widget.userRole,
            userId: widget.userId,
            selectedMenuItem: 'Inventory',
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
                              hintText: 'Search Inventory',
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
                          label: const Text('Add New Inventory',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              )),
                          onPressed: _showAddInventoryDialog,
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
                                      'Inventory Table',
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
                                        color: Colors.white,
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
                                        onSelected: _sortInventories,
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
                                                'Inv.ID',
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
                                                'Stock Level',
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
                                                'Quantity',
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
                                                'Created At',
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
                                                'Updated At',
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
                                            : paginatedInventories.isEmpty
                                                ? Center(
                                                    child: Text(
                                                        'No inventories yet.')) // No inventories message
                                                : ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    itemCount:
                                                        paginatedInventories
                                                            .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final inventory =
                                                          paginatedInventories[
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
                                                                inventory['inventory_id']
                                                                        ?.toString() ??
                                                                    'N/A', // Handle null
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
                                                                inventory[
                                                                        'product_name'] ??
                                                                    'N/A', // Handle null
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
                                                                inventory[
                                                                        'p_batch_name'] ??
                                                                    'N/A', // Handle null
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
                                                                        .center, // Center the row content
                                                                children: [
                                                                  // Circle indicator
                                                                  Container(
                                                                    width:
                                                                        20, // Width of the circle
                                                                    height:
                                                                        20, // Height of the circle
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color: _getStockLevelColor(
                                                                          inventory[
                                                                              'stock_level']), // Get color based on stock level
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      width:
                                                                          8), // Space between the circle and text
                                                                  // Fixed width container for text
                                                                  Container(
                                                                    width:
                                                                        60, // Set a fixed width for the text container
                                                                    child: Text(
                                                                      inventory[
                                                                              'stock_level'] ??
                                                                          'N/A', // Handle null
                                                                      style: const TextStyle(
                                                                          fontFamily:
                                                                              'Poppins'),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center, // Center the text
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Text(
                                                                inventory['p_batch_quantity']
                                                                        ?.toString() ??
                                                                    'N/A', // Handle null
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
                                                                inventory[
                                                                        'created_at'] ??
                                                                    'N/A', // Handle null
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
                                                                inventory[
                                                                        'updated_at'] ??
                                                                    'N/A', // Handle null
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
                                                                        _showEditInventoryDialog(
                                                                            inventory),
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .delete,
                                                                        color: Colors
                                                                            .red),
                                                                    onPressed: () =>
                                                                        _deleteInventory(
                                                                            inventory['inventory_id']),
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
                            const Text('Page ',
                                style: TextStyle(fontFamily: 'Poppins')),
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
                                        (_inventories.length / _itemsPerPage)
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
                              ' of ${(_inventories.length / _itemsPerPage).ceil()}',
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _nextPage,
                          color: _currentPage ==
                                  (_inventories.length / _itemsPerPage).ceil()
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
