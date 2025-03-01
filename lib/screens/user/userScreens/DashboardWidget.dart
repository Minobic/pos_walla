import 'package:flutter/material.dart';
import '../../../custom/SidebarHeader.dart';

class DashboardWidget extends StatefulWidget {
  final String userName;
  final String userRole;
  final int userId;
  const DashboardWidget({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userId,
  });

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  bool _isSidebarOpen = false;

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
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
            selectedMenuItem: 'Dashboard', // Highlight Dashboard
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
                    child: Center(
                      child: Image.asset(
                        'assets/images/Delivery_Boy.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
