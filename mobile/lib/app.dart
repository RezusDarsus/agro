import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/home_screen.dart';

class AgroLensApp extends StatelessWidget {
  const AgroLensApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AgroLens Samegrelo',
        theme: AppTheme.light,
        home: const HomeScreen(),
      );
}
