import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:geo_location/geo_location.dart';
import 'package:latlong/latlong.dart';
import 'package:location_permissions/location_permissions.dart';

import 'take_picture_screen.dart';

extension Stringify on LatLng {
  String toPretty() => "lat: ${this.latitude}, lng: ${this.longitude}";
}

List<CameraDescription> cameras = [];
final mobileImage = Image.asset('assets/mobile.png');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  double zoom = 10;
  LatLng currentPosition;

  MapController controller = MapControllerImpl();

  LocationCallback locationCallback;

  void _incrementCounter() {
    zoom++;
    move();
  }

  void move() {
    controller.move(currentPosition, zoom);
  }

  Function _takePicture(BuildContext context) => () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => TakePictureScreen(
                  camera: cameras.first,
                  location: currentPosition,
                )));
      };

  @override
  void initState() {
    super.initState();
    locationCallback = (loc) {
      setState(() {
        final newLat = LatLng(loc.lat, loc.long);
        if (currentPosition != newLat) {
          currentPosition = newLat;
          move();
        }
      });
    };
    GeoLocation.init();
    GeoLocation.addListener(locationCallback);
    _takeGeoLocation();
  }

  @override
  void dispose() {
    controller = null;
    GeoLocation.removeListener(locationCallback);
    super.dispose();
  }

  Future<void> _takeGeoLocation() async {
    try {
      PermissionStatus permission =
          await LocationPermissions().checkPermissionStatus();

      if (permission != PermissionStatus.granted) {
        permission = await LocationPermissions().requestPermissions(
            permissionLevel: LocationPermissionLevel.location);
      }

      if (permission == PermissionStatus.granted) {
        ServiceStatus status = await LocationPermissions()
            .checkServiceStatus(level: LocationPermissionLevel.location);

        if (status != ServiceStatus.enabled) {
          return print('Service not enabled');
        }

        final loc = await GeoLocation.getCurrentLocation();

        setState(() {
          currentPosition = LatLng(loc.lat, loc.long);
          controller.move(currentPosition, zoom);
        });
      } else {
        print("service not granted");
      }
    } catch (e) {
      print('here');
    }
  }

  void _decrementCounter() {
    zoom--;
    move();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${currentPosition?.toPretty() ?? "not founded"}"),
      ),
      body: FlutterMap(
        mapController: controller,
        options: MapOptions(center: currentPosition, zoom: 10),
        layers: [
          TileLayerOptions(
              backgroundColor: Colors.transparent,
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c']),
          MarkerLayerOptions(
            markers: [
              if (currentPosition != null)
                Marker(
                  width: 20.0,
                  height: 20.0,
                  point: currentPosition,
                  builder: (ctx) => Container(child: mobileImage),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: cameras.isEmpty || currentPosition == null ? 180 : 240,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RaisedButton(
              onPressed: _takeGeoLocation,
              child: Icon(Icons.policy),
            ),
            if (cameras.isNotEmpty && currentPosition != null)
              RaisedButton(
                onPressed: _takePicture(context),
                child: Icon(Icons.camera_alt),
              ),
            RaisedButton(
              onPressed: _incrementCounter,
              child: Icon(Icons.add),
            ),
            RaisedButton(
              onPressed: _decrementCounter,
              child: Icon(Icons.remove),
            ),
          ],
        ),
      ),
    );
  }
}
