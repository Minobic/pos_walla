import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode_widget/barcode_widget.dart'; // Import the barcode widget package
import '../../../custom/SidebarHeader.dart'; // Import the reusable components
import '../../../services/ApiService.dart'; // Import the ApiService
import '../../../custom/GradientButton.dart'; // Import the GradientButton
import '../../../custom/RedButton.dart'; // Import the RedButton

class BarcodeGeneratorWidget extends StatefulWidget {
  final String userName;
  final String userRole;
  final int userId;

  const BarcodeGeneratorWidget({
    Key? key,
    required this.userName,
    required this.userRole,
    required this.userId,
  }) : super(key: key);

  @override
  State<BarcodeGeneratorWidget> createState() => _BarcodeGeneratorWidgetState();
}

class _BarcodeGeneratorWidgetState extends State<BarcodeGeneratorWidget> {
  bool _isSidebarOpen = false;
  List<dynamic> _barcodes = [];
  List<dynamic> _filteredBarcodes = [];
  List<dynamic> _products = []; // List to hold products
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _assignCodeController = TextEditingController();
  final TextEditingController _line1Controller = TextEditingController();
  final TextEditingController _line2Controller = TextEditingController();
  final TextEditingController _noOfLabelsController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String _selectedSortOption = 'Default'; // Track selected sorting option
  bool _isLoading = true; // Loading state
  int? _selectedProductId; // Track selected product ID
  String? selectedPrinter;
  String? selectedSize;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _generatedBarcode = '';
  Set<String> _existingProductNames = {};
  List<dynamic> _selectedBarcodes = []; // Track selected barcodes

  // New variables for MRP, SRP, and dropdown selections
  String? selectedLine1Option;
  String? selectedLine2Option;
  double? productMrp;
  double? productSrp;

  @override
  void initState() {
    super.initState();
    _fetchBarcodes();
    _fetchProducts(); // Fetch products on init
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
      _isLoading = true;
    });
    try {
      final barcodes = await ApiService.fetchBarcodes();
      setState(() {
        _barcodes = barcodes;
        _filteredBarcodes = barcodes;

        // Populate existing product names
        _existingProductNames = barcodes
            .map((barcode) =>
                barcode['product_name'] as String) // Cast to String
            .toSet();
      });
    } catch (e) {
      print('Failed to fetch barcodes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onProductSelected(int? productId) {
    if (productId != null) {
      final selectedProduct =
          _products.firstWhere((product) => product['product_id'] == productId);
      setState(() {
        productMrp = selectedProduct['mrp_price'];
        productSrp = selectedProduct['sale_price'];
        selectedLine1Option = null; // Reset the selected option
        selectedLine2Option = null; // Reset the selected option
        _productNameController.text = selectedProduct[
            'product_name']; // Set the product name in the controller
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _generateBarcode() {
    String newBarcode;
    bool isUnique;

    do {
      // Generate a random number within the 32-bit unsigned integer range
      int randomNumber = Random().nextInt(900000000) + 100000000;

      // Format the number to ensure it has 12 digits
      newBarcode = randomNumber.toString().padLeft(12, '0');

      // Check if the generated barcode is unique
      isUnique =
          _barcodes.every((barcode) => barcode['barcode_number'] != newBarcode);
    } while (!isUnique);

    setState(() {
      _generatedBarcode = newBarcode; // Assign the unique barcode number
      _assignCodeController.text =
          newBarcode; // Set the generated barcode to the Assigned Code field
    });
  }

  void _clearFields() {
    setState(() {
      _selectedProductId = null; // Clear the selected product
      _productNameController.clear(); // Clear the product name field
      _headerController.clear(); // Clear the header field
      _assignCodeController.clear(); // Clear the assigned code field
      _line1Controller.clear(); // Clear the line 1 field
      _line2Controller.clear(); // Clear the line 2 field
      _noOfLabelsController.clear(); // Clear the number of labels field
      _generatedBarcode = ''; // Reset the generated barcode
      _selectedBarcodes.clear(); // Clear selected barcodes
      selectedLine1Option = null; // Reset line 1 option
      selectedLine2Option = null; // Reset line 2 option
    });
  }

  Widget _buildDropdown(
      String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.white,
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onChanged: (value) {
        setState(() {}); // Trigger a rebuild to update the preview
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Poppins'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Future<void> _fetchProducts() async {
    try {
      final products =
          await ApiService.fetchProducts(); // Fetch products from API
      setState(() {
        // Filter out products that already have barcodes
        _products = products.where((product) {
          String productName =
              product['product_name'] as String; // Ensure this is a String
          bool exists = _existingProductNames.contains(productName);
          return !exists; // Keep products that do not exist in the barcodes
        }).toList();
      });
    } catch (e) {
      print('Failed to fetch products: $e');
    }
  }

  void _addBarcode() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        print('Product Name: ${_productNameController.text}'); // Debug print
        final newBarcode = await ApiService.addBarcode(
          productName: _productNameController.text,
          barcodeNumber: _assignCodeController.text,
          barcodeHeader: _headerController.text,
          line1: selectedLine1Option == 'Custom'
              ? _line1Controller.text
              : selectedLine1Option ?? '',
          line2: selectedLine2Option == 'Custom'
              ? _line2Controller.text
              : selectedLine2Option ?? '',
        );

        setState(() {
          _barcodes.add(newBarcode);
          _filteredBarcodes = List.from(_barcodes);
          // Retain the current values in the input fields
          _productNameController.text = newBarcode['product_name'];
          _headerController.text = newBarcode['barcode_header'];
          _assignCodeController.text = newBarcode['barcode_number'];
          _line1Controller.text = newBarcode['line_1'];
          _line2Controller.text = newBarcode['line_2'];
          _clearFields();
          _fetchBarcodes();
          _fetchProducts();
        });

        await _fetchBarcodes();
      } catch (e) {
        print('Failed to add barcode: $e');
      }
    }
  }

  void _showEditBarcodeDialog(dynamic barcode) {
    _productNameController.text = barcode['product_name'];
    _headerController.text = barcode['barcode_header'];
    _assignCodeController.text = barcode['barcode_number'];
    _line1Controller.text = barcode['line_1'];
    _line2Controller.text = barcode['line_2'];

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
                    readOnly: true,
                    controller: _productNameController,
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
                    controller: _headerController,
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
                    readOnly: true,
                    controller: _assignCodeController,
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
                    controller: _line1Controller,
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
                    controller: _line2Controller,
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
                Navigator.of(context).pop(); // Close the dialog
              },
              width: 150,
            ),
            GradientButton(
              text: 'Update',
              onPressed: () async {
                try {
                  final updatedBarcode = await ApiService.updateBarcode(
                    barcodeId: barcode['barcode_id'],
                    barcodeNumber: _assignCodeController.text,
                    productName: _productNameController.text,
                    barcodeHeader: _headerController.text,
                    line1: _line1Controller.text,
                    line2: _line2Controller.text,
                  );
                  setState(() {
                    // Update the barcode in the list
                    int index = _barcodes.indexWhere(
                        (b) => b['barcode_id'] == barcode['barcode_id']);
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
          _barcodes.removeWhere((b) => b['barcode_id'] == barcodeId);
          _filteredBarcodes = _barcodes;
          _selectedBarcodes.removeWhere((b) => b['barcode_id'] == barcodeId);
          _fetchBarcodes();
          _fetchProducts();
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
          _filteredBarcodes.sort((a, b) =>
              b['created_at'].compareTo(a['created_at'])); // Most recent first
          break;
        case 'Product Name (A-Z)':
          _filteredBarcodes.sort((a, b) =>
              a['product_name'].compareTo(b['product_name'])); // A-Z sorting
          break;
        case 'Product Name (Z-A)':
          _filteredBarcodes.sort((a, b) =>
              b['product_name'].compareTo(a['product_name'])); // Z-A sorting
          break;
        default:
          _filteredBarcodes = List.from(_barcodes); // Default order
          break;
      }
    });
  }

  void _showBarcodeInPrintContainer(dynamic barcode) {
    setState(() {
      _headerController.text = barcode['barcode_header'];
      _generatedBarcode = barcode['barcode_number'];
      _line1Controller.text = barcode['line_1'];
      _line2Controller.text = barcode['line_2'];
    });
  }

  Future<void> _printBarcode() async {
    final pdf = pw.Document();

    // Custom page format (width and height can be adjusted as needed)
    final double pageWidth = 210 * PdfPageFormat.mm; // Example width
    final double pageHeight = 297 * PdfPageFormat.mm; // Example height
    final double margin = 10; // Set a fixed margin

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat(pageWidth, pageHeight),
      buildBackground: (context) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(
            color: PdfColors.white,
          ),
        );
      },
    );

    // Determine the layout based on the selected printer and size
    double barcodeWidth, barcodeHeight;
    int labelsPerRow, labelsPerColumn;

    if (selectedPrinter == 'Label Printer') {
      // Layout for Label Printer
      if (selectedSize == '2 Labels (50*25 mm)') {
        barcodeWidth = 50 * PdfPageFormat.mm;
        barcodeHeight = 25 * PdfPageFormat.mm;
        labelsPerRow = 1;
        labelsPerColumn = 2;
      } else {
        // '1 Labels (100*50 cm)'
        barcodeWidth = 100 * PdfPageFormat.mm;
        barcodeHeight = 50 * PdfPageFormat.mm;
        labelsPerRow = 1;
        labelsPerColumn = 1;
      }
    } else {
      // Layout for Regular Printer
      if (selectedSize == '65 Labels (38*21 mm)') {
        barcodeWidth = 38 * PdfPageFormat.mm;
        barcodeHeight = 21 * PdfPageFormat.mm;
      } else if (selectedSize == '48 Labels (48*24 mm)') {
        barcodeWidth = 48 * PdfPageFormat.mm;
        barcodeHeight = 24 * PdfPageFormat.mm;
      } else if (selectedSize == '24 Labels (64*34 mm)') {
        barcodeWidth = 64 * PdfPageFormat.mm;
        barcodeHeight = 34 * PdfPageFormat.mm;
      } else {
        // '12 Labels (100*44 mm)'
        barcodeWidth = 100 * PdfPageFormat.mm;
        barcodeHeight = 44 * PdfPageFormat.mm;
      }

      // Calculate the number of labels per row and column only for Regular Printer
      labelsPerRow = ((pageWidth - 2 * margin) / barcodeWidth).floor();
      labelsPerColumn = ((pageHeight - 2 * margin) / barcodeHeight).floor();
    }

    // Calculate scaling factor for text size
    double baseBarcodeWidth = 100 * PdfPageFormat.mm;
    double baseBarcodeHeight = 50 * PdfPageFormat.mm;
    double scaleFactor =
        (barcodeWidth * barcodeHeight) / (baseBarcodeWidth * baseBarcodeHeight);

    // Calculate the total number of labels available
    int totalLabels = labelsPerRow * labelsPerColumn;

    // Distribute the selected barcodes evenly across the labels
    List<dynamic> distributedBarcodes = [];
    int barcodesPerLabel = (totalLabels / _selectedBarcodes.length).floor();
    int remainingLabels = totalLabels % _selectedBarcodes.length;

    for (int i = 0; i < _selectedBarcodes.length; i++) {
      int count = barcodesPerLabel + (i < remainingLabels ? 1 : 0);
      for (int j = 0; j < count; j++) {
        distributedBarcodes.add(_selectedBarcodes[i]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (context) {
          return [
            pw.Padding(
              padding:
                  pw.EdgeInsets.all(margin), // Apply margin to the entire page
              child: pw.Column(
                children: [
                  for (int row = 0; row < labelsPerColumn; row++)
                    pw.Row(
                      children: List.generate(
                        labelsPerRow,
                        (col) {
                          // Calculate available space for text and barcode
                          double availableHeight =
                              barcodeHeight - 30; // Adjusted for text
                          double availableWidth = barcodeWidth - 10;

                          // Calculate font size based on available space
                          double headerFontSize = 10 * scaleFactor;
                          double lineFontSize = 8 * scaleFactor;

                          // Ensure the font size is not too small
                          headerFontSize = headerFontSize.clamp(10, 18);
                          lineFontSize = lineFontSize.clamp(10, 17);

                          // Determine the barcode to print
                          int barcodeIndex = row * labelsPerRow + col;
                          if (barcodeIndex < distributedBarcodes.length) {
                            dynamic selectedBarcode =
                                distributedBarcodes[barcodeIndex];

                            return pw.Container(
                              width: barcodeWidth,
                              height: barcodeHeight +
                                  30, // Increased height to fit text
                              margin: const pw.EdgeInsets.all(
                                  2), // Small margins between labels
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    selectedBarcode['barcode_header'].isEmpty
                                        ? 'Header'
                                        : selectedBarcode['barcode_header'],
                                    style: pw.TextStyle(
                                        fontSize: headerFontSize,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.BarcodeWidget(
                                    barcode: pw.Barcode.code128(),
                                    data: selectedBarcode['barcode_number'],
                                    height: availableHeight *
                                        0.7, // Adjusted height for barcode
                                    width: availableWidth,
                                    textStyle: pw.TextStyle(
                                      fontSize:
                                          lineFontSize, // Adjust this value to increase the font size
                                      fontWeight: pw.FontWeight
                                          .bold, // Optional: Make the text bold
                                    ),
                                  ),
                                  pw.SizedBox(
                                      height: 2), // Add space between elements
                                  pw.Text(
                                    selectedBarcode['line_1'].isEmpty
                                        ? 'Line 1 content'
                                        : selectedBarcode['line_1'],
                                    style: pw.TextStyle(fontSize: lineFontSize),
                                  ),
                                  pw.Text(
                                    selectedBarcode['line_2'].isEmpty
                                        ? 'Line 2 content'
                                        : selectedBarcode['line_2'],
                                    style: pw.TextStyle(fontSize: lineFontSize),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return pw
                                .Container(); // Empty container if no more barcodes
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }

  Future<void> _saveAsPdf() async {
    final pdf = pw.Document();

    // Custom page format (width and height can be adjusted as needed)
    final double pageWidth = 210 * PdfPageFormat.mm; // Example width
    final double pageHeight = 297 * PdfPageFormat.mm; // Example height
    final double margin = 10; // Set a fixed margin

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat(pageWidth, pageHeight),
      buildBackground: (context) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(
            color: PdfColors.white,
          ),
        );
      },
    );

    // Determine the layout based on the selected printer and size
    double barcodeWidth, barcodeHeight;
    int labelsPerRow, labelsPerColumn;

    if (selectedPrinter == 'Label Printer') {
      // Layout for Label Printer
      if (selectedSize == '2 Labels (50*25 mm)') {
        barcodeWidth = 50 * PdfPageFormat.mm;
        barcodeHeight = 25 * PdfPageFormat.mm;
        labelsPerRow = 2;
        labelsPerColumn = 1;
      } else {
        // '1 Labels (100*50 cm)'
        barcodeWidth = 100 * PdfPageFormat.mm;
        barcodeHeight = 50 * PdfPageFormat.mm;
        labelsPerRow = 1;
        labelsPerColumn = 1;
      }
    } else {
      // Layout for Regular Printer
      if (selectedSize == '65 Labels (38*21 mm)') {
        barcodeWidth = 38 * PdfPageFormat.mm;
        barcodeHeight = 21 * PdfPageFormat.mm;
      } else if (selectedSize == '48 Labels (48*24 mm)') {
        barcodeWidth = 48 * PdfPageFormat.mm;
        barcodeHeight = 24 * PdfPageFormat.mm;
      } else if (selectedSize == '24 Labels (64*34 mm)') {
        barcodeWidth = 64 * PdfPageFormat.mm;
        barcodeHeight = 34 * PdfPageFormat.mm;
      } else {
        // '12 Labels (100*44 mm)'
        barcodeWidth = 100 * PdfPageFormat.mm;
        barcodeHeight = 44 * PdfPageFormat.mm;
      }

      // Calculate the number of labels per row and column only for Regular Printer
      labelsPerRow = ((pageWidth - 2 * margin) / barcodeWidth).floor();
      labelsPerColumn = ((pageHeight - 2 * margin) / barcodeHeight).floor();
    }

    // Calculate scaling factor for text size
    double baseBarcodeWidth = 100 * PdfPageFormat.mm;
    double baseBarcodeHeight = 50 * PdfPageFormat.mm;
    double scaleFactor =
        (barcodeWidth * barcodeHeight) / (baseBarcodeWidth * baseBarcodeHeight);

    // Calculate the total number of labels available
    int totalLabels = labelsPerRow * labelsPerColumn;

    // Distribute the selected barcodes evenly across the labels
    List<dynamic> distributedBarcodes = [];
    int barcodesPerLabel = (totalLabels / _selectedBarcodes.length).floor();
    int remainingLabels = totalLabels % _selectedBarcodes.length;

    for (int i = 0; i < _selectedBarcodes.length; i++) {
      int count = barcodesPerLabel + (i < remainingLabels ? 1 : 0);
      for (int j = 0; j < count; j++) {
        distributedBarcodes.add(_selectedBarcodes[i]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (context) {
          return [
            pw.Padding(
              padding:
                  pw.EdgeInsets.all(margin), // Apply margin to the entire page
              child: pw.Column(
                children: [
                  for (int row = 0; row < labelsPerColumn; row++)
                    pw.Row(
                      children: List.generate(
                        labelsPerRow,
                        (col) {
                          // Calculate available space for text and barcode
                          double availableHeight =
                              barcodeHeight - 30; // Adjusted for text
                          double availableWidth = barcodeWidth - 10;

                          // Calculate font size based on available space
                          double headerFontSize = 10 * scaleFactor;
                          double lineFontSize = 8 * scaleFactor;

                          // Ensure the font size is not too small
                          headerFontSize = headerFontSize.clamp(10, 18);
                          lineFontSize = lineFontSize.clamp(10, 17);

                          // Determine the barcode to print
                          int barcodeIndex = row * labelsPerRow + col;
                          if (barcodeIndex < distributedBarcodes.length) {
                            dynamic selectedBarcode =
                                distributedBarcodes[barcodeIndex];

                            return pw.Container(
                              width: barcodeWidth,
                              height: barcodeHeight +
                                  30, // Increased height to fit text
                              margin: const pw.EdgeInsets.all(
                                  2), // Small margins between labels
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    selectedBarcode['barcode_header'].isEmpty
                                        ? 'Header'
                                        : selectedBarcode['barcode_header'],
                                    style: pw.TextStyle(
                                        fontSize: headerFontSize,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.BarcodeWidget(
                                    barcode: pw.Barcode.code128(),
                                    data: selectedBarcode['barcode_number'],
                                    height: availableHeight *
                                        0.7, // Adjusted height for barcode
                                    width: availableWidth,
                                    textStyle: pw.TextStyle(
                                      fontSize:
                                          lineFontSize, // Adjust this value to increase the font size
                                      fontWeight: pw.FontWeight
                                          .bold, // Optional: Make the text bold
                                    ),
                                  ),
                                  pw.SizedBox(
                                      height: 2), // Add space between elements
                                  pw.Text(
                                    selectedBarcode['line_1'].isEmpty
                                        ? 'Line 1 content'
                                        : selectedBarcode['line_1'],
                                    style: pw.TextStyle(fontSize: lineFontSize),
                                  ),
                                  pw.Text(
                                    selectedBarcode['line_2'].isEmpty
                                        ? 'Line 2 content'
                                        : selectedBarcode['line_2'],
                                    style: pw.TextStyle(fontSize: lineFontSize),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return pw
                                .Container(); // Empty container if no more barcodes
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/barcode.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to $path')),
    );
  }

  // Inside the _BarcodeGeneratorWidgetState class

  @override
  Widget build(BuildContext context) {
    final paginatedBarcodes = _getPaginatedBarcodes();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Sidebar(
            isSidebarOpen: _isSidebarOpen,
            toggleSidebar: _toggleSidebar,
            userName: widget.userName,
            userRole: widget.userRole,
            userId: widget.userId,
            selectedMenuItem: 'Generate Barcode',
          ),
          Expanded(
            child: Column(
              children: [
                Header(
                  userName: widget.userName,
                  userRole: widget.userRole,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Form
                              Expanded(
                                child: Card(
                                  elevation: 1,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              // In the build method, ensure the DropdownButtonFormField for product selection calls _onProductSelected
                                              Expanded(
                                                child: DropdownButtonFormField<
                                                    int>(
                                                  dropdownColor: Colors.white,
                                                  value: _selectedProductId,
                                                  decoration: InputDecoration(
                                                    labelText: 'Product name',
                                                    labelStyle: TextStyle(
                                                        fontFamily: 'Poppins'),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .grey.shade300),
                                                    ),
                                                  ),
                                                  items:
                                                      _products.map((product) {
                                                    return DropdownMenuItem<
                                                        int>(
                                                      value:
                                                          product['product_id'],
                                                      child: Text(product[
                                                          'product_name']),
                                                      onTap: () {
                                                        _onProductSelected(product[
                                                            'product_id']); // Call the method to set the product details
                                                      },
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _selectedProductId =
                                                          value;
                                                      _generateBarcode();
                                                    });
                                                  },
                                                  validator: (value) => value ==
                                                          null
                                                      ? 'Please select a product'
                                                      : null,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: _buildInputField(
                                                    'Header',
                                                    _headerController),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildInputField(
                                                    'Assigned Code',
                                                    _assignCodeController,
                                                    readOnly: true),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  dropdownColor: Colors.white,
                                                  value: selectedLine1Option,
                                                  decoration: InputDecoration(
                                                    labelText: 'Line 1',
                                                    labelStyle: TextStyle(
                                                        fontFamily: 'Poppins'),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .grey.shade300),
                                                    ),
                                                  ),
                                                  items: [
                                                    'MRP: ${productMrp?.toStringAsFixed(2) ?? ''}',
                                                    'SRP: ${productSrp?.toStringAsFixed(2) ?? ''}',
                                                    'Custom'
                                                  ].map((String option) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: option,
                                                      child: Text(option),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      selectedLine1Option =
                                                          value;
                                                      if (value == 'Custom') {
                                                        _line1Controller
                                                            .clear(); // Clear the controller for custom input
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Custom input field for Line 1
                                          if (selectedLine1Option == 'Custom')
                                            SizedBox(height: 16),
                                          if (selectedLine1Option == 'Custom')
                                            TextField(
                                              controller: _line1Controller,
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Enter Custom Line 1',
                                                labelStyle: TextStyle(
                                                    fontFamily: 'Poppins'),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade300),
                                                ),
                                              ),
                                            ),
                                          SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildInputField(
                                                    'No. of Labels',
                                                    _noOfLabelsController),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  dropdownColor: Colors.white,
                                                  value: selectedLine2Option,
                                                  decoration: InputDecoration(
                                                    labelText: 'Line 2',
                                                    labelStyle: TextStyle(
                                                        fontFamily: 'Poppins'),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .grey.shade300),
                                                    ),
                                                  ),
                                                  items: [
                                                    'MRP: ${productMrp?.toStringAsFixed(2) ?? ''}',
                                                    'SRP: ${productSrp?.toStringAsFixed(2) ?? ''}',
                                                    'Custom'
                                                  ].map((String option) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: option,
                                                      child: Text(option),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      selectedLine2Option =
                                                          value;
                                                      if (value == 'Custom') {
                                                        _line2Controller
                                                            .clear(); // Clear the controller for custom input
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Custom input field for Line 2
                                          if (selectedLine2Option == 'Custom')
                                            SizedBox(height: 16),
                                          if (selectedLine2Option == 'Custom')
                                            TextField(
                                              controller: _line2Controller,
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Enter Custom Line 2',
                                                labelStyle: TextStyle(
                                                    fontFamily: 'Poppins'),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade300),
                                                ),
                                              ),
                                            ),
                                          SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: RedButton(
                                                  text: 'Clear',
                                                  onPressed: _clearFields,
                                                  width: double.infinity,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: GradientButton(
                                                  text: "Add Barcode",
                                                  onPressed: () {
                                                    _addBarcode();
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 24),
                              // Right Preview
                              Expanded(
                                child: Card(
                                  elevation: 1,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Left Column for Dropdowns
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('Printer :'),
                                                SizedBox(height: 8),
                                                _buildDropdown(
                                                  selectedPrinter,
                                                  [
                                                    'Regular Printer',
                                                    'Label Printer'
                                                  ],
                                                  (value) {
                                                    setState(() {
                                                      selectedPrinter = value!;
                                                      // Reset selectedSize based on the new printer selection
                                                      if (selectedPrinter ==
                                                          'Label Printer') {
                                                        selectedSize =
                                                            '2 Labels (50*25 mm)'; // Default size for Label Printer
                                                      } else {
                                                        selectedSize =
                                                            '65 Labels (38*21 mm)'; // Default size for Regular Printer
                                                      }
                                                    });
                                                  },
                                                ),
                                                SizedBox(height: 24),
                                                Text('Size :'),
                                                SizedBox(height: 8),
                                                _buildDropdown(
                                                  selectedSize,
                                                  selectedPrinter ==
                                                          'Label Printer'
                                                      ? [
                                                          '2 Labels (50*25 mm)',
                                                          '1 Labels (100*50 mm)'
                                                        ]
                                                      : [
                                                          '65 Labels (38*21 mm)',
                                                          '48 Labels (48*24 mm)',
                                                          '24 Labels (64*34 mm)',
                                                          '12 Labels (100*44 mm)'
                                                        ],
                                                  (value) => setState(() =>
                                                      selectedSize = value!),
                                                ),
                                                SizedBox(height: 17.5),
                                                Container(
                                                  width:
                                                      200, // Set the desired width for the button
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Color(0xFF2196F3),
                                                        Color(0xFF1976D2)
                                                      ],
                                                      begin:
                                                          Alignment.centerLeft,
                                                      end:
                                                          Alignment.centerRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  child: TextButton.icon(
                                                    icon: const Icon(
                                                        Icons.picture_as_pdf,
                                                        color: Colors.white),
                                                    label: Text(
                                                      'Save as PDF',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                    onPressed: _saveAsPdf,
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 20,
                                                        vertical: 20,
                                                      ),
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      shadowColor:
                                                          Colors.transparent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 24),
                                          // Right Column for Barcode Preview
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                _headerController.text.isEmpty
                                                    ? 'Header'
                                                    : _headerController.text,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              BarcodeWidget(
                                                barcode: Barcode.code128(),
                                                data: _generatedBarcode,
                                                drawText: false,
                                                height: 100,
                                                width: 200,
                                              ),
                                              Text(_generatedBarcode),
                                              Text(_line1Controller.text.isEmpty
                                                  ? 'Line 1 content'
                                                  : _line1Controller.text),
                                              Text(_line2Controller.text.isEmpty
                                                  ? 'Line 2 content'
                                                  : _line2Controller.text),
                                              SizedBox(height: 4),
                                              Container(
                                                width:
                                                    200, // Set the desired width for the button
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xFF2196F3),
                                                      Color(0xFF1976D2)
                                                    ],
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                                child: TextButton.icon(
                                                  icon: const Icon(Icons.print,
                                                      color: Colors.white),
                                                  label: Text(
                                                    'Print Barcode',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                  onPressed: _printBarcode,
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 20,
                                                      vertical: 20,
                                                    ),
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    shadowColor:
                                                        Colors.transparent,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search Barcode',
                                      hintStyle:
                                          TextStyle(fontFamily: 'Poppins'),
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
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
                                        // Dropdown for sorting
                                        Center(
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.29,
                                            child: PopupMenuButton<String>(
                                              color: Colors.white,
                                              icon: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Text('Sort by - ',
                                                      style: TextStyle(
                                                          fontFamily:
                                                              'Poppins')),
                                                  Text(
                                                    _selectedSortOption,
                                                    style: const TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  const Icon(
                                                      Icons.arrow_drop_down),
                                                ],
                                              ),
                                              onSelected: _sortBarcodes,
                                              itemBuilder:
                                                  (BuildContext context) {
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
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
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
                                          // Fixed Header with Gradient
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
                                                    'Barcode ID',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Icon(
                                                    Icons.print,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Scrollable Data
                                          _isLoading
                                              ? Center(
                                                  child:
                                                      CircularProgressIndicator()) // Loading indicator
                                              : paginatedBarcodes.isEmpty
                                                  ? Center(
                                                      child: Text(
                                                          'No barcodes yet.')) // No barcodes message
                                                  : ListView.builder(
                                                      shrinkWrap: true,
                                                      physics:
                                                          NeverScrollableScrollPhysics(),
                                                      padding: EdgeInsets.zero,
                                                      itemCount:
                                                          paginatedBarcodes
                                                              .length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        final barcode =
                                                            paginatedBarcodes[
                                                                index];
                                                        bool isSelected =
                                                            _selectedBarcodes
                                                                .contains(
                                                                    barcode);
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
                                                                  barcode[
                                                                      'line_1'],
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
                                                                      'line_2'],
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
                                                                          color:
                                                                              Colors.green),
                                                                      onPressed:
                                                                          () =>
                                                                              _showEditBarcodeDialog(barcode),
                                                                    ),
                                                                    IconButton(
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .delete,
                                                                          color:
                                                                              Colors.red),
                                                                      onPressed:
                                                                          () =>
                                                                              _deleteBarcode(barcode['barcode_id']),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 1,
                                                                child: Checkbox(
                                                                  value:
                                                                      isSelected,
                                                                  onChanged:
                                                                      (value) {
                                                                    setState(
                                                                        () {
                                                                      if (value !=
                                                                          null) {
                                                                        if (value) {
                                                                          _selectedBarcodes
                                                                              .add(barcode);
                                                                          _showBarcodeInPrintContainer(
                                                                              barcode);
                                                                        } else {
                                                                          _selectedBarcodes
                                                                              .remove(barcode);
                                                                        }
                                                                      }
                                                                    });
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Pagination Buttons
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: _previousPage,
                                  color: _currentPage == 1
                                      ? Colors.grey
                                      : Colors.blue,
                                ),
                                // Editable page number in a box
                                Row(
                                  children: [
                                    const Text('Page ',
                                        style:
                                            TextStyle(fontFamily: 'Poppins')),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey), // Add a border
                                        borderRadius: BorderRadius.circular(
                                            5), // Rounded corners
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: SizedBox(
                                        width: 20, // Adjust width as needed
                                        child: TextField(
                                          controller:
                                              _pageController, // Controller for the input
                                          keyboardType: TextInputType
                                              .number, // Only allow numbers
                                          textAlign: TextAlign
                                              .center, // Center the text
                                          decoration: InputDecoration(
                                            hintText:
                                                '$_currentPage', // Show current page as hint
                                            border: InputBorder
                                                .none, // Remove the default TextField border
                                            contentPadding: EdgeInsets
                                                .zero, // Remove extra padding
                                            isDense:
                                                true, // Reduce the height of the input field
                                          ),
                                          onSubmitted: (value) {
                                            final int totalPages =
                                                (_filteredBarcodes.length /
                                                        _itemsPerPage)
                                                    .ceil();
                                            final int pageNumber =
                                                int.tryParse(value) ??
                                                    _currentPage;

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
                                            _pageController
                                                .clear(); // Clear the input field
                                          },
                                        ),
                                      ),
                                    ),
                                    Text(
                                        ' of ${(_filteredBarcodes.length / _itemsPerPage).ceil()}',
                                        style: const TextStyle(
                                            fontFamily: 'Poppins')),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: _nextPage,
                                  color: _currentPage ==
                                          (_filteredBarcodes.length /
                                                  _itemsPerPage)
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
