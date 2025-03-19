import 'package:flutter/material.dart';
import '../../../custom/SidebarHeader.dart'; // Ensure this path is correct
import '../../../custom/AdminSidebar.dart'; // Ensure this path is correct
import '../../../custom/GradientButton.dart'; // Ensure this path is correct
import '../../../services/ApiService.dart'; // Ensure this path is correct

class EmployeeWidget extends StatefulWidget {
  const EmployeeWidget({Key? key}) : super(key: key);

  @override
  State<EmployeeWidget> createState() => _EmployeeWidgetState();
}

class _EmployeeWidgetState extends State<EmployeeWidget> {
  List<Map<String, dynamic>> _employees = [];
  bool _isSidebarOpen = false;

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
    try {
      final employees = await ApiService.fetchEmployees();
      setState(() {
        _employees = List<Map<String, dynamic>>.from(employees);
      });
    } catch (e) {
      print('Failed to fetch employees: $e');
    }
  }

  String _getInitials(String firstName, String lastName) {
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  Future<void> _updateEmployeeRole(int index, String newRole) async {
    final employee = _employees[index];
    try {
      await ApiService.updateEmployeeRole(employee['user_id'], newRole);
      setState(() {
        _employees[index]['role'] = newRole;
      });
    } catch (e) {
      print('Failed to update role: $e');
    }
  }

  Future<void> _updateEmployeeStatus(int index, String newStatus) async {
    final employee = _employees[index];
    try {
      await ApiService.updateEmployeeStatus(employee['user_id'], newStatus);
      setState(() {
        _employees[index]['status'] = newStatus;
      });
    } catch (e) {
      print('Failed to update status: $e');
    }
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white, // Set background color to white
          contentPadding: EdgeInsets.all(20),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center the content
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue,
                  child: Text(
                    _getInitials(employee['first_name'], employee['last_name']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${employee['first_name']} ${employee['last_name']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${employee['role']}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 40.0), // Adjust the left padding as needed
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                          'Employee ID:', employee['user_id'].toString()),
                      _buildDetailRow('Email:', employee['email'].toString()),
                      _buildDetailRow('Contact:', employee['phone'].toString()),
                      _buildDetailRow(
                          'Salary:', '₹ ${employee['salary'].toString()}'),
                      _buildDetailRow('Address:',
                          (employee['address'] ?? 'N/A').toString()),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Implement delete functionality here
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 100, // Fixed width for labels
            child: Text(
              '$label ',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
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
            selectedMenuItem: 'Employees',
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
                    padding: const EdgeInsets.all(25),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Employee List Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Employee List',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GradientButton(
                                  onPressed: () {},
                                  text: 'Add Employee',
                                  width: 160,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Employee Table
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Table Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 15,
                                      ),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Color(0xFFEEEEEE),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: const [
                                          SizedBox(width: 50),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Name',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Role',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Spacer(),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Status',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Spacer(),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'About',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Table Content
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _employees.length,
                                        itemBuilder: (context, index) {
                                          final employee = _employees[index];
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                // Initials Circle
                                                CircleAvatar(
                                                  radius: 25,
                                                  backgroundColor: Colors.blue,
                                                  child: Text(
                                                    _getInitials(
                                                      employee['first_name'],
                                                      employee['last_name'],
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                // Name
                                                Expanded(
                                                  flex: 2,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 10),
                                                    child: Text(
                                                      '${employee['first_name']} ${employee['last_name']}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Role Dropdown
                                                Expanded(
                                                  flex: 2,
                                                  child:
                                                      DropdownButtonFormField<
                                                          String>(
                                                    value: employee['role'],
                                                    onChanged: (newValue) {
                                                      _updateEmployeeRole(
                                                          index, newValue!);
                                                    },
                                                    decoration: InputDecoration(
                                                      enabledBorder:
                                                          UnderlineInputBorder(
                                                        borderSide:
                                                            BorderSide.none,
                                                      ),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                        borderSide:
                                                            BorderSide.none,
                                                      ),
                                                    ),
                                                    items: <String>[
                                                      'cashier',
                                                      'manager',
                                                      'admin'
                                                    ].map<
                                                            DropdownMenuItem<
                                                                String>>(
                                                        (String value) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: value,
                                                        child: Text(
                                                            value.capitalize()),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                                Spacer(),
                                                // Status Dropdown
                                                Expanded(
                                                  flex: 2,
                                                  child:
                                                      DropdownButtonFormField<
                                                          String>(
                                                    value: employee['status'],
                                                    onChanged: (newValue) {
                                                      _updateEmployeeStatus(
                                                          index, newValue!);
                                                    },
                                                    decoration: InputDecoration(
                                                      enabledBorder:
                                                          UnderlineInputBorder(
                                                        borderSide:
                                                            BorderSide.none,
                                                      ),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                        borderSide:
                                                            BorderSide.none,
                                                      ),
                                                    ),
                                                    items: <String>[
                                                      'active',
                                                      'pending',
                                                      'rejected',
                                                      'inactive'
                                                    ].map<
                                                            DropdownMenuItem<
                                                                String>>(
                                                        (String value) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: value,
                                                        child: Text(
                                                            value.capitalize()),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                                Spacer(),
                                                // More Details Button
                                                Expanded(
                                                  flex: 2,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      _showEmployeeDetails(
                                                          employee);
                                                    },
                                                    child: const Text(
                                                      'More Details',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF0099E5),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 8,
                                                      ),
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
                          ],
                        ),
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
