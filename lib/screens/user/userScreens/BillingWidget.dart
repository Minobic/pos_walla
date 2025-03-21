import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for keyboard events
import '../../../custom/SidebarHeader.dart';
import '../../../services/ApiService.dart';
import '../../../custom/GradientButton.dart';
import '../../../custom/RedButton.dart';
import 'CheckoutWidget.dart';

class BillingWidget extends StatefulWidget {
  final String userName;
  final String userRole;
  final int userId;

  const BillingWidget({
    Key? key,
    required this.userName,
    required this.userRole,
    required this.userId,
  }) : super(key: key);

  @override
  State<BillingWidget> createState() => _BillingWidgetState();
}

class _BillingWidgetState extends State<BillingWidget> {
  bool _isSidebarOpen = false;
  List<Map<String, dynamic>> _billingItems = [];
  List<Map<String, dynamic>> _productBatches = [];
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  int _totalQuantity = 0;
  double _totalPrice = 0.0;
  List<Map<String, dynamic>> _filteredBatches = [];
  int? _selectedBatchIndex;
  FocusNode _barcodeFocusNode = FocusNode();
  bool _isDropdownVisible = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _barcodeController.addListener(_onBarcodeChanged);
    _fetchProductBatches();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _barcodeController.removeListener(_onBarcodeChanged);
    _searchController.dispose();
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      // Implement search functionality if needed
    });
  }

  void _onBarcodeChanged() async {
    if (_barcodeController.text.isNotEmpty) {
      final product =
          await ApiService.fetchProductByBarcode(_barcodeController.text);
      if (product != null) {
        _filteredBatches = _productBatches
            .where((batch) => batch['p_id'] == product['product_id'])
            .toList();
        setState(() {
          _selectedBatchIndex = null; // Reset selection
        });
      } else {
        _filteredBatches.clear();
      }
    } else {
      _filteredBatches.clear();
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  // Function to convert "DD-MM-YYYY" to ISO 8601 format
  String convertToIsoFormat(String dateStr) {
    List<String> dateParts = dateStr.split('-');
    return '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';
  }

  // Function to convert ISO 8601 format to "DD-MM-YYYY"
  String convertToIndianFormat(String dateStr) {
    List<String> dateParts = dateStr.split('-');
    return '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';
  }

  void _fetchProductBatches() async {
    try {
      final batches = await ApiService.fetchProductBatches();
      setState(() {
        _productBatches = List<Map<String, dynamic>>.from(batches);
        for (var batch in _productBatches) {
          batch['p_batch_mfg'] = convertToIsoFormat(batch['p_batch_mfg']);
          batch['p_batch_exp'] = convertToIsoFormat(batch['p_batch_exp']);
        }
      });
    } catch (e) {
      print('Failed to fetch product batches: $e');
    }
  }

  Future<int?> _findAvailableBatch(int productId, int quantity) async {
    for (var batch in _productBatches) {
      if (batch['p_id'] == productId) {
        try {
          await _checkBatchStock(batch['p_batch_id'], quantity);
          return batch['p_batch_id'];
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  Future<void> _checkBatchStock(int batchId, int quantity) async {
    try {
      final inventory = await ApiService.fetchInventories();
      final batchInventory = inventory.firstWhere(
        (item) => item['p_batch_id'] == batchId,
        orElse: () => null,
      );

      if (batchInventory != null &&
          batchInventory['p_batch_quantity'] >= quantity) {
        return;
      } else {
        throw Exception('Insufficient stock');
      }
    } catch (e) {
      print('Failed to check batch stock: $e');
      throw Exception('Failed to check batch stock');
    }
  }

  void _addProductByBarcode(String barcode) async {
    try {
      final product = await ApiService.fetchProductByBarcode(barcode);
      if (product != null) {
        int? selectedBatch =
            await _findAvailableBatch(product['product_id'], 1);

        if (selectedBatch != null) {
          bool isExisting = false;
          for (var item in _billingItems) {
            if (item['product_id'] == product['product_id'] &&
                item['batch'] == selectedBatch) {
              item['quantity'] += 1;
              item['total_price'] = item['quantity'] * item['sale_price'];
              isExisting = true;
              await _checkBatchStock(item['batch'], item['quantity']);
              break;
            }
          }
          if (!isExisting) {
            setState(() {
              _billingItems.add({
                'product_id': product['product_id'],
                'product_name': product['product_name'],
                'quantity': 1,
                'mrp_price': product['mrp_price'],
                'sale_price': product['sale_price'],
                'total_price': product['sale_price'],
                'batch': selectedBatch,
              });
              _calculateTotals();
            });
          } else {
            setState(() {
              _calculateTotals();
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No available batch with sufficient stock')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product not found')),
        );
      }
    } catch (e) {
      print('Failed to fetch product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    }
  }

  void _addProduct(int batchId) async {
    try {
      final product =
          await ApiService.fetchProductByBarcode(_barcodeController.text);
      if (product != null) {
        bool isExisting = false;
        for (var item in _billingItems) {
          if (item['product_id'] == product['product_id'] &&
              item['batch'] == batchId) {
            item['quantity'] += 1;
            item['total_price'] = item['quantity'] * item['sale_price'];
            isExisting = true;
            await _checkBatchStock(item['batch'], item['quantity']);
            break;
          }
        }
        if (!isExisting) {
          setState(() {
            _billingItems.add({
              'product_id': product['product_id'],
              'product_name': product['product_name'],
              'quantity': 1,
              'mrp_price': product['mrp_price'],
              'sale_price': product['sale_price'],
              'total_price': product['sale_price'],
              'batch': batchId,
            });
            _calculateTotals();
          });
        } else {
          setState(() {
            _calculateTotals();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product not found')),
        );
      }
    } catch (e) {
      print('Failed to fetch product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    }
  }

  void _calculateTotals() {
    int totalQuantity = 0;
    double totalPrice = 0.0;
    for (var item in _billingItems) {
      totalQuantity += item['quantity'] as int;
      totalPrice += item['total_price'] as double;
    }
    setState(() {
      _totalQuantity = totalQuantity;
      _totalPrice = totalPrice;
    });
  }

  void _updateQuantity(int index, int quantity) async {
    try {
      await _checkBatchStock(_billingItems[index]['batch'], quantity);
      setState(() {
        _billingItems[index]['quantity'] = quantity;
        _billingItems[index]['total_price'] =
            quantity * (_billingItems[index]['sale_price'] as double);
        _calculateTotals();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update quantity: $e')),
      );
    }
  }

  void _removeItem(int index) {
    setState(() {
      _billingItems.removeAt(index);
      _calculateTotals();
    });
  }

  void _proceedToCheckout() async {
    try {
      for (var item in _billingItems) {
        await _checkBatchStock(item['batch'], item['quantity']);
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutWidget(
            userName: widget.userName,
            userRole: widget.userRole,
            userId: widget.userId,
            billingItems: _billingItems,
            totalQuantity: _totalQuantity,
            totalPrice: _totalPrice,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to proceed to checkout: $e')),
      );
    }
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (_filteredBatches.isNotEmpty) {
        if (event.logicalKey == LogicalKeyboardKey.enter &&
            _selectedBatchIndex != null) {
          // Add product with selected batch
          _addProduct(_filteredBatches[_selectedBatchIndex!]['p_batch_id']);
          _barcodeController.clear();
          _filteredBatches.clear();
          _selectedBatchIndex = null;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() {
            if (_selectedBatchIndex == null) {
              _selectedBatchIndex = 0;
            } else if (_selectedBatchIndex! < _filteredBatches.length - 1) {
              _selectedBatchIndex = _selectedBatchIndex! + 1;
            }
          });
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() {
            if (_selectedBatchIndex != null && _selectedBatchIndex! > 0) {
              _selectedBatchIndex = _selectedBatchIndex! - 1;
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
        focusNode: FocusNode(), // Create a focus node for the keyboard listener
        onKey: _handleKeyPress,
        child: GestureDetector(
          onTap: () {
            // Close the dropdown when tapping outside
            setState(() {
              _isDropdownVisible = false;
              _filteredBatches.clear();
            });
          },
          child: Scaffold(
            body: Row(
              children: [
                Sidebar(
                  isSidebarOpen: _isSidebarOpen,
                  toggleSidebar: _toggleSidebar,
                  userName: widget.userName,
                  userRole: widget.userRole,
                  userId: widget.userId,
                  selectedMenuItem: 'Billing',
                ),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Stack(
                      // Use Stack to overlay the dropdown
                      children: [
                        Column(
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
                                      controller: _barcodeController,
                                      focusNode: _barcodeFocusNode,
                                      decoration: InputDecoration(
                                        hintText: 'Scan Barcode',
                                        hintStyle:
                                            TextStyle(fontFamily: 'Poppins'),
                                        prefixIcon:
                                            const Icon(Icons.qr_code_scanner),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                      ),
                                      onSubmitted: (value) {
                                        // Trigger the barcode change listener
                                        _onBarcodeChanged();
                                      },
                                      onTap: () {
                                        // Show the dropdown when the text field is tapped
                                        setState(() {
                                          _isDropdownVisible = true;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add,
                                        color: Colors.white),
                                    label: const Text('Add Product',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        )),
                                    onPressed: () {
                                      _addProductByBarcode(
                                          _barcodeController.text);
                                      _barcodeController.clear();
                                    },
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
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          children: [
                                            const Center(
                                              child: Text(
                                                'Billing Table',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Poppins',
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
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
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
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 16),
                                                  decoration:
                                                      const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Color(0xFF2196F3),
                                                        Color(0xFF1976D2)
                                                      ],
                                                      begin:
                                                          Alignment.centerLeft,
                                                      end:
                                                          Alignment.centerRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(25),
                                                      topRight:
                                                          Radius.circular(25),
                                                    ),
                                                  ),
                                                  child: const Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          'Product Name',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'Poppins',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Text(
                                                          'Batch',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'Poppins',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Text(
                                                          'Quantity',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'Poppins',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Text(
                                                          'MRP',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'Poppins',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Text(
                                                          'Sale Price',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'Poppins',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Text(
                                                          'Total Price',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'Poppins',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Text(
                                                          'Action',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'Poppins',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Scrollable Data
                                                Expanded(
                                                  child: ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    itemCount:
                                                        _billingItems.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final item =
                                                          _billingItems[index];
                                                      final productBatches = _productBatches
                                                          .where((batch) =>
                                                              batch['p_id'] ==
                                                                  item[
                                                                      'product_id'] &&
                                                              DateTime.parse(batch[
                                                                      'p_batch_exp'])
                                                                  .isAfter(
                                                                      DateTime
                                                                          .now()))
                                                          .toList();

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
                                                              flex: 2,
                                                              child: Text(
                                                                item[
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
                                                              flex: 1,
                                                              child:
                                                                  DropdownButton<
                                                                      int>(
                                                                value: item[
                                                                    'batch'],
                                                                onChanged:
                                                                    (value) async {
                                                                  try {
                                                                    await _checkBatchStock(
                                                                        value!,
                                                                        item[
                                                                            'quantity']);
                                                                    setState(
                                                                        () {
                                                                      _billingItems[index]
                                                                              [
                                                                              'batch'] =
                                                                          value;
                                                                    });
                                                                  } catch (e) {
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                          content:
                                                                              Text('Failed to update batch: $e')),
                                                                    );
                                                                  }
                                                                },
                                                                items: productBatches
                                                                    .map(
                                                                        (batch) {
                                                                  return DropdownMenuItem<
                                                                      int>(
                                                                    value: batch[
                                                                            'p_batch_id']
                                                                        as int,
                                                                    child: Text(
                                                                        batch[
                                                                            'p_batch_name']),
                                                                  );
                                                                }).toList(),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 1,
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .remove,
                                                                        color: Colors
                                                                            .red),
                                                                    onPressed:
                                                                        () {
                                                                      if (_billingItems[index]
                                                                              [
                                                                              'quantity'] >
                                                                          1) {
                                                                        _updateQuantity(
                                                                            index,
                                                                            _billingItems[index]['quantity'] -
                                                                                1);
                                                                      }
                                                                    },
                                                                  ),
                                                                  Text(
                                                                    _billingItems[index]
                                                                            [
                                                                            'quantity']
                                                                        .toString(),
                                                                    style: const TextStyle(
                                                                        fontFamily:
                                                                            'Poppins'),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .add,
                                                                        color: Colors
                                                                            .green),
                                                                    onPressed:
                                                                        () async {
                                                                      try {
                                                                        await _checkBatchStock(
                                                                            _billingItems[index][
                                                                                'batch'],
                                                                            _billingItems[index]['quantity'] +
                                                                                1);
                                                                        _updateQuantity(
                                                                            index,
                                                                            _billingItems[index]['quantity'] +
                                                                                1);
                                                                      } catch (e) {
                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(
                                                                          SnackBar(
                                                                              content: Text('Failed to update quantity: $e')),
                                                                        );
                                                                      }
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 1,
                                                              child: Text(
                                                                item['mrp_price']
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
                                                              flex: 1,
                                                              child: Text(
                                                                item['sale_price']
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
                                                              flex: 1,
                                                              child: Text(
                                                                item['total_price']
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
                                                              flex: 1,
                                                              child: IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .delete,
                                                                    color: Colors
                                                                        .red),
                                                                onPressed: () =>
                                                                    _removeItem(
                                                                        index),
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
                            // Total Container
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
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
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Total Products',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${_billingItems.length}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        height: 40,
                                        child: const VerticalDivider(
                                          color: Colors.grey,
                                          thickness: 1,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Total Quantity',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '$_totalQuantity',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        height: 40,
                                        child: const VerticalDivider(
                                          color: Colors.grey,
                                          thickness: 1,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Total Price',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '₹$_totalPrice',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Proceed to Checkout Button
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: GradientButton(
                                text: 'Proceed to Checkout',
                                onPressed: _proceedToCheckout,
                                width: double.infinity,
                              ),
                            ),
                          ],
                        ),
                        // Floating Dropdown
                        if (_filteredBatches.isNotEmpty)
                          Positioned(
                            top:
                                170, // Adjust this value to position the dropdown correctly below the text field
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: List.generate(_filteredBatches.length,
                                    (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      _addProduct(_filteredBatches[index]
                                          ['p_batch_id']);
                                      _barcodeController.clear();
                                      setState(() {
                                        _filteredBatches.clear();
                                        _isDropdownVisible = false;
                                      });
                                    },
                                    child: Container(
                                      color: _selectedBatchIndex == index
                                          ? Colors.blue.shade100
                                          : null,
                                      child: ListTile(
                                        title: Text(_filteredBatches[index]
                                            ['p_batch_name']),
                                        subtitle: Text(
                                            'Exp: ${convertToIndianFormat(_filteredBatches[index]['p_batch_exp'])}'),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
