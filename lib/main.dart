import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  Location location = Location();
  Set<Marker> markers = Set<Marker>();
  late LatLng destination;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  _getUserLocation() async {
    try {
      var userLocation = await location.getLocation();
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(userLocation.latitude!, userLocation.longitude!),
            zoom: 15.0,
          ),
        ),
      );
    } catch (e) {
      print('Error: $e');
    }
  }

  _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  _navigate() async {
    var selectedDestination = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationInputScreen(),
      ),
    );

    if (selectedDestination != null) {
      setState(() {
        destination = selectedDestination;
        markers = Set<Marker>.from([
          Marker(
            markerId: MarkerId('origin'),
            position:
                LatLng(0.0, 0.0), // ตำแหน่งเริ่มต้น (ไม่มีการแสดงบนแผนที่)
            icon: BitmapDescriptor.defaultMarker,
          ),
          Marker(
            markerId: MarkerId('destination'),
            position: destination,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        ]);
      });

      _startNavigation();
    }
  }

  _startNavigation() async {
    var userLocation = await location.getLocation();
    var origin = LatLng(userLocation.latitude!, userLocation.longitude!);

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            min(origin.latitude, destination.latitude),
            min(origin.longitude, destination.longitude),
          ),
          northeast: LatLng(
            max(origin.latitude, destination.latitude),
            max(origin.longitude, destination.longitude),
          ),
        ),
        100.0,
      ),
    );

    // นำทางด้วย Google Maps
    // ในตัวอย่างนี้จะให้นำทางด้วยการเดิน
    // คุณสามารถปรับเปลี่ยนเป็นรถหรือระบุวิธีการนำทางอื่น ๆ ตามต้องการ
    String url =
        'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=walking';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps Navigation'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        myLocationEnabled: true,
        markers: markers,
        initialCameraPosition: CameraPosition(
          target: LatLng(0.0, 0.0),
          zoom: 2.0,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigate,
        child: Icon(Icons.navigation),
      ),
    );
  }
}

class DestinationInputScreen extends StatelessWidget {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Destination'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _latController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Latitude'),
            ),
            TextField(
              controller: _lngController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Longitude'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                var lat = double.tryParse(_latController.text);
                var lng = double.tryParse(_lngController.text);

                if (lat != null && lng != null) {
                  Navigator.pop(
                    context,
                    LatLng(lat, lng),
                  );
                } else {
                  // Handle invalid input
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Invalid Input'),
                      content:
                          Text('Please enter valid latitude and longitude.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text('Navigate'),
            ),
          ],
        ),
      ),
    );
  }
}
