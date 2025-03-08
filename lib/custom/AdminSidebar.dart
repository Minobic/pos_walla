import 'package:flutter/material.dart';

class AdminSidebar extends StatefulWidget {
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final String userName;
  final String userRole;
  final int userId;
  final String selectedMenuItem;

  const AdminSidebar({
    Key? key,
    required this.isSidebarOpen,
    required this.toggleSidebar,
    required this.userName,
    required this.userRole,
    required this.userId,
    required this.selectedMenuItem,
  }) : super(key: key);

  @override
  _AdminSidebarState createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  Widget _buildMenuItem(
      String title, IconData icon, bool isSelected, Function onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        color: isSelected ? Colors.blue : Colors.transparent,
      ),
      child: ListTile(
        leading: widget.isSidebarOpen
            ? Padding(
                padding: const EdgeInsets.only(left: 60.0),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white54,
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 14.0),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white54,
                ),
              ),
        title: widget.isSidebarOpen
            ? Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontFamily: 'Poppins',
                ),
              )
            : null,
        onTap: () => onTap(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isSidebarOpen ? 280 : 80,
      color: const Color(0xFF1F1F1F),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 50,
                  height: 50,
                ),
                if (widget.isSidebarOpen) const SizedBox(width: 10),
                if (widget.isSidebarOpen)
                  const Text(
                    'POS WALLA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMenuItem(
                    'Dashboard',
                    Icons.dashboard,
                    widget.selectedMenuItem == 'Admin Dashboard',
                    () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/adminDashboard',
                        arguments: {
                          'name': widget.userName,
                          'role': widget.userRole,
                          'userId': widget.userId,
                        },
                      );
                    },
                  ),
                  _buildMenuItem(
                    'Transactions',
                    Icons.payments_outlined,
                    widget.selectedMenuItem == 'Transactions',
                    () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/transactions',
                        arguments: {
                          'name': widget.userName,
                          'role': widget.userRole,
                          'userId': widget.userId,
                        },
                      );
                    },
                  ),
                  _buildMenuItem(
                    'Customers',
                    Icons.people,
                    widget.selectedMenuItem == 'Customers',
                    () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/customers',
                        arguments: {
                          'name': widget.userName,
                          'role': widget.userRole,
                          'userId': widget.userId,
                        },
                      );
                    },
                  ),
                  _buildMenuItem(
                    'Reports',
                    Icons.description,
                    widget.selectedMenuItem == 'Reports',
                    () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/reports',
                        arguments: {
                          'name': widget.userName,
                          'role': widget.userRole,
                          'userId': widget.userId,
                        },
                      );
                    },
                  ),
                  _buildMenuItem(
                    'Settings',
                    Icons.settings,
                    widget.selectedMenuItem == 'Settings',
                    () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/settings',
                        arguments: {
                          'name': widget.userName,
                          'role': widget.userRole,
                          'userId': widget.userId,
                        },
                      );
                    },
                  ),
                  _buildMenuItem(
                    'Notifications',
                    Icons.notifications,
                    widget.selectedMenuItem == 'Notifications',
                    () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/notifications',
                        arguments: {
                          'name': widget.userName,
                          'role': widget.userRole,
                          'userId': widget.userId,
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildMenuItem('Profile', Icons.person, false, () {}),
                  _buildMenuItem('Help', Icons.help, false, () {}),
                  _buildMenuItem('Log Out', Icons.logout, false, () {
                    Navigator.pushReplacementNamed(context, '/');
                  }),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            child: IconButton(
              icon: Icon(
                widget.isSidebarOpen
                    ? Icons.arrow_back_ios
                    : Icons.arrow_forward_ios,
                color: Colors.white,
              ),
              onPressed: widget.toggleSidebar,
            ),
          ),
        ],
      ),
    );
  }
}
