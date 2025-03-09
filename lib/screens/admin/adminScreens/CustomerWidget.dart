import 'package:flutter/material.dart';
import '../../../custom/SidebarHeader.dart';
import '../../../custom/AdminSidebar.dart';
import '../../../services/ApiService.dart'; // Import your ApiService
import 'package:intl/intl.dart';

class CustomerWidget extends StatefulWidget {
  const CustomerWidget({Key? key}) : super(key: key);

  @override
  State<CustomerWidget> createState() => _CustomerWidgetState();
}

class _CustomerWidgetState extends State<CustomerWidget> {
  String _sortBy = 'Recently';
  bool _isSidebarOpen = false;

  List<dynamic> _customers = [];
  Map<String, dynamic>? _selectedCustomer;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      final customers = await ApiService.fetchCustomers();
      setState(() {
        _customers = customers;
      });
    } catch (e) {
      print('Failed to fetch customers: $e');
    }
  }

  Future<void> _fetchCustomerDetails(int customerId) async {
    try {
      final customer = await ApiService.fetchCustomerDetails(customerId);
      final transactions =
          await ApiService.fetchCustomerTransactions(customerId);

      setState(() {
        _selectedCustomer = customer;
        _transactions = transactions;
      });

      _sortTransactions(); // Sort transactions after fetching
    } catch (e) {
      print('Failed to fetch customer details: $e');
    }
  }

  void _sortTransactions() {
    if (_sortBy == 'Recently') {
      _transactions.sort((a, b) => DateTime.parse(b['created_at'])
          .compareTo(DateTime.parse(a['created_at'])));
    } else if (_sortBy == 'Oldest') {
      _transactions.sort((a, b) => DateTime.parse(a['created_at'])
          .compareTo(DateTime.parse(b['created_at'])));
    } else if (_sortBy == 'Amount') {
      _transactions.sort((a, b) =>
          (b['total_amount'] as num).compareTo(a['total_amount'] as num));
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final timeFormat = DateFormat('HH:mm');
    final apiDateFormat =
        DateFormat('dd-MM-yyyy HH:mm:ss'); // Format for parsing API date

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
            selectedMenuItem: 'Customers',
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
                        // Customer list card
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
                                        'Customer',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(Icons.more_horiz),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _customers.length,
                                      itemBuilder: (context, index) {
                                        final customer = _customers[index];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor:
                                                    Colors.blue[100],
                                                child: Icon(
                                                  Icons.person,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              Text(
                                                customer['customer_name'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Spacer(),
                                              ElevatedButton(
                                                onPressed: () {
                                                  _fetchCustomerDetails(
                                                      customer['customer_id']);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blue[500],
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                ),
                                                child: const Text('Detail'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.expand_more),
                                      label: const Text('Show All My Customer'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue,
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
                                                _sortTransactions(); // Sort transactions when the sort criteria changes
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
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Card(
                                              color: Colors.white,
                                              elevation: 2,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(15),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const SizedBox(height: 20),
                                                    // Avatar
                                                    CircleAvatar(
                                                      radius: 40,
                                                      backgroundColor:
                                                          Colors.blue[100],
                                                      child: Text(
                                                        _selectedCustomer !=
                                                                null
                                                            ? _selectedCustomer![
                                                                'customer_name'][0]
                                                            : 'C', // Initials of the name
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          color:
                                                              Colors.blue[700],
                                                          fontSize: 30,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 30),
                                                    // Customer Name
                                                    Text(
                                                      _selectedCustomer != null
                                                          ? _selectedCustomer![
                                                              'customer_name']
                                                          : 'Customer Name',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color: Colors.blue[700],
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    // Mobile Number
                                                    Text(
                                                      _selectedCustomer != null
                                                          ? 'Mobile: ${_selectedCustomer!['customer_mobile']}'
                                                          : 'Mobile: N/A',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 30),
                                                    // Total Amount
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 10,
                                                          horizontal: 15),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue[500],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            'Total Amount:',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Poppins',
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            _selectedCustomer !=
                                                                    null
                                                                ? '₹ ${_selectedCustomer!['total_amount']}'
                                                                : '₹ 0',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Poppins',
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Card(
                                              color: Colors.white,
                                              elevation: 2,
                                              child: Column(
                                                children: [
                                                  // Table Header
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 10,
                                                        horizontal: 15),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[500],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                    ),
                                                    child: const Row(
                                                      children: [
                                                        Expanded(
                                                          flex: 2,
                                                          child: Text(
                                                            'Date',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 1,
                                                          child: Text(
                                                            'Amount',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Transaction List
                                                  Expanded(
                                                    child: ListView.builder(
                                                      itemCount:
                                                          _transactions.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        final transaction =
                                                            _transactions[
                                                                index];
                                                        final date = apiDateFormat
                                                            .parse(transaction[
                                                                'created_at']);
                                                        return Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 15,
                                                                  horizontal:
                                                                      15),
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border(
                                                              bottom:
                                                                  BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .withOpacity(
                                                                        0.2),
                                                                width: 1,
                                                              ),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                flex: 2,
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      dateFormat
                                                                          .format(
                                                                              date),
                                                                      style:
                                                                          const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      timeFormat
                                                                          .format(
                                                                              date),
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .grey[600],
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 1,
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      '₹ ${transaction['total_amount'] ?? '0'}', // Adjust based on your API response
                                                                      style:
                                                                          const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      transaction[
                                                                              'payment_method'] ??
                                                                          'N/A', // Adjust based on your API response
                                                                      style:
                                                                          TextStyle(
                                                                        color: transaction['payment_method'] ==
                                                                                'Online'
                                                                            ? Colors.blue[600]
                                                                            : Colors.grey[600],
                                                                        fontSize:
                                                                            12,
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
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.expand_more),
                                      label: const Text(
                                          'Show All My Transactions'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue,
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
          ),
        ],
      ),
    );
  }
}
