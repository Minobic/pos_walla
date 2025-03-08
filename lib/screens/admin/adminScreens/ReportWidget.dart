import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../custom/SidebarHeader.dart'; // Ensure this path is correct
import '../../../custom/AdminSidebar.dart'; // Ensure this path is correct
import '../../../services/ApiService.dart'; // Ensure this path is correct

class ReportWidget extends StatefulWidget {
  const ReportWidget({Key? key}) : super(key: key);

  @override
  State<ReportWidget> createState() => _ReportWidgetState();
}

class _ReportWidgetState extends State<ReportWidget> {
  String _timeRange = 'daily'; // Default time range
  bool _isSidebarOpen = false;
  List<dynamic> _transactions = [];
  double _cashAmount = 0.0;
  double _onlineAmount = 0.0;

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

  Future<void> _fetchTransactions() async {
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
      if (transaction['payment_method'] == 'cash') {
        _cashAmount += transaction['total_amount'];
      } else {
        _onlineAmount += transaction['total_amount'];
      }
    }
  }

  List<FlSpot> _prepareGraphData() {
    final Map<int, double> dataPoints = {};

    // Determine the current date and time
    final now = DateTime.now();

    // Initialize data points based on the time range
    int dataPointCount;
    switch (_timeRange) {
      case 'daily':
        dataPointCount = now.hour + 1; // Show from 0 to current hour
        break;
      case 'weekly':
        dataPointCount = now.weekday; // Show from Monday to current day
        break;
      case 'monthly':
        dataPointCount = now.day; // Show from 1 to current day of the month
        break;
      case 'quarterly':
        dataPointCount = now.month; // Show from January to current month
        break;
      case 'yearly':
        dataPointCount = now.month; // Show from January to current month
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
      final DateTime date = DateTime.parse(transaction['created_at']);
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
          if (date.isAfter(now.subtract(Duration(days: now.weekday - 1))) &&
              date.isBefore(now.add(Duration(days: 1)))) {
            index = date.weekday - 1; // Monday is 0, Sunday is 6
            dataPoints[index] =
                (dataPoints[index] ?? 0) + transaction['total_amount'];
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
        default:
          continue; // Skip if time range is not valid
      }
    }

    return dataPoints.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
  }

  String _getXAxisTitle(double value) {
    switch (_timeRange) {
      case 'daily':
        return '${value.toInt()}:00'; // Show hours (e.g., 0:00, 1:00, ..., 23:00)
      case 'weekly':
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[value.toInt() % days.length];
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
      default:
        return '';
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final graphData = _prepareGraphData();

    // Check if graphData is empty
    if (graphData.isEmpty) {
      return Center(
          child: Text('No data available for the selected time range.'));
    }

    final totalAmount = _cashAmount + _onlineAmount;
    final cashPercentage = totalAmount > 0
        ? (_cashAmount / totalAmount) * 100
        : 0.0; // Ensure this is a double
    final onlinePercentage = totalAmount > 0
        ? (_onlineAmount / totalAmount) * 100
        : 0.0; // Ensure this is a double

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
                                            value: _timeRange,
                                            icon: const Icon(
                                                Icons.arrow_drop_down),
                                            underline: Container(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _timeRange = newValue!;
                                                _fetchTransactions();
                                              });
                                            },
                                            items: <String>[
                                              'daily',
                                              'weekly',
                                              'monthly',
                                              'quarterly',
                                              'yearly'
                                            ].map<DropdownMenuItem<String>>(
                                                (String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
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
                                              interval: 10,
                                              reservedSize: 40,
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                return Text(
                                                    _getXAxisTitle(value));
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
                                        centerSpaceRadius: 60,
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
                                  _buildLegendItem('Cash', Colors.blue,
                                      '${cashPercentage.toStringAsFixed(1)}%'),
                                  const SizedBox(height: 10),
                                  _buildLegendItem('Online', Colors.green,
                                      '${onlinePercentage.toStringAsFixed(1)}%'),
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
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          percentage,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
