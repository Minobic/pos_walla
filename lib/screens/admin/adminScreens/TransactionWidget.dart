import 'package:flutter/material.dart';
import '../../../custom/SidebarHeader.dart';
import '../../../custom/AdminSidebar.dart';
import '../../../custom/AdminGradientButton.dart'; // Adjust the import path as necessary
import '../../../services/ApiService.dart';

class TransactionWidget extends StatefulWidget {
  final String selectedPeriod;

  const TransactionWidget({Key? key, required this.selectedPeriod})
      : super(key: key);

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
      if (transaction['payment_method'] == 'cash') {
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
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Today's Transaction",
                                        style: TextStyle(
                                          fontSize: 18,
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
                                      padding: const EdgeInsets.all(50),
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
                                              fontSize: 16,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          const SizedBox(height: 10),
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
                                                  fontSize: 40,
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
                              padding: const EdgeInsets.all(20),
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
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Text('Sort by'),
                                          const SizedBox(width: 5),
                                          DropdownButton<String>(
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
                                        onPressed: () {},
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
                                          flex: 2,
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
                                          flex: 1,
                                          child: Text(
                                            'Amount',
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
                                                flex: 2,
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
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      transaction['created_at'],
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '₹ ${transaction['total_amount']}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                    Text(
                                                      transaction[
                                                          'payment_method'],
                                                      style: TextStyle(
                                                        color: transaction[
                                                                    'payment_method'] ==
                                                                'Online'
                                                            ? Colors.blue[600]
                                                            : Colors.grey[600],
                                                        fontSize: 12,
                                                        fontFamily: 'Poppins',
                                                      ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
