import 'package:flutter/material.dart';
import '../../../custom/SidebarHeader.dart';
import '../../../custom/AdminSidebar.dart';
import '../../../custom/AdminGradientButton.dart';
import '../../../services/ApiService.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import '../../../custom/GradientButton.dart';
import '../../../custom/RedButton.dart';
import 'package:intl/intl.dart'; // Import the intl package

class TransactionWidget extends StatefulWidget {
  String selectedPeriod;

  TransactionWidget({Key? key, required this.selectedPeriod}) : super(key: key);

  @override
  State<TransactionWidget> createState() => _TransactionWidgetState();
}

class _TransactionWidgetState extends State<TransactionWidget> {
  String _sortBy = 'Recently';
  bool _isOnline = true;
  bool _isSidebarOpen = false;
  List<dynamic> _transactions = [];
  double _cashTotal = 0.0;
  double _onlineTotal = 0.0;
  String _title = "Today's Transaction";

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final transactions =
          await ApiService.fetchTransactions(widget.selectedPeriod);
      setState(() {
        _transactions = transactions;
        _calculateTotals(transactions);
      });
    } catch (e) {
      print('Error fetching transactions: $e');
    }
  }

  void _calculateTotals(List<dynamic> transactions) {
    _cashTotal = 0.0;
    _onlineTotal = 0.0;

    for (var transaction in transactions) {
      if (transaction['payment_method'] == 'Cash') {
        _cashTotal += transaction['total_amount'];
      } else {
        _onlineTotal += transaction['total_amount'];
      }
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _updatePeriod(String period) {
    setState(() {
      widget.selectedPeriod = period;
      if (period == 'custom') {
        _showCustomDateRangeDialog();
      } else {
        _fetchTransactions();
        switch (period) {
          case 'daily':
            _title = "Today's Transaction";
            break;
          case 'weekly':
            _title = "This Week's Transactions";
            break;
          case 'monthly':
            _title = "This Month's Transactions";
            break;
          case 'quarterly':
            _title = "This Quarter's Transactions";
            break;
          case 'yearly':
            _title = "This Year's Transactions";
            break;
          default:
            _title = "Transactions";
        }
      }
    });
  }

  Future<void> _showCustomDateRangeDialog() async {
    TextEditingController startDateController = TextEditingController();
    TextEditingController endDateController = TextEditingController();

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
              'Select Date Range',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: startDateController,
                  decoration: InputDecoration(
                    labelText: 'Start Date (DD-MM-YYYY)',
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endDateController,
                  decoration: InputDecoration(
                    labelText: 'End Date (DD-MM-YYYY)',
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
              ],
            ),
          ),
          actions: [
            RedButton(
              text: 'Cancel',
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              width: 150, // Set the width of the button
            ),
            GradientButton(
              text: 'Apply',
              onPressed: () {
                String startDate = startDateController.text;
                String endDate = endDateController.text;

                if (startDate.isNotEmpty && endDate.isNotEmpty) {
                  try {
                    // Parse the input dates
                    DateFormat inputFormat = DateFormat('dd-MM-yyyy');
                    DateFormat apiFormat = DateFormat('yyyy-MM-dd');

                    DateTime parsedStartDate = inputFormat.parse(startDate);
                    DateTime parsedEndDate = inputFormat.parse(endDate);

                    // Format the dates for the API call
                    String formattedStartDate =
                        apiFormat.format(parsedStartDate);
                    String formattedEndDate = apiFormat.format(parsedEndDate);

                    setState(() {
                      widget.selectedPeriod = 'custom';
                      _title = "Custom Period Transactions";
                      _fetchCustomTransactions(
                          formattedStartDate, formattedEndDate);
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Please enter valid dates in DD-MM-YYYY format.'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter both start and end dates.'),
                    ),
                  );
                }
              },
              width: 150, // Set the width of the button
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchCustomTransactions(
      String startDate, String endDate) async {
    try {
      final transactions =
          await ApiService.fetchCustomTransactions(startDate, endDate);
      setState(() {
        _transactions = transactions;
        _calculateTotals(transactions);
      });
    } catch (e) {
      print('Error fetching custom transactions: $e');
    }
  }

  Future<void> _printTransactions() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              children: [
                pw.Text(_title,
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Customer', 'Date', 'Amount', 'Type'],
                    ..._transactions.map((transaction) => [
                          transaction['customer_name'],
                          transaction['created_at'],
                          'Rs. ${transaction['total_amount']}',
                          transaction['payment_method'],
                        ])
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await doc.save();
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) => bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          AdminSidebar(
            isSidebarOpen: _isSidebarOpen,
            toggleSidebar: _toggleSidebar,
            userName: 'Admin',
            userRole: 'Admin',
            userId: 1,
            selectedMenuItem: 'Transactions',
          ),
          Expanded(
            child: Column(
              children: [
                Header(
                  userName: 'Admin',
                  userRole: 'Admin',
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Today's Transaction card
                        Expanded(
                          flex: 1,
                          child: Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _title,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const Icon(Icons.more_horiz),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: Card(
                                      color: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              height:
                                                  35, // Set your desired height here
                                              child: ToggleButtons(
                                                isSelected: [
                                                  !_isOnline,
                                                  _isOnline
                                                ],
                                                onPressed: (int index) {
                                                  setState(() {
                                                    _isOnline = index == 1;
                                                  });
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                selectedColor: Colors.white,
                                                fillColor: Colors.blue,
                                                color: Colors.black,
                                                selectedBorderColor:
                                                    Colors.blue,
                                                borderColor: Colors.grey
                                                    .withOpacity(0.6),
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20),
                                                    child: Text(
                                                      'Cash',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20),
                                                    child: Text(
                                                      'Online',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 30),
                                            Center(
                                              child: Text(
                                                _isOnline
                                                    ? '₹ $_onlineTotal'
                                                    : '₹ $_cashTotal',
                                                style: TextStyle(
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue[700],
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(30),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF2196F3),
                                            Color(0xFF1976D2)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Total Balance',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 25,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.baseline,
                                            textBaseline:
                                                TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                '₹ ${_cashTotal + _onlineTotal}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 50,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                              ),
                                              onPressed: () =>
                                                  _updatePeriod('daily'),
                                              child: Text(
                                                'Daily',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                              ),
                                              onPressed: () =>
                                                  _updatePeriod('weekly'),
                                              child: Text(
                                                'Weekly',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                              ),
                                              onPressed: () =>
                                                  _updatePeriod('monthly'),
                                              child: Text(
                                                'Monthly',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                              ),
                                              onPressed: () =>
                                                  _updatePeriod('quarterly'),
                                              child: Text(
                                                'Quarterly',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                              ),
                                              onPressed: () =>
                                                  _updatePeriod('yearly'),
                                              child: Text(
                                                'Yearly',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                              ),
                                              onPressed: () =>
                                                  _updatePeriod('custom'),
                                              child: Text(
                                                'Custom',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),
                        // Transaction list card
                        Expanded(
                          flex: 1,
                          child: Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Transaction',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Text('Sort by'),
                                          const SizedBox(width: 5),
                                          DropdownButton<String>(
                                            dropdownColor: Colors.white,
                                            value: _sortBy,
                                            icon: const Icon(
                                                Icons.arrow_drop_down),
                                            underline: Container(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _sortBy = newValue!;
                                              });
                                            },
                                            items: <String>[
                                              'Recently',
                                              'Oldest',
                                              'Amount'
                                            ].map<DropdownMenuItem<String>>(
                                                (String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(
                                                  value,
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      AdminGradientButton(
                                        text: 'Print',
                                        icon: Icons.print,
                                        onPressed:
                                            _printTransactions, // Set the onPressed callback to _printTransactions
                                      ),
                                      const SizedBox(width: 10),
                                      AdminGradientButton(
                                        text: 'Share',
                                        icon: Icons.share,
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 15),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[500],
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Customer',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Date',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Amount',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Type',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _transactions.length,
                                      itemBuilder: (context, index) {
                                        final transaction =
                                            _transactions[index];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 15, horizontal: 15),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey
                                                    .withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  transaction['customer_name'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  transaction['created_at'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '₹ ${transaction['total_amount']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  transaction['payment_method'],
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Poppins',
                                                  ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
