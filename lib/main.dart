// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_app/controller/map_controller.dart';
// import 'package:google_maps_app/screens/map_home_screen.dart';
// import 'package:google_maps_app/screens/map_screen.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: MapHomeScreen(),
//       // home: MapScreen(),
//       initialBinding: BindingsBuilder(() {
//         Get.put(MapController());
//       }),
//     );
//   }
// }

import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await initializeService();

  runApp(MyApp());
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel notificationChannel = AndroidNotificationChannel(
  "stopwatch_foreground",
  "Stopwatch Foreground",
  description: "This channel is used for stopwatch notifications",
  importance: Importance.high,
);

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(iOS: DarwinInitializationSettings()),
    );
  }


  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(notificationChannel);


  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannel.id,
      initialNotificationTitle: "Background Service Running",
      initialNotificationContent: "Fetching location...",
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: iosBackground,
    ),
  );

  await service.startService();
}

// iOS Background Execution Handler
@pragma("vm:entry-point")
Future<bool> iosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// Main Background Service Handler
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Location Service",
      content: "Tracking your location...",
    );
  }

  // Request location permissions
  // await Geolocator.requestPermission();

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    // if (!service.isRunning) timer.cancel();

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Log or process the location
    print("Location: ${position.latitude}, ${position.longitude}");

    // Optionally, communicate with the app via the service
    service.invoke("update", {
      "latitude": position.latitude,
      "longitude": position.longitude,
    });
  });
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Background Service',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String latitude = "Unknown";
  String longitude = "Unknown";

  @override
  void initState() {
    super.initState();
    // requestLocationPermission();
    FlutterBackgroundService().on('update').listen((data) {
      if (data != null) {
        setState(() {
          latitude = data['latitude'].toString();
          longitude = data['longitude'].toString();
        });
      }
    });

    loadSavedLocation();
  }

  Future<void> handleLocationPermissions(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission denied.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location permission is required to continue.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permission permanently denied. Directing to settings.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enable location permissions in settings."),
          action: SnackBarAction(
            label: "Settings",
            onPressed: () {
              Geolocator.openAppSettings();
            },
          ),
        ),
      );
      return;
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      print("Location permission granted.");
    } else {
      print("Unhandled permission state: $permission");
    }
  }


  Future<void> requestLocationPermission() async {
    await Geolocator.checkPermission();
    // Check if a request is already running
    if (await Permission.location.isGranted) {
      print("Location permission already granted.");
      return;
    }

    final status = await Permission.location.request();
    if (status.isGranted) {
      print("Location permission granted.");
    } else if (status.isDenied) {
      print("Location permission denied.");
    } else if (status.isPermanentlyDenied) {
      print("Location permission permanently denied. Directing to settings.");
      openAppSettings();
    }

    // Check if the app has the required foreground service permission
    if (await Permission.notification.request().isGranted) {
      print("Foreground service permission granted");
    } else {
      print("Foreground service permission denied");
    }
  }

  Future<void> loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      latitude = prefs.getString('latitude') ?? "Unknown";
      longitude = prefs.getString('longitude') ?? "Unknown";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Background Location Service")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // await requestLocationPermission();
                //
                // // Check if permissions are granted before starting the service
                // if (await Permission.location.isGranted) {
                //   FlutterBackgroundService().startService();
                //   print("Background service started.");
                // } else {
                //   print("Cannot start the service. Location permission not granted.");
                // }

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Location Permission Required"),
                      content: Text("This app needs location permissions to track your location."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // Close the dialog
                            await handleLocationPermissions(context);
                          },
                          child: Text("Grant Permission"),
                        ),
                      ],
                    );
                  },
                );


              },
              child: Text("Start Background Service"),
            ),

            Text("Latitude: $latitude"),
            Text("Longitude: $longitude"),
          ],
        ),
      ),
    );
  }
}
