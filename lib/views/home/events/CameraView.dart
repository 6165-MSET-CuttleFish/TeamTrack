import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/util/Permissions.dart';
import 'package:provider/provider.dart';

class CameraView extends StatefulWidget {

  const CameraView({
    super.key,
    required this.event,

  });
  final Event event;

  @override
  State<CameraView> createState() => _CameraViewState();
}
Widget _liveFeed(){
  if (_cameras.isEmpty) return Container(

      child: Center(child: PlatformProgressIndicator())
  );
  if (_controller == null) return Container(child: Center(child: PlatformProgressIndicator()));
  if (_controller?.value.isInitialized == false) return Container(child: Center(child: PlatformProgressIndicator()));
  return Container(
    color: Colors.black,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Center(
          child: CameraPreview(
              _controller!
          ),
        ),
      ],
    ),
  );
}
late CameraController? _controller;
List<CameraDescription> _cameras=[];
class _CameraViewState extends State<CameraView> {

  int _cameraIndex = -1;
  void _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.back) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _controller = CameraController(
        // Get a specific camera from the list of available cameras.
        _cameras[_cameraIndex],
        // Define the resolution to use.
        ResolutionPreset.medium,
      );
      _controller?.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    }

  }

  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller!.dispose();
    super.dispose();
  }
  Widget build(BuildContext context) => Scaffold(
  appBar: AppBar(
    title: Text("Import Match Schedule"),
    backgroundColor: Theme.of(context).colorScheme.primary,
    leading:
      IconButton(onPressed: (){Navigator.of(context).pop();}, icon: Icon(Icons.arrow_back)),
  ),
    body: _controller!=null?_liveFeed():Text("bruh"),
  floatingActionButton: FloatingActionButton(
  // Provide an onPressed callback.
  onPressed: () async {
  // Take the Picture in a try / catch block. If anything goes wrong,
  // catch the error.
  try {
  // Ensure that the camera is initialized.
  await _controller;

  // Attempt to take a picture and get the file `image`
  // where it was saved.
  final image = await _controller!.takePicture();

  if (!mounted) return;

  // If the picture was taken, display it on a new screen.
  await Navigator.of(context).push(
  MaterialPageRoute(
  builder: (context) => AnalyzingDataScreen(
  // Pass the automatically generated path to
  // the DisplayPictureScreen widget.
  imagePath: image.path,
  ),
  ),
  );
  } catch (e) {
  // If an error occurs, log the error to the console.
  print(e);
  }
  },
  child: const Icon(Icons.camera_alt),
  ),

  );
}
var recognizedText;
class AnalyzingDataScreen extends StatefulWidget {
  final String imagePath;

  const AnalyzingDataScreen({super.key, required this.imagePath});

  @override
  State<AnalyzingDataScreen> createState() => _AnalyzingDataState();
}
class _AnalyzingDataState extends State<AnalyzingDataScreen>{
  void initState(){
    _processImage(InputImage.fromFile(File(widget.imagePath)));
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyzing Matches')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: recognizedText!=null?Text(recognizedText.text):PlatformProgressIndicator()
    );
  }
  Future<void> _processImage(InputImage inputImage) async {
    var _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    recognizedText = await _textRecognizer.processImage(inputImage);
    setState(() {});
  }
}
