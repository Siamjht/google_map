

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  TextEditingController searchTextController = TextEditingController();
  var uuid = Uuid();
  String sessionToken = '112233';
  List<dynamic> placesList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    searchTextController.addListener((){
      onChange();
    });
  }

  void onChange(){
    if(sessionToken == null){
      setState(() {
        sessionToken = uuid.v4();
      });
    }
    getSuggestion(searchTextController.text);
  }

  void getSuggestion(String inputText) async{
    String kPlacesApiKey = "AIzaSyDUjNaRwWEUbn__efy3duv9cFQak66jI4o";
    String baseURL ='https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String request = '$baseURL?input=$inputText&key=$kPlacesApiKey&sessiontoken= $sessionToken';

    var response = await http.get(Uri.parse(request));

    print(response.body.toString());
    if(response.statusCode == 200){
      placesList = jsonDecode(response.body.toString()) ['predictions'];
    }else{
      throw Exception('Failed to load data');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Google Maps Api"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              controller: searchTextController,
              decoration: const InputDecoration(
                  hintText: 'Search places here...'
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: placesList.length,
                itemBuilder: (context, index){
                  return ListTile(
                    onTap: ()async{
                      List<Location> locations = await locationFromAddress(placesList[index]['description']);
                      print("${locations.last.latitude},${locations.last.longitude}");
                      setState(() {

                      });
                    },
                    title: Text(placesList[index]['description']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
