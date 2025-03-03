import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../custom/SidebarHeader.dart';
import '../../../services/ApiService.dart';
import '../../../custom/GradientButton.dart';
import '../../../custom/RedButton.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CheckoutWidget extends StatefulWidget {
  final String userName;
  final String userRole;
  final int userId;
  final List<Map<String, dynamic>> billingItems;
  final int totalQuantity;
  final double totalPrice;

  const CheckoutWidget({
    Key? key,
    required this.userName,
    required this.userRole,
    required this.userId,
    required this.billingItems,
    required this.totalQuantity,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<CheckoutWidget> createState() => _CheckoutWidgetState();
}

class _CheckoutWidgetState extends State<CheckoutWidget> {
  bool _isSidebarOpen = false;
  final TextEditingController _promoCodeController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _customerNameController =
      TextEditingController(); // New controller for customer name
  double _discount = 0.0;
  double _tax = 0.0;
  double _subtotal = 0.0;
  double _total = 0.0;
  List<String> _paymentMethods = [];
  String? _selectedPaymentMethod;
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    _subtotal = widget.totalPrice;
    _total = widget.totalPrice;
    _fetchPaymentMethods();
    _initPrinter();
  }

  void _initPrinter() async {
    // Initialize the printer
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      // Connect to the printer if not already connected
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      if (devices.isNotEmpty) {
        await bluetooth.connect(devices[0]);
      }
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final paymentMethods = await ApiService.fetchPaymentMethods();
      setState(() {
        _paymentMethods = List<String>.from(paymentMethods);
        if (_paymentMethods.isNotEmpty) {
          _selectedPaymentMethod = _paymentMethods[0];
        }
      });
    } catch (e) {
      print('Failed to fetch payment methods: $e');
    }
  }

  void _applyPromoCode(String promoCode) async {
    try {
      final discount = await ApiService.applyPromoCode(promoCode, _subtotal);
      setState(() {
        _discount = discount;
        _total = _subtotal - _discount + _tax;
      });
    } catch (e) {
      print('Failed to apply promo code: $e');
    }
  }

  void _confirmPayment() async {
    try {
      final invoice = await ApiService.createInvoice(
        userId: widget.userId,
        customerName: _customerNameController.text,
        customerMobile: _mobileController.text,
        totalAmount: _total,
        subTotal: _subtotal,
        discountAmount: _discount,
        taxAmount: _tax,
        paymentMethod: _selectedPaymentMethod ?? '',
        items: widget.billingItems.map((item) {
          return {
            'product_id': item['product_id'],
            'quantity': item['quantity'],
            'sale_price': item['sale_price'],
            'p_batch_id': item['batch'] ?? null,
          };
        }).toList(),
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment confirmed successfully')),
      );

      await PdfBillGenerator.generateAndSavePdf(
        customerName: _customerNameController.text,
        mobileNumber: _mobileController.text,
        paymentMethod: _selectedPaymentMethod ?? '',
        billingItems: widget.billingItems,
        subtotal: _subtotal,
        discount: _discount,
        tax: _tax,
        total: _total,
      );
      // Print the bill
      _printBill();

      // Navigate back to billing page
      Navigator.pushReplacementNamed(
        context,
        '/billing',
        arguments: {
          'name': widget.userName,
          'role': widget.userRole,
          'userId': widget.userId,
        },
      );
    } catch (e) {
      print('Failed to confirm payment: $e');
    }
  }

  void _printBill() async {
    // Check if the printer is connected
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printer is not connected')),
      );
      return;
    }

    // Create the bill content
    String billContent = """
    Customer Name: ${_customerNameController.text}
    Mobile: ${_mobileController.text}
    Payment Method: $_selectedPaymentMethod
    ----------------------------------------
    Product Name\tQty\tPrice\tTotal
    """;

    for (var item in widget.billingItems) {
      billContent += """
    ${item['product_name']}\t${item['quantity']}\t${item['sale_price']}\t${item['total_price']}
    """;
    }

    billContent += """
    ----------------------------------------
    Subtotal: $_subtotal
    Discount: $_discount
    Tax: $_tax
    Total: $_total
    ----------------------------------------
    Thank you for your purchase!
    """;

    // Print the bill
    bluetooth.printCustom(billContent, 1, 1);
  }

  void _removeItem(int index) {
    setState(() {
      widget.billingItems.removeAt(index);
      // Recalculate totals if needed
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    _subtotal =
        widget.billingItems.fold(0.0, (sum, item) => sum + item['total_price']);
    _total = _subtotal - _discount + _tax;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
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
            child: Column(
              children: [
                Header(
                  userName: widget.userName,
                  userRole: widget.userRole,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Promo Code Input
                          TextField(
                            controller: _promoCodeController,
                            decoration: InputDecoration(
                              hintText: 'Enter Promo Code',
                              hintStyle: TextStyle(fontFamily: 'Poppins'),
                              prefixIcon: const Icon(Icons.local_offer),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.check),
                                onPressed: () =>
                                    _applyPromoCode(_promoCodeController.text),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onSubmitted: (value) {
                              _applyPromoCode(value);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Checkout Table
                          Container(
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
                                  child: Center(
                                    child: Text(
                                      'Checkout Table',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                                // Table with FIXED HEIGHT
                                Container(
                                  height: 300, // EXPLICIT HEIGHT
                                  margin: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
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
                                                'Price',
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
                                                'Total',
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
                                          itemCount: widget.billingItems.length,
                                          itemBuilder: (context, index) {
                                            final item =
                                                widget.billingItems[index];
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Customer Name
                          TextField(
                            controller: _customerNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter Customer Name',
                              hintStyle: TextStyle(fontFamily: 'Poppins'),
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Customer Mobile Number
                          TextField(
                            controller: _mobileController,
                            decoration: InputDecoration(
                              hintText: 'Enter Customer Mobile Number',
                              hintStyle: TextStyle(fontFamily: 'Poppins'),
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          // Payment Methods
                          DropdownButtonFormField<String>(
                            value: _selectedPaymentMethod,
                            decoration: InputDecoration(
                              labelText: 'Select Payment Method',
                              labelStyle: TextStyle(fontFamily: 'Poppins'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            items: _paymentMethods.map((method) {
                              return DropdownMenuItem<String>(
                                value: method,
                                child: Text(method),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Subtotal, Discount, Tax Container
                          Container(
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
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Subtotal:',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹$_subtotal',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Discount:',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹$_discount',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Tax:',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹$_tax',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Total Container
                          Container(
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹$_total',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Confirm Payment Button
                          GradientButton(
                            text: 'Confirm Payment',
                            onPressed: _confirmPayment,
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PdfBillGenerator {
  static Future<void> generateAndSavePdf({
    required String customerName,
    required String mobileNumber,
    required String paymentMethod,
    required List<Map<String, dynamic>> billingItems,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
  }) async {
    // Define the page size for a 2-inch thermal printer
    const double pageWidth = 58 * PdfPageFormat.mm; // 58mm width
    const double pageHeight = 200 * PdfPageFormat.mm; // Adjust height as needed

    // Create a PDF document
    final pdf = pw.Document();

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'Invoice',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 5),

              // Customer Details
              pw.Text('Customer: $customerName'),
              pw.Text('Mobile: $mobileNumber'),
              pw.Text('Payment: $paymentMethod'),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Table Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Item',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Qty',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Price',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Total',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 5),

              // Bill Items
              ...billingItems.map((item) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(item['product_name'].toString()),
                    pw.Text(item['quantity'].toString()),
                    pw.Text(item['sale_price'].toString()),
                    pw.Text(item['total_price'].toString()),
                  ],
                );
              }).toList(),

              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:'),
                  pw.Text('Rs$subtotal'), // Replace ₹ with Rs
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Discount:'),
                  pw.Text('Rs$discount'), // Replace ₹ with Rs
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tax:'),
                  pw.Text('Rs$tax'), // Replace ₹ with Rs
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Rs$total', // Replace ₹ with Rs
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for your purchase!',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF to a file
    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }
}
