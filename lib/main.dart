import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Map Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static String API_KEY = "YOUR_API_KEY";
  Completer<GoogleMapController> _mapController = Completer();
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: API_KEY);
  GoogleMapController mapController;

  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  final Set<Marker> _markers = {};
  LatLng latLng_1;
  LatLng latLng_2;
  String location1 = "Pick 1st Location";
  String location2 = "Pick 2nd Location";
  static const LatLng _center =
      const LatLng(-6.986076045651891, 107.58459348231554);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            markers: _markers,
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(target: _center, zoom: 10.0),
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
          ),
          Positioned(
            top: 60,
            left: MediaQuery.of(context).size.width * 0.05,
            // width: MediaQuery.of(context).size.width * 0.9,
            child: RaisedButton(
              child: Text(location1),
              onPressed: () {
                setState(() {
                  _handlePressButton("1");
                });
              },
            ),
          ),
          Positioned(
            top: 120,
            left: MediaQuery.of(context).size.width * 0.05,
            // width: MediaQuery.of(context).size.width * 0.9,
            child: RaisedButton(
              child: Text(location2),
              onPressed: () {
                setState(() {
                  _handlePressButton("2");
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void onError(PlacesAutocompleteResponse response) {
    homeScaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }

  Future<void> _handlePressButton(String pos) async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    Prediction p = await PlacesAutocomplete.show(
      context: context,
      apiKey: API_KEY,
      onError: onError,
      mode: Mode.overlay,
      language: "id",
      components: [Component(Component.country, "id")],
    );

    displayPrediction(p, homeScaffoldKey.currentState, pos);
  }

  Future<Null> displayPrediction(
      Prediction p, ScaffoldState scaffold, String position) async {
    if (p != null) {
      // get detail (lat/lng)
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);
      final lat = detail.result.geometry.location.lat;
      final lng = detail.result.geometry.location.lng;

      final GoogleMapController controller = await _mapController.future;
      if (position == "1") {
        _markers.clear();
        latLng_1 = LatLng(lat, lng);
        addMarker(latLng_1, "${p.description}", "First Marker");
        controller.animateCamera(CameraUpdate.newLatLng(latLng_1));
        location1 = "${p.description}";
        location2 = "Pick 2nd Location";
        setState(() {});
      } else if (position == "2") {
        latLng_2 = LatLng(lat, lng);
        addMarker(latLng_2, "${p.description}", "Second Marker");
        location2 = "${p.description}";
        setState(() {});

        double lat1 = latLng_1.latitude;
        double lng1 = latLng_1.longitude;
        double lat2 = latLng_2.latitude;
        double lng2 = latLng_2.longitude;
        // Find south west and north east position from available marker
        double latSW, lngSW, latNE, lngNE;
        if (lat1 > lat2) {
          latSW = lat2;
          latNE = lat1;
        } else {
          latSW = lat1;
          latNE = lat2;
        }
        if (lng1 > lng2) {
          lngSW = lng2;
          lngNE = lng1;
        } else {
          lngSW = lng1;
          lngNE = lng2;
        }

        LatLngBounds bound = LatLngBounds(
            southwest: LatLng(latSW, lngSW), northeast: LatLng(latNE, lngNE));
        mapController = controller;
        CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound, 50);
        this.mapController.animateCamera(u2);
      }
    }
  }

  void addMarker(LatLng mLatLng, String mTitle, String mDescription) {
    _markers.add(Marker(
      // This marker id can be anything that uniquely identifies each marker.
      markerId:
          MarkerId((mTitle + "_" + _markers.length.toString()).toString()),
      position: mLatLng,
      infoWindow: InfoWindow(
        title: mTitle,
        snippet: mDescription,
      ),
      icon: BitmapDescriptor.defaultMarker,
    ));
  }
}
