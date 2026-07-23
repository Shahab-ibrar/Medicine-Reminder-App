import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'package:medicine_reminder_app/providers/auth_provider.dart';
import 'package:medicine_reminder_app/providers/medicine_provider.dart';
import 'package:medicine_reminder_app/providers/theme_provider.dart';

import 'package:medicine_reminder_app/services/service_locator.dart';
import 'package:medicine_reminder_app/services/notification_service.dart';

import 'package:medicine_reminder_app/screens/splash_screen.dart';
import 'package:medicine_reminder_app/screens/login_screen.dart';
import 'package:medicine_reminder_app/screens/register_screen.dart';
import 'package:medicine_reminder_app/screens/forgot_password_screen.dart';
import 'package:medicine_reminder_app/screens/home_dashboard.dart';
import 'package:medicine_reminder_app/screens/add_edit_medicine_screen.dart';
import 'package:medicine_reminder_app/screens/medicine_details_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Service Locator
  await locator.init();

  // Initialize Notifications
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, MedicineProvider>(
          create: (_) => MedicineProvider(),
          update: (_, authProvider, medicineProvider) {
            medicineProvider!.updateUserId(authProvider.user?.uid);
            return medicineProvider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'MediMind',
            theme: themeProvider.currentTheme,
            initialRoute: '/splash',
            routes: {
              '/splash': (_) => const SplashScreen(),
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterScreen(),
              '/forgot_password': (_) => const ForgotPasswordScreen(),
              '/home': (_) => const HomeDashboard(),
              '/add_medicine': (_) => const AddEditMedicineScreen(),
              '/medicine_details': (_) => const MedicineDetailsScreen(),
            },
          );
        },
      ),
    );
  }
}
