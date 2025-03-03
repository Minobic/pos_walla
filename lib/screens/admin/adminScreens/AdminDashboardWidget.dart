import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class AdminDashboardWidget extends StatelessWidget {
  const AdminDashboardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 250,
            color: Color(0xFF2D2D2D),
            child: Column(
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Image.network(
                        'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/12-YHB1dFO5zr57yU2bv1X6QQsJQWZx5B.png',
                        height: 40,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'POS WALLA',
                        style: TextStyle(
                          color: Color(0xFF00B4D8),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu Items
                _buildMenuItem(context, Icons.dashboard, 'Dashboard', true),
                _buildMenuItem(context, Icons.bar_chart, 'Statistics', false),
                _buildMenuItem(context, Icons.description, 'Report', false),
                _buildMenuItem(
                    context, Icons.notifications, 'Notification', false),
                _buildMenuItem(context, Icons.settings, 'Settings', false),
                _buildMenuItem(context, Icons.logout, 'Logout', false),
                Spacer(),
                _buildMenuItem(context, Icons.account_circle, 'Account', false),
                _buildMenuItem(context, Icons.help, 'Help', false),
                SizedBox(height: 16),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search here...',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Color(0xFF0077B6)),
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Priority Member',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Dashboard Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Row(
                                children: [
                                  Text('View More'),
                                  Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Transaction Section
                              Expanded(
                                flex: 2,
                                child: _buildTransactionSection(),
                              ),
                              SizedBox(width: 16),
                              // Right Side Sections
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildEmployeeSection(),
                                    SizedBox(height: 16),
                                    _buildCustomerSection(),
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
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String title, bool isSelected) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.white.withOpacity(0.1) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: TextStyle(color: Colors.white),
        ),
        selected: isSelected,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/WelcomeWidget',
          );
        },
      ),
    );
  }

  Widget _buildTransactionSection() {
    final transactions = [
      {'title': 'Daily', 'period': 'Current Date:'},
      {'title': 'Weekly', 'period': 'Current Week:'},
      {'title': 'Monthly', 'period': 'Current Month:'},
      {'title': 'Quaterly', 'period': 'Current Quater:'},
      {'title': 'Yearly', 'period': 'Current Year:'},
      {'title': 'Custom', 'period': 'Custom Date'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...transactions
                .map((t) => _buildTransactionItem(t['title']!, t['period']!)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String title, String period) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFE3F2FD),
            child: Icon(Icons.currency_rupee, color: Color(0xFF0077B6)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(period, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text('Detail'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0077B6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSection() {
    final employees = [
      {'name': 'Akash', 'role': 'Cashier'},
      {'name': 'Neha', 'role': 'Manager'},
      {'name': 'Akash', 'role': 'Admin'},
      {'name': 'Akash', 'role': 'Cashier'},
    ];

    return Card(
      color: Color(0xFF00B4D8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...employees.map((e) => _buildEmployeeItem(e['name']!, e['role']!)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeItem(String name, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFF00B4D8)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            child: Text('Detail'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.trending_up, color: Colors.green),
              title: Text('Customer Sales Report'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: Colors.blue),
              title: Text('Customer Analysis'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
