// BarcodeGenerator.dart
import 'package:flutter/material.dart';

class BarcodeGenerator extends StatefulWidget {
  @override
  _BarcodeGeneratorState createState() => _BarcodeGeneratorState();
}

class _BarcodeGeneratorState extends State<BarcodeGenerator> {
  final TextEditingController _searchController = TextEditingController();
  String _sortValue = 'Recently';

  List<Map<String, dynamic>> products = [
    {
      "pid": "55",
      "name": "Tomato",
      "batch": "Tomato001",
      "barcode": "125236556478",
      "mrp": 500,
      "sellPrice": 500,
    },
    {
      "pid": "100",
      "name": "Potato",
      "batch": "potato001",
      "barcode": "585698582517",
      "mrp": 1000,
      "sellPrice": 1000,
    },
    {
      "pid": "55",
      "name": "Chips",
      "batch": "Chips001",
      "barcode": "125365241589",
      "mrp": 500,
      "sellPrice": 500,
    },
    {
      "pid": "55",
      "name": "Chips",
      "batch": "Chips002",
      "barcode": "125365241589",
      "mrp": 1000,
      "sellPrice": 1000,
    },
    {
      "pid": "64",
      "name": "ABCD",
      "batch": "ABCD...",
      "barcode": "525635254152",
      "mrp": 500,
      "sellPrice": 500,
    },
    {
      "pid": "152",
      "name": "Soap",
      "batch": "Sandalwood...",
      "barcode": "89956869854",
      "mrp": 1000,
      "sellPrice": 1000,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Color(0xFF2D2D2D),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'POS WALLA',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildSidebarItem(Icons.dashboard, 'Dashboard'),
                _buildSidebarItem(Icons.category, 'Categories'),
                _buildSidebarItem(Icons.shopping_bag, 'Products'),
                _buildSidebarItem(Icons.inventory, 'Inventory'),
                _buildSidebarItem(Icons.receipt_long, 'Billing'),
                _buildSidebarItem(Icons.qr_code, 'Generate Barcode'),
                _buildSidebarItem(Icons.list_alt, 'Barcode List',
                    isSelected: true),
                Spacer(),
                _buildSidebarItem(Icons.person, 'Profile'),
                _buildSidebarItem(Icons.settings, 'Settings'),
                _buildSidebarItem(Icons.help, 'Help'),
                _buildSidebarItem(Icons.logout, 'Log Out'),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blue.shade700],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(color: Colors.white, fontSize: 24),
                          ),
                          Text(
                            'Let\'s take a detailed look at financial situation today',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Olivia Wilson',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                'Cashier',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          SizedBox(width: 10),
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Colors.blue),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Search and Generate Section
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.add),
                        label: Text('Generate barcode'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Table Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Barcode Table',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text('Sort by'),
                          SizedBox(width: 10),
                          DropdownButton<String>(
                            value: _sortValue,
                            items: ['Recently']
                                .map((String value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() => _sortValue = newValue);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Table
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(10)),
                          ),
                          child: _buildTableHeader(),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _buildTableRow(product);
                          },
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Show All Products'),
                              Icon(Icons.keyboard_arrow_down),
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

  Widget _buildSidebarItem(IconData icon, String title,
      {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey,
        ),
      ),
      selected: isSelected,
      onTap: () {},
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Row(
        children: [
          Expanded(
              child: Text('P.ID',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Product Name',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Product Batch',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Barcode',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              child: Text('MRP',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              child: Text('Sell price',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              child: Text('No. of Labels',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              child: Text('Action',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Row(
          children: [
            Expanded(child: Text(product['pid'])),
            Expanded(flex: 2, child: Text(product['name'])),
            Expanded(flex: 2, child: Text(product['batch'])),
            Expanded(flex: 2, child: Text(product['barcode'])),
            Expanded(child: Text('₹ ${product['mrp']}')),
            Expanded(child: Text('₹ ${product['sellPrice']}')),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                height: 30,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: IconButton(
                icon: Icon(Icons.print, color: Colors.blue),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
