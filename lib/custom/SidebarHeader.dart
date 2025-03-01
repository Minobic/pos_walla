import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final String userName;
  final String userRole;
  final int userId; // Add userId parameter
  final String selectedMenuItem;

  const Sidebar({
    Key? key,
    required this.isSidebarOpen,
    required this.toggleSidebar,
    required this.userName,
    required this.userRole,
    required this.userId, // Add userId parameter
    required this.selectedMenuItem,
  }) : super(key: key);

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  // ... existing code ...

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
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/6-DaF4ALXMwQ5K3xfmVXVkZDiRg8JieP.png',
                  width: 40,
                  height: 40,
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
                    widget.selectedMenuItem == 'Dashboard',
                    () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/dashboard',
                        arguments: {
                          'name': widget.userName,
                          'role': widget.userRole,
                          'userId': widget.userId, // Pass userId
                        },
                      );
                    },
                  ),
                  _buildMenuItem(
                    'Categories',
                    Icons.category,
                    widget.selectedMenuItem == 'Categories',
                    () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/category',
                        arguments: {
                          'name': widget.userName,
                          'role': widget.userRole,
                          'userId': widget.userId, // Pass userId
                        },
                      );
                    },
                  ),
                  _buildMenuItem('Products', Icons.shopping_bag,
                      widget.selectedMenuItem == 'Products', () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/product',
                      arguments: {
                        'name': widget.userName,
                        'role': widget.userRole,
                        'userId': widget.userId, // Pass userId
                      },
                    );
                  }),
                  _buildMenuItem('ProductsBatch', Icons.auto_awesome_motion,
                      widget.selectedMenuItem == 'ProductsBatch', () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/productbatch',
                      arguments: {
                        'name': widget.userName,
                        'role': widget.userRole,
                        'userId': widget.userId, // Pass userId
                      },
                    );
                  }),
                  _buildMenuItem('Inventory', Icons.inventory,
                      widget.selectedMenuItem == "Inventory", () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/inventory',
                      arguments: {
                        'name': widget.userName,
                        'role': widget.userRole,
                        'userId': widget.userId, // Pass userId
                      },
                    );
                  }),
                  _buildMenuItem('Billing', Icons.receipt_long,
                      widget.selectedMenuItem == 'Billing', () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/billing',
                      arguments: {
                        'name': widget.userName,
                        'role': widget.userRole,
                        'userId': widget.userId, // Pass userId
                      },
                    );
                  }),
                  _buildMenuItem('Generate Barcode', Icons.qr_code,
                      widget.selectedMenuItem == 'Generate Barcode', () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/barcode',
                      arguments: {
                        'name': widget.userName,
                        'role': widget.userRole,
                        'userId': widget.userId, // Pass userId
                      },
                    );
                  }),
                  _buildMenuItem('Barcode List', Icons.list,
                      widget.selectedMenuItem == 'Barcode List', () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/barcodeList',
                      arguments: {
                        'name': widget.userName,
                        'role': widget.userRole,
                        'userId': widget.userId, // Pass userId
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                  _buildMenuItem('Profile', Icons.person, false, () {}),
                  _buildMenuItem('Settings', Icons.settings, false, () {}),
                  _buildMenuItem('Help', Icons.help, false, () {}),
                  _buildMenuItem('Log Out', Icons.logout, false, () {
                    Navigator.pushReplacementNamed(context, '/login');
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

class Header extends StatelessWidget {
  final String userName;
  final String userRole;

  const Header({
    Key? key,
    required this.userName,
    required this.userRole,
  }) : super(key: key);

  String getInitials(String fullName) {
    List<String> names = fullName.split(' ');
    String initials = '';
    for (String name in names) {
      if (name.isNotEmpty) {
        initials += name[0];
      }
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                'Let\'s take a detailed look at financial situation today',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {},
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    userRole,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Text(
                    getInitials(userName),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                ),
                offset: const Offset(
                    0, 50), // Adjust the offset to show below the circle
                onSelected: (String value) {
                  if (value == 'profile') {
                    // Handle Profile option
                    Navigator.pushNamed(context, '/profile');
                  } else if (value == 'logout') {
                    // Handle Logout option
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Text('Profile'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ];
                },
                color: Colors.white, // Set background color to white
              ),
            ],
          ),
        ],
      ),
    );
  }
}
