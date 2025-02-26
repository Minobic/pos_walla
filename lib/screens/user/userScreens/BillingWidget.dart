import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../custom/SidebarHeader.dart'; // Import the reusable components
import '../../../services/ApiService.dart'; // Import the ApiService
import '../../../custom/GradientButton.dart'; // Import the GradientButton
import '../../../custom/RedButton.dart'; // Import the RedButton

class BillingWidget extends StatefulWidget {
  final String userName;
  final String userRole;

  const BillingWidget({
    Key? key,
    required this.userName,
    required this.userRole,
  }) : super(key: key);

  @override
  State<BillingWidget> createState() => _BillingWidgetState();
}

class _BillingWidgetState extends State<BillingWidget> {
  bool _isSidebarOpen = false;
  List<dynamic> _invoiceItems = [];
  final TextEditingController _barcodeController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInvoiceItems();
  }

  Future<void> _fetchInvoiceItems() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });
    try {
      // Fetch invoice items from the API
      final items = await ApiService
          .fetchInvoiceItems(); // Adjust this method in ApiService
      setState(() {
        _invoiceItems = items;
      });
    } catch (e) {
      print('Failed to fetch invoice items: $e');
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  void _deleteInvoiceItem(int invoiceItemId) async {
    try {
      await ApiService.deleteInvoiceItem(
          invoiceItemId); // Adjust this method in ApiService
      setState(() {
        _invoiceItems
            .removeWhere((item) => item['invoice_item_id'] == invoiceItemId);
      });
    } catch (e) {
      print('Failed to delete invoice item: $e');
    }
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ],
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
            toggleSidebar: () {
              setState(() {
                _isSidebarOpen = !_isSidebarOpen;
              });
            },
            userName: widget.userName,
            userRole: widget.userRole,
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
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        hintText: 'Enter Barcode',
                        prefixIcon: Icon(Icons.qr_code_scanner),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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
                              child: const Center(
                                child: Text(
                                  'Invoice Items',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: _isLoading
                                  ? Center(child: CircularProgressIndicator())
                                  : _invoiceItems.isEmpty
                                      ? Center(
                                          child: Text('No invoice items yet.'))
                                      : ListView.builder(
                                          itemCount: _invoiceItems.length,
                                          itemBuilder: (context, index) {
                                            final item = _invoiceItems[index];
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
                                                    child: Text(
                                                      item['quantity']
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
                                                      (item['quantity'] *
                                                              item[
                                                                  'sale_price'])
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
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.edit,
                                                              color:
                                                                  Colors.green),
                                                          onPressed: () {
                                                            // Implement edit functionality
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.delete,
                                                              color:
                                                                  Colors.red),
                                                          onPressed: () =>
                                                              _deleteInvoiceItem(
                                                                  item[
                                                                      'invoice_item_id']),
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
                            // Summary Section
                            Container(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildSummaryCard(
                                      'Total Products', '40', Colors.blue),
                                  _buildSummaryCard(
                                      'Total Quantity', '61', Colors.blue),
                                  _buildSummaryCard(
                                      'Total Price', '₹4800', Colors.blue),
                                ],
                              ),
                            ),
                            // Checkout Button
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: ElevatedButton(
                                onPressed: () {
                                  // Implement checkout functionality
                                },
                                child: Text('Proceed to Checkout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
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
        ],
      ),
    );
  }
}
