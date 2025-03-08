import 'package:flutter/material.dart';
import '../../../custom/SidebarHeader.dart';
import '../../../custom/AdminSidebar.dart'; // Import the new AdminSidebar
import '../../../services/ApiService.dart'; // Import the ApiService
import 'TransactionWidget.dart'; // Import the TransactionWidget

class AdminDashboardWidget extends StatefulWidget {
  final String userName;
  final String userRole;
  final int userId;
  const AdminDashboardWidget({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userId,
  });

  @override
  State<AdminDashboardWidget> createState() => _AdminDashboardWidgetState();
}

class _AdminDashboardWidgetState extends State<AdminDashboardWidget> {
  bool _isSidebarOpen = false;
  List<dynamic> _employees = [];
  bool _isLoading = true; // Add a loading state
  String _selectedPeriod = 'daily'; // Define _selectedPeriod here

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true; // Set loading to true before fetching data
    });
    try {
      final employees = await ApiService.fetchEmployees();
      setState(() {
        _employees = employees;
        _isLoading = false; // Set loading to false after data is fetched
      });
    } catch (e) {
      print('Error fetching employees: $e');
      setState(() {
        _isLoading = false; // Set loading to false in case of an error
      });
    }
  }

  void _onTransactionItemPressed(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    // Navigate to TransactionWidget with the selected period
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TransactionWidget(selectedPeriod: _selectedPeriod),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            isSidebarOpen: _isSidebarOpen,
            toggleSidebar: _toggleSidebar,
            userName: widget.userName,
            userRole: widget.userRole,
            userId: widget.userId,
            selectedMenuItem: 'Admin Dashboard',
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
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main Content Sections
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // First Column: Transaction and Report
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      // Transaction Section
                                      Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                              right: 10, bottom: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                          ),
                                          padding: const EdgeInsets.all(15),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Transaction',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              const SizedBox(height: 15),
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    children: [
                                                      _buildTransactionItem(
                                                          'Daily',
                                                          'Current Date:',
                                                          _onTransactionItemPressed),
                                                      _buildTransactionItem(
                                                          'Weekly',
                                                          'Current Week:',
                                                          _onTransactionItemPressed),
                                                      _buildTransactionItem(
                                                          'Monthly',
                                                          'Current Month:',
                                                          _onTransactionItemPressed),
                                                      _buildTransactionItem(
                                                          'Quarterly',
                                                          'Current Quarter:',
                                                          _onTransactionItemPressed),
                                                      _buildTransactionItem(
                                                          'Yearly',
                                                          'Current Year:',
                                                          _onTransactionItemPressed),
                                                      _buildTransactionItem(
                                                          'Custom',
                                                          'Custom Date',
                                                          _onTransactionItemPressed),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Report Section
                                      Container(
                                        height: 80,
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                        ),
                                        padding: const EdgeInsets.all(15),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Report',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Current Year:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Icon(
                                                  Icons.report, // Report icon
                                                  size: 40,
                                                  color: Colors.blue,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Second Column: Employee and Customer
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      // Employee Section
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 10),
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF2196F3),
                                                Color(0xFF1976D2)
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(15),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Employee',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              const SizedBox(height: 15),
                                              Expanded(
                                                child: _isLoading
                                                    ? const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      )
                                                    : SingleChildScrollView(
                                                        child: Column(
                                                          children: _employees
                                                              .map((employee) =>
                                                                  _buildEmployeeItem(
                                                                      employee[
                                                                          'first_name'],
                                                                      employee[
                                                                          'last_name'],
                                                                      employee[
                                                                          'role']))
                                                              .toList(),
                                                        ),
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Customer Section
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                          ),
                                          padding: const EdgeInsets.all(15),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Customer',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              const SizedBox(height: 15),
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    children: [
                                                      _buildCustomerItem(
                                                          'Customer Sales Report',
                                                          Icons.bar_chart,
                                                          Colors.green),
                                                      _buildCustomerItem(
                                                          'Customer Analysis',
                                                          Icons.pie_chart,
                                                          Colors.green),
                                                    ],
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
                          ),
                        ],
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

  Widget _buildTransactionItem(
      String title, String subtitle, Function(String) onPressed) {
    return GestureDetector(
      onTap: () => onPressed(title.toLowerCase()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFD6E4FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.currency_rupee,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'Detail',
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
    );
  }

  Widget _buildEmployeeItem(String name, String lastName, String role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$name $lastName",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(
                          height: 4), // Add some space between name and role
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center, // Center the role text
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'Detail',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'Poppins',
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

  Widget _buildCustomerItem(String title, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
