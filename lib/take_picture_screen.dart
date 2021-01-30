import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exif_plugin/flutter_exif_plugin.dart';
import 'package:latlong/latlong.dart';

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  final LatLng location;

  const TakePictureScreen({
    Key key,
    @required this.location,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: () async {
          try {
            await _initializeControllerFuture;

            XFile photo = await _controller.takePicture();
            final exif = FlutterExif.fromPath(photo.path);

            await exif.setLatLong(
                widget.location.latitude, widget.location.longitude);

            await exif.saveAttributes();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DisplayPictureScreen(imagePath: photo.path),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Display the Picture')),
        body: Stack(children: [
          Image.file(File(imagePath)),
          FutureBuilder(
            future: FlutterExif.fromPath(imagePath).getLatLong(),
            builder: (_, snapshot) => Positioned(
                left: 0,
                top: 0,
                height: 30,
                right: 0,
                child: snapshot.hasData
                    ? Text(
                        snapshot.data.toString(),
                        style: TextStyle(color: Colors.black),
                      )
                    : null),
          )
        ]));
  }
}
