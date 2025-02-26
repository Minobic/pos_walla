import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../custom/SidebarHeader.dart'; // Import the reusable components
import '../../../services/ApiService.dart'; // Import the ApiService
import '../../../custom/GradientButton.dart'; // Import the GradientButton
import '../../../custom/RedButton.dart'; // Import the RedButton

class BarcodeListWidget extends StatefulWidget {
  final String userName;
  final String userRole;

  const BarcodeListWidget({
    Key? key,
    required this.userName,
    required this.userRole,
  }) : super(key: key);

  @override
  State<BarcodeListWidget> createState() => _BarcodeListWidgetState();
}

class _BarcodeListWidgetState extends State<BarcodeListWidget> {
  bool _isSidebarOpen = false;
  List<dynamic> _barcodes = [];
  List<dynamic> _filteredBarcodes = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String _selectedSortOption = 'Default'; // Track selected sorting option
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchBarcodes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredBarcodes = _barcodes
          .where((barcode) => barcode['product_name']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
      _currentPage = 1; // Reset to the first page when searching
    });
  }

  Future<void> _fetchBarcodes() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });
    try {
      final barcodes = await ApiService.fetchBarcodes();
      setState(() {
        _barcodes = barcodes;
        _filteredBarcodes = barcodes;
      });
    } catch (e) {
      print('Failed to fetch barcodes: $e');
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _showAddBarcodeDialog() {
    final TextEditingController productNameController = TextEditingController();
    final TextEditingController barcodeHeaderController =
        TextEditingController();
    final TextEditingController barcodeNumberController =
        TextEditingController();
    final TextEditingController line1Controller = TextEditingController();
    final TextEditingController line2Controller = TextEditingController();

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
              'Add New Barcode',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: Container(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: productNameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: barcodeHeaderController,
                    decoration: InputDecoration(
                      labelText: 'Barcode Header',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: barcodeNumberController,
                    decoration: InputDecoration(
                      labelText: 'Barcode Number',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: line1Controller,
                    decoration: InputDecoration(
                      labelText: 'Line 1',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: line2Controller,
                    decoration: InputDecoration(
                      labelText: 'Line 2',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            RedButton(
              text: 'Cancel',
              onPressed: () {
                Navigator.of(context).pop();
              },
              width: 150,
            ),
            GradientButton(
              text: 'Add',
              onPressed: () async {
                try {
                  final newBarcode = await ApiService.addBarcode(
                    productName: productNameController.text,
                    barcodeHeader: barcodeHeaderController.text,
                    barcodeNumber: barcodeNumberController.text,
                    line1: line1Controller.text,
                    line2: line2Controller.text,
                  );
                  setState(() {
                    _barcodes.add(newBarcode);
                    _filteredBarcodes = _barcodes;
                  });
                  _fetchBarcodes();
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Failed to add barcode: $e');
                }
              },
              width: 150,
            ),
          ],
        );
      },
    );
  }

  void _showEditBarcodeDialog(dynamic barcode) {
    final TextEditingController productNameController =
        TextEditingController(text: barcode['product_name']);
    final TextEditingController barcodeHeaderController =
        TextEditingController(text: barcode['barcode_header']);
    final TextEditingController barcodeNumberController =
        TextEditingController(text: barcode['barcode_number']);
    final TextEditingController line1Controller =
        TextEditingController(text: barcode['line_1']);
    final TextEditingController line2Controller =
        TextEditingController(text: barcode['line_2']);

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
              'Edit Barcode',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: Container(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: productNameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: barcodeHeaderController,
                    decoration: InputDecoration(
                      labelText: 'Barcode Header',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: barcodeNumberController,
                    decoration: InputDecoration(
                      labelText: 'Barcode Number',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: line1Controller,
                    decoration: InputDecoration(
                      labelText: 'Line 1',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: line2Controller,
                    decoration: InputDecoration(
                      labelText: 'Line 2',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            RedButton(
              text: 'Cancel',
              onPressed: () {
                Navigator.of(context).pop();
              },
              width: 150,
            ),
            GradientButton(
              text: 'Update',
              onPressed: () async {
                try {
                  final updatedBarcode = await ApiService.updateBarcode(
                    barcodeId: barcode['barcode_id'],
                    barcodeNumber: barcodeNumberController.text,
                    productName: productNameController.text,
                    barcodeHeader: barcodeHeaderController.text,
                    line1: line1Controller.text,
                    line2: line2Controller.text,
                  );
                  setState(() {
                    int index = _barcodes.indexWhere(
                        (bc) => bc['barcode_id'] == barcode['barcode_id']);
                    if (index != -1) {
                      _barcodes[index] = updatedBarcode;
                      _filteredBarcodes = _barcodes;
                    }
                  });
                  _fetchBarcodes();
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Failed to update barcode: $e');
                }
              },
              width: 150,
            ),
          ],
        );
      },
    );
  }

  void _deleteBarcode(int barcodeId) async {
    final confirmDelete = await showDialog<bool>(
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
              'Confirm Delete',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: const Text('Are you sure you want to delete this barcode?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                textAlign: TextAlign.center,
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(160, 53),
              ),
            ),
            RedButton(
              text: 'Delete',
              onPressed: () => Navigator.of(context).pop(true),
              width: 150,
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await ApiService.deleteBarcode(barcodeId);
        setState(() {
          _barcodes.removeWhere((bc) => bc['barcode_id'] == barcodeId);
          _filteredBarcodes = _barcodes;
        });
      } catch (e) {
        print('Failed to delete barcode: $e');
      }
    }
  }

  List<dynamic> _getPaginatedBarcodes() {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _filteredBarcodes.length) {
      endIndex = _filteredBarcodes.length;
    }
    return _filteredBarcodes.sublist(startIndex, endIndex);
  }

  void _nextPage() {
    setState(() {
      if (_currentPage < (_filteredBarcodes.length / _itemsPerPage).ceil()) {
        _currentPage++;
      }
    });
  }

  void _previousPage() {
    setState(() {
      if (_currentPage > 1) {
        _currentPage--;
      }
    });
  }

  void _sortBarcodes(String sortOption) {
    setState(() {
      _selectedSortOption = sortOption;
      switch (sortOption) {
        case 'Recently Added':
          _filteredBarcodes
              .sort((a, b) => b['created_at'].compareTo(a['created_at']));
          break;
        case 'Product Name (A-Z)':
          _filteredBarcodes
              .sort((a, b) => a['product_name'].compareTo(b['product_name']));
          break;
        case 'Product Name (Z-A)':
          _filteredBarcodes
              .sort((a, b) => b['product_name'].compareTo(a['product_name']));
          break;
        default:
          _filteredBarcodes = List.from(_barcodes);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paginatedBarcodes = _getPaginatedBarcodes();

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            isSidebarOpen: _isSidebarOpen,
            toggleSidebar: _toggleSidebar,
            userName: widget.userName,
            userRole: widget.userRole,
            selectedMenuItem: 'Barcode List',
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search Barcode',
                              hintStyle: TextStyle(fontFamily: 'Poppins'),
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add New Barcode',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              )),
                          onPressed: _showAddBarcodeDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white,
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  const Center(
                                    child: Text(
                                      'Barcodes Table',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.29,
                                      child: PopupMenuButton<String>(
                                        icon: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text('Sort by - ',
                                                style: TextStyle(
                                                    fontFamily: 'Poppins')),
                                            Text(
                                              _selectedSortOption,
                                              style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const Icon(Icons.arrow_drop_down),
                                          ],
                                        ),
                                        onSelected: _sortBarcodes,
                                        itemBuilder: (BuildContext context) {
                                          return [
                                            'Default',
                                            'Recently Added',
                                            'Product Name (A-Z)',
                                            'Product Name (Z-A)',
                                          ].map((String option) {
                                            return PopupMenuItem<String>(
                                              value: option,
                                              child: Text(option),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white,
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF2196F3),
                                              Color(0xFF1976D2)
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(25),
                                            topRight: Radius.circular(25),
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'B.ID',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Product Name',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Barcode Header',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Barcode Number',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Line 1',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Line 2',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Action',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: _isLoading
                                            ? Center(
                                                child:
                                                    CircularProgressIndicator())
                                            : paginatedBarcodes.isEmpty
                                                ? Center(
                                                    child: Text(
                                                        'No barcodes yet.'))
                                                : ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    itemCount: paginatedBarcodes
                                                        .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final barcode =
                                                          paginatedBarcodes[
                                                              index];
                                                      return Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 5),
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade300),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              flex: 1,
                                                              child: Text(
                                                                barcode['barcode_id']
                                                                    .toString(),
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Text(
                                                                barcode[
                                                                    'product_name'],
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Text(
                                                                barcode[
                                                                    'barcode_header'],
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Text(
                                                                barcode[
                                                                    'barcode_number'],
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Text(
                                                                barcode['line_1'] ??
                                                                    'N/A',
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Text(
                                                                barcode['line_2'] ??
                                                                    'N/A',
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .edit,
                                                                        color: Colors
                                                                            .green),
                                                                    onPressed: () =>
                                                                        _showEditBarcodeDialog(
                                                                            barcode),
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .delete,
                                                                        color: Colors
                                                                            .red),
                                                                    onPressed: () =>
                                                                        _deleteBarcode(
                                                                            barcode['barcode_id']),
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
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _previousPage,
                          color: _currentPage == 1 ? Colors.grey : Colors.blue,
                        ),
                        Row(
                          children: [
                            const Text(
                              'Page ',
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: SizedBox(
                                width: 20,
                                child: TextField(
                                  controller: _pageController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: '$_currentPage',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  onSubmitted: (value) {
                                    final int totalPages =
                                        (_filteredBarcodes.length /
                                                _itemsPerPage)
                                            .ceil();
                                    final int pageNumber =
                                        int.tryParse(value) ?? _currentPage;

                                    if (pageNumber >= 1 &&
                                        pageNumber <= totalPages) {
                                      setState(() {
                                        _currentPage = pageNumber;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Please enter a valid page number between 1 and $totalPages.'),
                                        ),
                                      );
                                    }
                                    _pageController.clear();
                                  },
                                ),
                              ),
                            ),
                            Text(
                              ' of ${(_filteredBarcodes.length / _itemsPerPage).ceil()}',
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _nextPage,
                          color: _currentPage ==
                                  (_filteredBarcodes.length / _itemsPerPage)
                                      .ceil()
                              ? Colors.grey
                              : Colors.blue,
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
    );
  }
}
