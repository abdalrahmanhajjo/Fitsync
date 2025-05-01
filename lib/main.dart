// lib/main.dart
import 'package:fitsync/features/auth/providers/nutrition_provider.dart';
import 'package:fitsync/features/auth/providers/progress_provider.dart';
import 'package:fitsync/features/auth/providers/workout_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),

      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitSync',

      routes: {
        '/': (context) => const AuthScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },

    );
  }
}