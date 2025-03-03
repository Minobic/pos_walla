import 'package:flutter/material.dart';
import 'screens/WelcomeWidget.dart';
import 'screens/user/LoginWidget.dart';
import 'screens/user/RegisterWidget.dart';
import 'screens/admin/AdminLoginWidget.dart';
import 'screens/user/userScreens/CategoryWidget.dart';
import 'screens/user/userScreens/ProductWidget.dart';
import 'screens/user/userScreens/DashboardWidget.dart';
import 'screens/user/userScreens/ProductBatchWidget.dart';
import 'screens/user/userScreens/InventoryWidget.dart';
import 'screens/user/userScreens/BillingWidget.dart';
import 'screens/user/userScreens/BarcodeGeneratorWidget.dart';
import 'screens/admin/adminScreens/AdminDashboardWidget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Service',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
                builder: (context) => const WelcomeWidget());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginWidget());
          case '/register':
            return MaterialPageRoute(
                builder: (context) => const RegisterWidget());
          case '/adminLogin':
            return MaterialPageRoute(
                builder: (context) => const AdminLoginWidget());
          case '/dashboard':
            final args = settings.arguments
                as Map<String, dynamic>; // Expecting a Map with user data
            return MaterialPageRoute(
              builder: (context) => DashboardWidget(
                userName: args['name'] ??
                    'User ', // Provide a default value if not found
                userRole: args['role'] ??
                    'Role', // Provide a default value if not found
                userId:
                    args['userId'] ?? 1, // Provide a default value if not found
              ),
            );
          case '/category':
            final args = settings.arguments
                as Map<String, dynamic>; // Expecting a Map with user data
            return MaterialPageRoute(
              builder: (context) => CategoryWidget(
                userName: args['name'] ??
                    'User ', // Provide a default value if not found
                userRole: args['role'] ??
                    'Role', // Provide a default value if not found
                userId:
                    args['userId'] ?? 1, // Provide a default value if not found
              ),
            );
          case '/product':
            final args = settings.arguments
                as Map<String, dynamic>; // Expecting a Map with user data
            return MaterialPageRoute(
              builder: (context) => ProductWidget(
                userName: args['name'] ??
                    'User ', // Provide a default value if not found
                userRole: args['role'] ??
                    'Role', // Provide a default value if not found
                userId:
                    args['userId'] ?? 1, // Provide a default value if not found
              ),
            );
          case '/productbatch':
            final args = settings.arguments
                as Map<String, dynamic>; // Expecting a Map with user data
            return MaterialPageRoute(
              builder: (context) => ProductBatchWidget(
                userName: args['name'] ??
                    'User ', // Provide a default value if not found
                userRole: args['role'] ??
                    'Role', // Provide a default value if not found
                userId:
                    args['userId'] ?? 1, // Provide a default value if not found
              ),
            );
          case '/inventory':
            final args = settings.arguments
                as Map<String, dynamic>; // Expecting a Map with user data
            return MaterialPageRoute(
              builder: (context) => InventoryWidget(
                userName: args['name'] ??
                    'User ', // Provide a default value if not found
                userRole: args['role'] ??
                    'Role', // Provide a default value if not found
                userId:
                    args['userId'] ?? 1, // Provide a default value if not found
              ),
            );
          case '/billing':
            final args = settings.arguments
                as Map<String, dynamic>; // Expecting a Map with user data
            return MaterialPageRoute(
              builder: (context) => BillingWidget(
                userName: args['name'] ??
                    'User ', // Provide a default value if not found
                userRole: args['role'] ??
                    'Role', // Provide a default value if not found
                userId:
                    args['userId'] ?? 1, // Provide a default value if not found
              ),
            );
          case '/barcode':
            final args = settings.arguments
                as Map<String, dynamic>; // Expecting a Map with user data
            return MaterialPageRoute(
              builder: (context) => BarcodeGeneratorWidget(
                userName: args['name'] ??
                    'User ', // Provide a default value if not found
                userRole: args['role'] ??
                    'Role', // Provide a default value if not found
                userId:
                    args['userId'] ?? 1, // Provide a default value if not found
              ),
            );
          case '/adminDashboard':
            return MaterialPageRoute(
                builder: (context) => const AdminDashboardWidget());
          default:
            return MaterialPageRoute(
                builder: (context) => const WelcomeWidget());
        }
      },
    );
  }
}
