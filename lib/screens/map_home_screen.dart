
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_app/controller/map_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {


  final mapController = Get.put(MapController());

  GoogleMapController? _mapController;
  LatLng _currentLocation = LatLng(37.7749, -122.4194); // Initial location
  double _currentHeading = 0.0; // Initial heading

  final Set<Polyline> _polylines = {};
  final List<LatLng> _points = [
    LatLng(23.763999373281255, 90.4287651926279),
    LatLng(23.776176, 90.425674),
  ];

  final LatLng _origin = LatLng(23.776176, 90.425674); // San Francisco
  final LatLng _destination = LatLng(23.763999373281255, 90.4287651926279); // Los Angeles
  final String _apiKey = "AIzaSyCZ6YIiEkZnGVCQUyFIKsu3RdOJ49GVeLU"; // Replace with your API key
  double firstStepEndLat = 0.0;
  double firstStepEndLng = 0.0;

  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(23.769423999999997,90.41428529999999),
      tilt: 59.440717697143555,
      zoom: 18);


  void _createPolylines() {
    final polyline = Polyline(
      polylineId: PolylineId('route1'),
      points: _points,
      color: Colors.blue,
      width: 6,
    );
    _polylines.add(polyline);
  }

  Future<void> _getRoute() async {
    final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_origin.latitude},${_origin.longitude}&destination=${_destination.latitude},${_destination.longitude}&key=$_apiKey'));

    log("${response.statusCode}");
    log(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["routes"].isNotEmpty) {
        final route = data["routes"][0]["overview_polyline"]["points"];
        final points = _decodePolyline(route);

        var firstStepEndLocation = data['routes'][0]['legs'][0]['steps'][0]['end_location'];
        firstStepEndLat = firstStepEndLocation['lat'];
        firstStepEndLng = firstStepEndLocation['lng'];

        setState(() {
          _polylines.add(
            Polyline(
              polylineId: PolylineId("route"),
              points: points,
              color: Colors.blue,
              width: 5,
            ),
          );
        });
      }
    } else {
      print("Failed to fetch route: ${response.body}");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }


  String locationMessage = "";
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationMessage = "Location services are disabled.";
      });
      return;
    }

    // Request location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationMessage = "Location permissions are denied.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationMessage = "Location permissions are permanently denied. We cannot request permissions.";
      });
      return;
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      locationMessage = "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
      log("My current location: $locationMessage");
      mapController.setMyLocationMarker(LatLng(position.latitude, position.longitude), "My current location");
      mapController.setMarker(LatLng(23.776176, 90.425674), LatLng(firstStepEndLat, firstStepEndLng), "Truck", );
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    )).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _currentHeading = position.heading; // Heading in degrees
      });

      // Move the map camera to the new position
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation));
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // _createPolylines();
    // mapController.setMarker(LatLng(23.776176, 90.425674), "Truck", "");
    _getRoute();
    _getCurrentLocation().then((value) => _startLocationUpdates());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Google Map"),
      ),
      body: Obx(() => Column(
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: mapController.searchText.value,
                    decoration: const InputDecoration(
                      hintText: 'Place your co-ordinates or location....',
                    ),

                    onSubmitted: (value) async{
                      mapController.isSearched.value = true;
                      mapController.checkDataDoubleOrString();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: ()async {

                    List<Location> locations = await locationFromAddress("Gronausestraat 710, Enschede");
                    // mapController.isSearched.value = true;
                    // mapController.setTargetLocation(
                    //     double.parse(mapController.searchText.value.text.split(',').first),
                    //     double.parse(mapController.searchText.value.text.split(',').last)
                    // );
                  },
                )
              ],
            ),
          ),
          if(mapController.placesList.isNotEmpty)
            Expanded(
              flex: 5,
              child: Obx(() {
                return ListView.builder(
                  itemCount: mapController.placesList.length,
                  itemBuilder: (context, index){
                    return ListTile(
                      onTap: ()async{
                        List<Location> locations = await locationFromAddress(mapController.placesList[index]['description']);
                        print("${locations.last.latitude},${locations.last.longitude}");
                      },
                      title: Text(mapController.placesList[index]['description']),
                    );
                  },
                );
              }),
            ),
          Expanded(
            flex: 5,
            child: Obx(() => GoogleMap(
              initialCameraPosition: mapController.initialCameraPosition,
              compassEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: Set<Marker>.of(mapController.marker),
              onMapCreated: (GoogleMapController controller) {
                mapController.googleMapController.complete(controller);
              },
              onCameraMove: (CameraPosition position){
                print("Camera position is moving: ${position.target.latitude}, ${position.target.longitude}################");
                  mapController.updateLocation(
                      position.target.latitude, position.target.longitude
                  );
              },
              onTap: (LatLng latlng) async{
                mapController.isTapped.value = true;
                mapController.setTargetLocation(latlng.latitude, latlng.longitude);
                mapController.placeAddress = await placemarkFromCoordinates(latlng.latitude, latlng.longitude);

                mapController.marker.add(
                    Marker(
                      markerId: MarkerId('tapped place'),
                      position: LatLng(latlng.latitude, latlng.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                      infoWindow: InfoWindow(
                          title: "${mapController.placeAddress.first.subLocality}: ${latlng.latitude}, ${latlng.longitude}"
                      ),
                    )
                );
                final GoogleMapController controller = await mapController.googleMapController.future;
                await controller.animateCamera(CameraUpdate.newCameraPosition(mapController.kRandom));
                print("==============Map Tapped Here: ${mapController.placeAddress} ====================");
                mapController.isTapped.value = false;
              },

              polylines: _polylines,
            )),
          ),
        ],
      ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Wrap(
        direction: Axis.horizontal,
        children: [
          Container(
            margin: EdgeInsets.all(5),
            child: FloatingActionButton(
              onPressed: (){
              },
              child: Icon(Icons.draw_sharp),
            ),
          ),
          Container(
            margin: EdgeInsets.all(5),
            child: FloatingActionButton.extended(
              onPressed: _gotoLake,
              label: const Text("Go to Lake"),
              icon: Icon(Icons.directions_boat),
            ),
          ),
          Container(
            margin: EdgeInsets.all(5),
            child: FloatingActionButton(
              onPressed: (){
                mapController.getCurrentLocation();
              },
              child: Icon(Icons.location_history),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _gotoLake() async{
    BitmapDescriptor boatIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(), 'assets/icons/ship.png',);
    mapController.marker.add(
      Marker(
          markerId: MarkerId('Hatir jheel'),
        position: LatLng(23.769423999999997,90.41428529999999),
        // icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: "Travel in Hatir Jheel Lake by boat"
        ),
        icon: boatIcon,
      )
    );
    final GoogleMapController controller = await mapController.googleMapController.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));

  }
}
