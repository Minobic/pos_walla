import 'dart:math'; // Import the math library for the max function
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../custom/SidebarHeader.dart'; // Ensure this path is correct
import '../../../custom/AdminSidebar.dart'; // Ensure this path is correct
import '../../../services/ApiService.dart'; // Ensure this path is correct
import 'package:intl/intl.dart';
import '../../../custom/GradientButton.dart';
import '../../../custom/RedButton.dart';

class ReportWidget extends StatefulWidget {
  const ReportWidget({Key? key}) : super(key: key);

  @override
  State<ReportWidget> createState() => _ReportWidgetState();
}

class _ReportWidgetState extends State<ReportWidget> {
  String _timeRange = 'daily'; // Default time range
  String? _lastSelectedTimeRange;
  bool _isSidebarOpen = false;
  List<dynamic> _transactions = [];
  double _cashAmount = 0.0;
  double _onlineAmount = 0.0;
  String? _startDate; // Initialize as nullable
  String? _endDate; // Initialize as nullable

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _fetchTransactions() async {
    try {
      final transactions = await ApiService.fetchTransactions(_timeRange);
      setState(() {
        _transactions = transactions;
        _processTransactionData();
      });
    } catch (e) {
      print('Failed to fetch transactions: $e');
    }
  }

  void _processTransactionData() {
    _cashAmount = 0.0;
    _onlineAmount = 0.0;

    for (var transaction in _transactions) {
      if (transaction['payment_method'] == 'Cash') {
        _cashAmount += transaction['total_amount'];
      } else {
        _onlineAmount += transaction['total_amount'];
      }
    }
  }

  List<FlSpot> _prepareGraphData() {
    final Map<int, double> dataPoints = {};
    final apiDateFormat =
        DateFormat('dd-MM-yyyy HH:mm:ss'); // Format for parsing API date

    // Determine the current date and time
    final now = DateTime.now();

    // Initialize data points based on the time range
    int dataPointCount;
    DateTime? startDate;
    DateTime? endDate;

    switch (_timeRange) {
      case 'daily':
        dataPointCount = now.hour + 1; // Show from 0 to current hour
        break;
      case 'weekly':
        dataPointCount = 7; // Show for each day of the week
        break;
      case 'monthly':
        dataPointCount = now.day; // Show from 1 to current day of the month
        break;
      case 'quarterly':
      case 'yearly':
        dataPointCount = now.month; // Show from January to current month
        break;
      case 'custom':
        // Ensure _startDate and _endDate are set
        if (_startDate != null && _endDate != null) {
          startDate = DateTime.parse(_startDate!);
          endDate = DateTime.parse(_endDate!);
          dataPointCount = endDate.difference(startDate).inDays + 1;
        } else {
          dataPointCount = 0; // No data points if dates are not set
        }
        break;
      default:
        dataPointCount = 0;
    }

    // Initialize data points to zero
    for (int i = 0; i < dataPointCount; i++) {
      dataPoints[i] = 0.0;
    }

    // Populate data points based on transactions
    for (var transaction in _transactions) {
      final DateTime date = apiDateFormat.parse(transaction['created_at']);
      int index;

      switch (_timeRange) {
        case 'daily':
          if (date.day == now.day &&
              date.month == now.month &&
              date.year == now.year) {
            index = date.hour; // Only include transactions from today
            dataPoints[index] =
                (dataPoints[index] ?? 0) + transaction['total_amount'];
          }
          break;
        case 'weekly':
          if (date.isAfter(now.subtract(Duration(days: now.weekday))) &&
              date.isBefore(now.add(Duration(days: 1)))) {
            index = date.weekday; // Monday is 1, Sunday is 7
            dataPoints[index - 1] =
                (dataPoints[index - 1] ?? 0) + transaction['total_amount'];
          }
          break;
        case 'monthly':
          if (date.month == now.month && date.year == now.year) {
            index = date.day - 1; // Day of the month (1-31)
            dataPoints[index] =
                (dataPoints[index] ?? 0) + transaction['total_amount'];
          }
          break;
        case 'quarterly':
        case 'yearly':
          if (date.year == now.year) {
            index = date.month - 1; // Month (1-12)
            dataPoints[index] =
                (dataPoints[index] ?? 0) + transaction['total_amount'];
          }
          break;
        case 'custom':
          if (startDate != null &&
              endDate != null &&
              date.isAfter(startDate.subtract(Duration(days: 1))) &&
              date.isBefore(endDate.add(Duration(days: 1)))) {
            index = date.difference(startDate).inDays;
            dataPoints[index] =
                (dataPoints[index] ?? 0) + transaction['total_amount'];
          }
          break;
        default:
          continue; // Skip if time range is not valid
      }
    }

    // Calculate the maximum value in the dataset
    double maxValue =
        dataPoints.values.isNotEmpty ? dataPoints.values.reduce(max) : 1.0;

    // Determine an appropriate interval for the Y-axis
    double yInterval = _calculateInterval(maxValue);

    // Determine an appropriate interval for the X-axis
    double xInterval = _calculateXInterval(dataPointCount);

    return dataPoints.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
  }

  double _calculateInterval(double maxValue) {
    if (maxValue <= 10) {
      return 1.0;
    } else if (maxValue <= 50) {
      return 5.0;
    } else if (maxValue <= 100) {
      return 10.0;
    } else if (maxValue <= 500) {
      return 50.0;
    } else if (maxValue <= 1000) {
      return 100.0;
    } else {
      return 500.0;
    }
  }

  double _calculateXInterval(int dataPointCount) {
    if (dataPointCount <= 7) {
      return 1.0;
    } else if (dataPointCount <= 14) {
      return 2.0;
    } else if (dataPointCount <= 30) {
      return 5.0;
    } else {
      return 10.0;
    }
  }

  String _getXAxisTitle(double value) {
    switch (_timeRange) {
      case 'daily':
        return '${value.toInt()}:00'; // Show hours (e.g., 0:00, 1:00, ..., 23:00)
      case 'weekly':
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[value.toInt()];
      case 'monthly':
        return 'Day ${value.toInt() + 1}'; // Day of the month (1-31)
      case 'quarterly':
      case 'yearly':
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return months[value.toInt()];
      case 'custom':
        // Assume _startDate is set
        DateTime date =
            DateTime.parse(_startDate!).add(Duration(days: value.toInt()));
        return '${date.day}-${date.month}';
      default:
        return '';
    }
  }

  Future<void> _showCustomDateRangeDialog() async {
    // Set _timeRange to the last selected time range to maintain the current state
    setState(() {
      _timeRange = _lastSelectedTimeRange ?? 'daily';
    });

    TextEditingController startDateController = TextEditingController();
    TextEditingController endDateController = TextEditingController();

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
              'Select Date Range',
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
                  controller: startDateController,
                  decoration: InputDecoration(
                    labelText: 'Start Date (DD-MM-YYYY)',
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endDateController,
                  decoration: InputDecoration(
                    labelText: 'End Date (DD-MM-YYYY)',
                    labelStyle: TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  keyboardType: TextInputType.datetime,
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
              width: 150, // Set the width of the button
            ),
            GradientButton(
              text: 'Apply',
              onPressed: () {
                String startDate = startDateController.text;
                String endDate = endDateController.text;

                if (startDate.isNotEmpty && endDate.isNotEmpty) {
                  try {
                    // Validate the input dates
                    DateFormat inputFormat = DateFormat('dd-MM-yyyy');
                    DateTime parsedStartDate = inputFormat.parse(startDate);
                    DateTime parsedEndDate = inputFormat.parse(endDate);

                    // Format the dates for the API call
                    DateFormat apiFormat = DateFormat('yyyy-MM-dd');
                    String formattedStartDate =
                        apiFormat.format(parsedStartDate);
                    String formattedEndDate = apiFormat.format(parsedEndDate);

                    setState(() {
                      _timeRange = 'custom';
                      _lastSelectedTimeRange =
                          'custom'; // Update the last selected time range
                      _startDate = formattedStartDate; // Store the start date
                      _endDate = formattedEndDate; // Store the end date
                      _fetchCustomTransactions(
                          formattedStartDate, formattedEndDate);
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Please enter valid dates in DD-MM-YYYY format.'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter both start and end dates.'),
                    ),
                  );
                }
              },
              width: 150, // Set the width of the button
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchCustomTransactions(
      String startDate, String endDate) async {
    try {
      final transactions =
          await ApiService.fetchCustomTransactions(startDate, endDate);
      setState(() {
        _transactions = transactions;
        _processTransactionData();
      });
    } catch (e) {
      print('Error fetching custom transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final graphData = _prepareGraphData();

    // Check if graphData is empty
    if (graphData.isEmpty) {
      return Center(
          child: Text('No data available for the selected time range.'));
    }

    final totalAmount = _cashAmount + _onlineAmount;
    final cashPercentage =
        totalAmount > 0 ? (_cashAmount / totalAmount) * 100 : 0.0;
    final onlinePercentage =
        totalAmount > 0 ? (_onlineAmount / totalAmount) * 100 : 0.0;

    // Calculate the maximum value in the dataset
    double maxValue = graphData.map((spot) => spot.y).reduce(max);

    // Determine an appropriate interval for the Y-axis
    double yInterval = _calculateInterval(maxValue);

    // Determine an appropriate interval for the X-axis
    double xInterval = _calculateXInterval(graphData.length);

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
            selectedMenuItem: 'Reports',
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
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Analysis card
                        Expanded(
                          flex: 2,
                          child: Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Analysis',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Text('Sort by'),
                                          const SizedBox(width: 5),
                                          DropdownButton<String>(
                                            dropdownColor: Colors.white,
                                            value: _timeRange,
                                            icon: const Icon(
                                                Icons.arrow_drop_down),
                                            underline: Container(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _lastSelectedTimeRange =
                                                    _timeRange; // Update the last selected time range
                                                _timeRange = newValue!;
                                                if (_timeRange == 'custom') {
                                                  _showCustomDateRangeDialog();
                                                } else {
                                                  _fetchTransactions();
                                                }
                                              });
                                            },
                                            items: <String>[
                                              'daily',
                                              'weekly',
                                              'monthly',
                                              'quarterly',
                                              'yearly',
                                              'custom'
                                            ].map<DropdownMenuItem<String>>(
                                                (String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value.capitalize()),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: LineChart(
                                      LineChartData(
                                        gridData: FlGridData(show: true),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              interval: yInterval,
                                              reservedSize: 40,
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              interval: xInterval,
                                              getTitlesWidget: (value, meta) {
                                                if (value % xInterval == 0) {
                                                  return Text(
                                                      _getXAxisTitle(value));
                                                }
                                                return Container();
                                              },
                                              reservedSize: 30,
                                            ),
                                          ),
                                          rightTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false),
                                          ),
                                          topTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: graphData,
                                            isCurved: true,
                                            color: Colors.blue,
                                            barWidth: 3,
                                            isStrokeCapRound: true,
                                            dotData: FlDotData(show: false),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color:
                                                  Colors.blue.withOpacity(0.1),
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
                        const SizedBox(width: 20),
                        // Cash/Online card
                        Expanded(
                          flex: 1,
                          child: Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Cash/Online',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(Icons.more_horiz),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 0,
                                        centerSpaceRadius: 50,
                                        sections: [
                                          PieChartSectionData(
                                            color: Colors.blue,
                                            value: cashPercentage,
                                            title: 'Cash',
                                            radius: 80,
                                            titleStyle: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          PieChartSectionData(
                                            color: Colors.green,
                                            value: onlinePercentage,
                                            title: 'Online',
                                            radius: 80,
                                            titleStyle: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Card(
                                    elevation: 2,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          _buildLegendItem('Cash', Colors.blue,
                                              '${cashPercentage.toStringAsFixed(1)}%'),
                                          const SizedBox(height: 20),
                                          _buildLegendItem(
                                              'Online',
                                              Colors.green,
                                              '${onlinePercentage.toStringAsFixed(1)}%'),
                                        ],
                                      ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 25,
            fontFamily: 'poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          percentage,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'poppins',
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
