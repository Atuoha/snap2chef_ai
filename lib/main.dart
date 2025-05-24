import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:snap2chef/presentation/screens/home_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'core/constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snap2Chef',
      home: LoaderOverlay(
        overlayWidgetBuilder: (_) {
          return Center(
            child: SpinKitWanderingCubes(
              color: AppColors.primaryColor,
              size: 50.0,
            ),
          );
        },
        child: const HomeScreen(),
      ),
    );
  }
}
