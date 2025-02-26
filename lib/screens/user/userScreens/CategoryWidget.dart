import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../custom/SidebarHeader.dart'; // Import the reusable components
import '../../../services/ApiService.dart'; // Import the ApiService
import '../../../custom/GradientButton.dart'; // Import the GradientButton
import '../../../custom/RedButton.dart'; // Import the RedButton

class CategoryWidget extends StatefulWidget {
  final String userName;
  final String userRole;

  const CategoryWidget({
    Key? key,
    required this.userName,
    required this.userRole,
  }) : super(key: key);

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  bool _isSidebarOpen = false;
  List<dynamic> _categories = [];
  List<dynamic> _filteredCategories = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String _selectedSortOption = 'Default'; // Track selected sorting option
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchCategories();
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
      _filteredCategories = _categories
          .where((category) => category['cat_name']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
      _currentPage = 1; // Reset to the first page when searching
    });
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });
    try {
      final categories = await ApiService.fetchCategories();
      setState(() {
        _categories = categories;
        _filteredCategories = categories;
      });
    } catch (e) {
      print('Failed to fetch categories: $e');
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

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

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
              'Add New Category',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description',
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
          actions: [
            RedButton(
              text: 'Cancel',
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              width: 150, // Set the desired width
            ),
            GradientButton(
              text: 'Add',
              onPressed: () async {
                try {
                  final newCategory = await ApiService.addCategory(
                    name: nameController.text,
                    description: descriptionController.text,
                  );
                  setState(() {
                    _categories.add(newCategory);
                    _filteredCategories = _categories;
                  });
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Failed to add category: $e');
                }
              },
              width: 150,
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(dynamic category) {
    final TextEditingController nameController =
        TextEditingController(text: category['cat_name']);
    final TextEditingController descriptionController =
        TextEditingController(text: category['cat_description']);

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
              'Edit Category',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: Container(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description',
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
                  final updatedCategory = await ApiService.updateCategory(
                    catId: category['cat_id'],
                    name: nameController.text,
                    description: descriptionController.text,
                  );
                  setState(() {
                    int index = _categories.indexWhere(
                        (cat) => cat['cat_id'] == category['cat_id']);
                    if (index != -1) {
                      _categories[index] = updatedCategory;
                      _filteredCategories = _categories;
                    }
                  });
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Failed to update category: $e');
                }
              },
              width: 150,
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(int catId) async {
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
          content: const Text('Are you sure you want to delete this category?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                textAlign: TextAlign.center,
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(160, 53), // Set the desired width
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
        await ApiService.deleteCategory(catId);
        setState(() {
          _categories.removeWhere((cat) => cat['cat_id'] == catId);
          _filteredCategories = _categories;
        });
      } catch (e) {
        print('Failed to delete category: $e');
      }
    }
  }

  List<dynamic> _getPaginatedCategories() {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _filteredCategories.length) {
      endIndex = _filteredCategories.length;
    }
    return _filteredCategories.sublist(startIndex, endIndex);
  }

  void _nextPage() {
    setState(() {
      if (_currentPage < (_filteredCategories.length / _itemsPerPage).ceil()) {
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

  void _sortCategories(String sortOption) {
    setState(() {
      _selectedSortOption = sortOption;
      switch (sortOption) {
        case 'Recently Added':
          _filteredCategories.sort((a, b) =>
              b['created_at'].compareTo(a['created_at'])); // Most recent first
          break;
        case 'Category Name (A-Z)':
          _filteredCategories.sort(
              (a, b) => a['cat_name'].compareTo(b['cat_name'])); // A-Z sorting
          break;
        case 'Category Name (Z-A)':
          _filteredCategories.sort(
              (a, b) => b['cat_name'].compareTo(a['cat_name'])); // Z-A sorting
          break;
        default:
          _filteredCategories = List.from(_categories); // Default order
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paginatedCategories = _getPaginatedCategories();

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            isSidebarOpen: _isSidebarOpen,
            toggleSidebar: _toggleSidebar,
            userName: widget.userName,
            userRole: widget.userRole,
            selectedMenuItem: 'Categories',
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
                              hintText: 'Search Category',
                              hintStyle: TextStyle(fontFamily: 'Poppins'),
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GradientButton(
                          text: 'Add New Category',
                          onPressed: _showAddCategoryDialog,
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
                                      'Categories Table',
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
                                        onSelected: _sortCategories,
                                        itemBuilder: (BuildContext context) {
                                          return [
                                            'Default',
                                            'Recently Added',
                                            'Category Name (A-Z)',
                                            'Category Name (Z-A)',
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
                                                'C.ID',
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
                                                'Category',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'Description',
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
                                                'Created At',
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
                                                'Updated At',
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
                                      // Scrollable Data
                                      Expanded(
                                        child: _isLoading
                                            ? Center(
                                                child:
                                                    CircularProgressIndicator()) // Loading indicator
                                            : paginatedCategories.isEmpty
                                                ? Center(
                                                    child: Text(
                                                        'No categories yet.')) // No categories message
                                                : ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    itemCount:
                                                        paginatedCategories
                                                            .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final category =
                                                          paginatedCategories[
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
                                                                category[
                                                                        'cat_id']
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
                                                                category[
                                                                    'cat_name'],
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        'Poppins'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 3,
                                                              child: Text(
                                                                category[
                                                                    'cat_description'],
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
                                                                category[
                                                                    'created_at'],
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
                                                                category[
                                                                    'updated_at'],
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
                                                                        _showEditCategoryDialog(
                                                                            category),
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .delete,
                                                                        color: Colors
                                                                            .red),
                                                                    onPressed: () =>
                                                                        _deleteCategory(
                                                                            category['cat_id']),
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
                  // Pagination Buttons
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
                        // Editable page number in a box
                        Row(
                          children: [
                            const Text(
                              'Page ',
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey), // Add a border
                                borderRadius:
                                    BorderRadius.circular(5), // Rounded corners
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
                                  textAlign:
                                      TextAlign.center, // Center the text
                                  decoration: InputDecoration(
                                    hintText:
                                        '$_currentPage', // Show current page as hint
                                    border: InputBorder
                                        .none, // Remove the default TextField border
                                    contentPadding:
                                        EdgeInsets.zero, // Remove extra padding
                                    isDense:
                                        true, // Reduce the height of the input field
                                  ),
                                  onSubmitted: (value) {
                                    final int totalPages =
                                        (_filteredCategories.length /
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
                                    _pageController
                                        .clear(); // Clear the input field
                                  },
                                ),
                              ),
                            ),
                            Text(
                              ' of ${(_filteredCategories.length / _itemsPerPage).ceil()}',
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _nextPage,
                          color: _currentPage ==
                                  (_filteredCategories.length / _itemsPerPage)
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
