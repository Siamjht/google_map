import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:custom_marker/marker_icon.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class MapController extends GetxController {
  final Completer<GoogleMapController> googleMapController = Completer();
  CustomInfoWindowController infoWindowController = CustomInfoWindowController();

  final searchText = TextEditingController().obs;
  RxBool isSearched = false.obs;
  RxBool isTapped = false.obs;

  RxDouble userLatitude = 23.7814561.obs;
  RxDouble userLongitude = 90.4215143.obs;

  RxDouble targetLatitude = 0.0.obs;
  RxDouble targetLongitude = 0.0.obs;
  List<Marker> marker = [];
  List<Placemark> placeAddress = [];
  List<Location> locationCoOrdinates = [];

  double _truckBearing = 180; // Example bearing in degrees

  void updateLocation(double lat, double lng) {
    userLatitude.value = lat;
    userLongitude.value = lng;
  }

  void setTargetLocation(double lat, double lng) {
    print("++++++++++ Set Target Location+++++++++");
    targetLatitude.value = lat;
    targetLongitude.value = lng;
    print("${targetLatitude.value}, ${targetLongitude.value}");
  }

  CameraPosition get initialCameraPosition => CameraPosition(
        target: LatLng(userLatitude.value, userLongitude.value),
        zoom: 14.0,
      );

  CameraPosition get kRandom => CameraPosition(
      bearing: 180,
      target: isTapped.value
          ? LatLng(targetLatitude.value, targetLongitude.value)
          : LatLng(userLatitude.value, userLongitude.value),
      tilt: 59.440717697143555,
      zoom: 15);

  final List<Marker> list = [
    const Marker(
      markerId: MarkerId('office'),
      position: LatLng(23.763999373281255, 90.4287651926279),
      infoWindow: InfoWindow(
        title: 'Bd Calling IT Ltd.',
      ),
      // onTap: (){
      //   infoWindowController.addInfoWindow(
      //    Container(
      //      height: 300,
      //      width: 200,
      //      decoration: BoxDecoration(
      //        color: Colors.white,
      //        border: Border.all(color: Colors.grey),
      //        borderRadius: BorderRadius.circular(15.0)
      //      ),
      //      child: Column(
      //        mainAxisAlignment: MainAxisAlignment.start,
      //        crossAxisAlignment: CrossAxisAlignment.start,
      //        children: [
      //          Container(
      //            width: 300,
      //            height: 90,
      //            decoration: BoxDecoration(
      //              image:  DecorationImage(image: NetworkImage(""),
      //              fit: BoxFit.fitWidth,
      //              filterQuality: FilterQuality.high
      //              ),
      //              borderRadius: BorderRadius.all(Radius.circular(10.0)),
      //            ),
      //          ),
      //          Padding(
      //              padding: EdgeInsets.only(top: 10, left: 10, right: 10),
      //          child: Row(
      //            children: [
      //              SizedBox(width: 100,
      //              child: Text(
      //                "Bd Calling Office",
      //                maxLines: 2,
      //                overflow: TextOverflow.fade,
      //                softWrap: false,
      //              ),
      //              ),
      //              Spacer(),
      //              Text("3 min...")
      //            ],
      //          ),
      //          ),
      //          Padding(
      //              padding: EdgeInsets.only(top: 10, left: 10, right: 10),
      //            child: Text("Corporate Office",
      //            maxLines: 2,),
      //          )
      //        ],
      //      ),
      //    ),
      //       LatLng(23.763999373281255, 90.4287651926279)
      //   );
      // }
    ),
    // const Marker(
    //     markerId: MarkerId('2'),
    //     position: LatLng(23.776176, 90.425674),
    //     infoWindow: InfoWindow(
    //       title: 'Badda',
    //     )),
    const Marker(
        markerId: MarkerId('My Home'),
        position: LatLng(23.7814561, 90.4215143),
        infoWindow: InfoWindow(
          title: 'My Home',
        )),
  ];

  var uuid = const Uuid();
  String sessionToken = '112233';
  RxList placesList = [].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    marker.addAll(list);
    searchText.value.addListener(() {
      onChange();
    });
    super.onInit();
  }

  double calculateBearing(LatLng start, LatLng end) {
    double deltaLongitude = end.longitude - start.longitude;
    double y = sin(deltaLongitude) * cos(end.latitude);
    double x = cos(start.latitude) * sin(end.latitude) -
        sin(start.latitude) * cos(end.latitude) * cos(deltaLongitude);
    double initialBearing = atan2(y, x);
    return (initialBearing * 180 / pi) % 360;
  }

// Load custom truck icon

  Future<BitmapDescriptor> _loadTruckIcon(BuildContext context) async {
    return await BitmapDescriptor.asset(
        ImageConfiguration(
            devicePixelRatio: MediaQuery.of(context).devicePixelRatio),
        "assets/icons/truckIcon.png",
      height: 70, width: 40
        );
  }
  
  setMarker(LatLng latLng, String placeId, String address) async {
    final BitmapDescriptor customMarker = await _loadTruckIcon(Get.context!);
    Marker newMarker = Marker(
      onTap: () {
      },
      infoWindow: InfoWindow(title: address.split(",")[0]),
      icon: customMarker,
      markerId: MarkerId(placeId), // Use a unique MarkerId for each marker
      position: LatLng(latLng.latitude, latLng.longitude),
      rotation: calculateBearing(LatLng(23.776176, 90.425674), LatLng(23.763999373281255, 90.4287651926279)),
    );

    marker.add(newMarker);
    update();
  }

  customMarker(
      {required String markerId,
      required double latitude,
      required double longitude,
      required String infoTitle,
      String? iconPath,
      double? width,
      double? height}) async {
    Marker(
        markerId: MarkerId(markerId),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: infoTitle,
        ),
        icon: await MarkerIcon.pictureAsset(
            assetPath: iconPath!, width: width!, height: height!));
  }

  void onChange() {
    sessionToken ??= uuid.v4();
    getSuggestion(searchText.value.text);
  }

  void getSuggestion(String inputText) async {
    String kPlacesApiKey = "AIzaSyDUjNaRwWEUbn__efy3duv9cFQak66jI4o";
    String baseURL =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String request =
        '$baseURL?input=$inputText&key=$kPlacesApiKey&sessiontoken= $sessionToken';

    var response = await http.get(Uri.parse(request));

    print(response.body.toString());
    if (response.statusCode == 200) {
      placesList.value = jsonDecode(response.body.toString())['predictions'];
    } else {
      print("--------------------- Error -------------------");
      throw Exception('Failed to load data');
    }
  }

  checkDataDoubleOrString() async {
    isTapped.value = true;
    List searchedCoOrdinates = [];
    List inputDataList = searchText.value.text.split(',');

    double? doubleValue = double.tryParse(inputDataList.first);
    print("+++++++++++++++++++++${searchText.value}++++++++++++++++++++");

    if (doubleValue != null) {
      placeAddress = await placemarkFromCoordinates(
          double.parse(inputDataList.first), double.parse(inputDataList.last));
      searchedCoOrdinates.addAll(inputDataList);
      print("Coordinate to locations:...........................${placeAddress.first}");
    } else {
      locationCoOrdinates = await locationFromAddress(searchText.value.text);
      searchedCoOrdinates.addAll(locationCoOrdinates);
      print("Locations to Coordinates:...............${locationCoOrdinates.first}..............${locationCoOrdinates.last}");
    }
    targetLatitude.value = searchedCoOrdinates.first;
    targetLongitude.value = searchedCoOrdinates.last;
    marker.add(
      Marker(
        markerId: MarkerId("Search Location"),
        position: LatLng(searchedCoOrdinates.first, searchedCoOrdinates.last),
        infoWindow: InfoWindow(
          title: "Searched Location"
          )
      ),
    );
    final GoogleMapController controller = await googleMapController.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(kRandom));
    isSearched.value = false;
    isTapped.value = false;
  }

  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) {
      print("Error ${error.toString()}");
    });
    return await Geolocator.getCurrentPosition();
  }

  getCurrentLocation() {
    getUserCurrentLocation().then((value) async {
      updateLocation(value.latitude, value.longitude);
      print(value.floor);
      print('My current location');
      print(
          "My Current Location:^^^^^^^^^^^^^^^^^^${value.latitude}, ${value.longitude}");

      List<Placemark> placemarks = await placemarkFromCoordinates(value.latitude, value.longitude);
      print("Placemarks: ============>>>>$placemarks");
      marker.add(Marker(
          markerId: MarkerId("My location"),
          position: LatLng(value.latitude, value.longitude),
          infoWindow: const InfoWindow(title: 'My current location')));
      final GoogleMapController controller = await googleMapController.future;
      await controller.animateCamera(CameraUpdate.newCameraPosition(kRandom));
    });
  }
}
