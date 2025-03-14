import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CustomDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final Function(T?) onChanged;
  final String Function(T) itemAsString; // Function to convert item to string
  final String label; // Label for the dropdown

  const CustomDropdown({
    Key? key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    required this.itemAsString,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>(
      popupProps: PopupProps.menu(
        showSearchBox: true, // Enable search bar
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search $label...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            fillColor:
                Colors.white, // Set search field background color to white
            filled: true,
          ),
        ),
        menuProps: MenuProps(
          backgroundColor:
              Colors.white, // Set popup menu background color to white
        ),
      ),
      items: items,
      itemAsString: itemAsString,
      onChanged: onChanged,
      selectedItem: selectedItem,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontFamily: 'Poppins'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          fillColor: Colors.white, // Set dropdown background color to white
          filled: true,
        ),
      ),
    );
  }
}
