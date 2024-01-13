
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_app/controller/map_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {


  final mapController = Get.put(MapController());
  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(23.769423999999997,90.41428529999999),
      tilt: 59.440717697143555,
      zoom: 18);


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
