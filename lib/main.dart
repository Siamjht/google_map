import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_app/controller/map_controller.dart';
import 'package:google_maps_app/screens/map_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapHomeScreen(),
      // home: MapScreen(),
      initialBinding: BindingsBuilder(() {
        Get.put(MapController());
      }),
    );
  }
}

