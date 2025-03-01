import 'dart:convert';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchProductBatches();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      // Implement search functionality if needed
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  Future<void> _fetchProductBatches() async {
    try {
      final batches = await ApiService.fetchProductBatches();
      setState(() {
        _productBatches = List<Map<String, dynamic>>.from(batches);
      });
    } catch (e) {
      print('Failed to fetch product batches: $e');
    }
  }

  void _addProductByBarcode(String barcode) async {
    try {
      final product = await ApiService.fetchProductByBarcode(barcode);
      if (product != null) {
        bool isExisting = false;
        for (var item in _billingItems) {
          if (item['product_id'] == product['product_id']) {
            item['quantity'] += 1;
            item['total_price'] = item['quantity'] * item['sale_price'];
            isExisting = true;
            break;
          }
        }
        if (!isExisting) {
          String? selectedBatch = null;
          DateTime? batchExpiry = null;

          // Check if the product has batches
          final productBatches = _productBatches
              .where((batch) =>
                  batch['p_id'] == product['product_id'] &&
                  DateTime.parse(batch['p_batch_exp']).isAfter(DateTime.now()))
              .toList();

          if (productBatches.isNotEmpty) {
            selectedBatch = productBatches.first['p_batch_id'].toString();
            batchExpiry = DateTime.parse(productBatches.first['p_batch_exp']);
          }

          setState(() {
            _billingItems.add({
              'product_id': product['product_id'],
              'product_name': product['product_name'],
              'quantity': 1,
              'mrp_price': product['mrp_price'],
              'sale_price': product['sale_price'],
              'total_price': product['sale_price'],
              'batch': selectedBatch,
              'batch_expiry': batchExpiry?.toString(),
            });
            _calculateTotals();
          });
        } else {
          // Trigger a rebuild to reflect the updated quantity
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

  void _updateQuantity(int index, int quantity) {
    setState(() {
      _billingItems[index]['quantity'] = quantity;
      _billingItems[index]['total_price'] =
          quantity * _billingItems[index]['sale_price'];
      _calculateTotals(); // Ensure totals are recalculated
    });
  }

  void _removeItem(int index) {
    setState(() {
      _billingItems.removeAt(index);
      _calculateTotals();
    });
  }

  void _proceedToCheckout() {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            controller: _barcodeController,
                            decoration: InputDecoration(
                              hintText: 'Scan Barcode',
                              hintStyle: TextStyle(fontFamily: 'Poppins'),
                              prefixIcon: const Icon(Icons.qr_code_scanner),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add Product',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              )),
                          onPressed: () {
                            _addProductByBarcode(_barcodeController.text);
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
                                              flex: 1,
                                              child: Text(
                                                'Batch',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
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
                                              flex: 1,
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
                                              flex: 1,
                                              child: Text(
                                                'Sale Price',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'Total Price',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
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
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: _billingItems.length,
                                          itemBuilder: (context, index) {
                                            final item = _billingItems[index];
                                            final productBatches =
                                                _productBatches
                                                    .where((batch) =>
                                                        batch['p_id'] ==
                                                            item[
                                                                'product_id'] &&
                                                        DateTime.parse(batch[
                                                                'p_batch_exp'])
                                                            .isAfter(
                                                                DateTime.now()))
                                                    .toList();

                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                      color:
                                                          Colors.grey.shade300),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      item['product_name'],
                                                      style: const TextStyle(
                                                          fontFamily:
                                                              'Poppins'),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child:
                                                        DropdownButton<String>(
                                                      value: item['batch'],
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _billingItems[index]
                                                              ['batch'] = value;
                                                        });
                                                      },
                                                      items: productBatches
                                                          .map((batch) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: batch[
                                                                  'p_batch_id']
                                                              .toString(),
                                                          child: Text(batch[
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
                                                              Icons.remove,
                                                              color:
                                                                  Colors.red),
                                                          onPressed: () {
                                                            if (item[
                                                                    'quantity'] >
                                                                1) {
                                                              _updateQuantity(
                                                                  index,
                                                                  item['quantity'] -
                                                                      1);
                                                            }
                                                          },
                                                        ),
                                                        Text(
                                                          item['quantity']
                                                              .toString(),
                                                          style: const TextStyle(
                                                              fontFamily:
                                                                  'Poppins'),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.add,
                                                              color:
                                                                  Colors.green),
                                                          onPressed: () {
                                                            _updateQuantity(
                                                                index,
                                                                item['quantity'] +
                                                                    1);
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
                                                          TextAlign.center,
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
                                                          TextAlign.center,
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
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red),
                                                      onPressed: () =>
                                                          _removeItem(index),
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
                      child: Container(
                        padding: const EdgeInsets.all(
                            10), // Add padding for better spacing
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .center, // Center-align text
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
                              crossAxisAlignment: CrossAxisAlignment
                                  .center, // Center-align text
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
                              crossAxisAlignment: CrossAxisAlignment
                                  .center, // Center-align text
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
            ),
          ),
        ],
      ),
    );
  }
}
