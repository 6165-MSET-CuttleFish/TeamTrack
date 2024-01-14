import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/util/Permissions.dart';
import 'package:provider/provider.dart';

class ImageView extends StatefulWidget {

  const ImageView({
    super.key,
    required this.event,

  });
  final Event event;

  @override
  State<ImageView> createState() => _ImageViewState();
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
class _ImageViewState extends State<ImageView> {

  File ? imageFile;

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
  _getFromGallery() async {
    print("OIEJOFEJW");
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {

        imageFile = File(pickedFile.path);
      });
    }

  }
  _getFromCamera() async {
    print("af");
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      print(pickedFile.path);
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller!.dispose();
    super.dispose();
  }
  Widget build(BuildContext context) => Scaffold(
  appBar: AppBar(
    title: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text("Import Match Schedule")
    ),
    backgroundColor: Theme.of(context).colorScheme.primary,
    leading:
      IconButton(onPressed: (){Navigator.of(context).pop();}, icon: Icon(Icons.arrow_back)),

      actions:[
        IconButton(onPressed:_getFromCamera,icon:Icon(Icons.camera_alt)),
        IconButton(onPressed:_getFromGallery,icon:Icon(Icons.photo_size_select_large))
      ]
  )
    ,
    body: imageFile!=null ? Column(
        children:[
          SizedBox(

            height:MediaQuery.of(context).size.height*.8,
     width: MediaQuery.of(context).size.width,
     child: FittedBox(
       fit: BoxFit.fill,
              child: Center(child:Image.file(imageFile!))
      )
          ),
          IconButton(onPressed:() async {
        await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnalyzingDataScreen(
          // Pass the automatically generated path to
          // the DisplayPictureScreen widget.
          imagePath: imageFile!.path,
          event: widget.event
        ),
      ),
    );}
    ,icon:
        Icon(Icons.arrow_circle_right_outlined)
    )]) : Center(child:Text("Select a photo above to begin"))

  );
}
var recognizedText;
List<String> redOne = [];
List<String> redTwo = [];
List<String> blueOne = [];
List<String> blueTwo = [];
var returnedState = "No Response, try again!";

class AnalyzingDataScreen extends StatefulWidget {
  final String imagePath;
  final Event event;
  const AnalyzingDataScreen({
    super.key,
    required this.imagePath,
    required this.event});

  @override
  State<AnalyzingDataScreen> createState() => _AnalyzingDataState();
}
bool _isNumeric(String str) {
  if(str == null) {
    return false;
  }
  return double.tryParse(str) != null;
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
      body: redOne.isNotEmpty?Center(
          child:Text(returnedState)):
      Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
    children:[
      PlatformProgressIndicator(),
      SizedBox(
        height: 20,
      ),
      Text("Hold On, We're Processing your Image"),
              ]
          )
      )
    );
  }
  Future<void> _processImage(InputImage inputImage) async {

     returnedState = "No Response, try again!";
    redOne = [];
    redTwo = [];
    blueOne = [];
    blueTwo = [];
    var _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    recognizedText = await _textRecognizer.processImage(inputImage);
    print(recognizedText.blocks.length);
int z = 0;
    for(TextBlock x in recognizedText.blocks) {
      for (TextLine y in x.lines) {
        if (y.text == "Red 1") {
          z = 1;
        }
        if (y.text == "Red 2") {
          z = 2;
        }
        if (y.text == "Blue 1") {
          z = 3;
        }
        if (y.text == "Blue 2") {
          z = 4;
        }
        var text = y.text;
        print(y.text);
        if (text.endsWith("*")) {
          text = text.substring(0, text.length - 2);
        }
        if (_isNumeric(text)) {
          if (z == 1) {
            redOne.add(text);
          }
          if (z == 2) {
            redTwo.add(text);
          }

          if (z == 3) {
            blueOne.add(text);
          }
          if (z == 4) {
            blueTwo.add(text);
          }
        }
      }
    }
  if(blueOne.length==redTwo.length&&redOne.length==blueTwo.length&&redTwo.length==blueTwo.length){
  for (int row = 0; row<blueOne.length;row++) {
      setState(() {
        widget.event.addMatch(
          Match(
            Alliance(
              widget.event.teams.findAdd(
                  redOne[row],
                  "Number DNE",
                  widget.event),
              widget.event.teams.findAdd(
                  redTwo[row],
                  "Number DNE",
                  widget.event),
              widget.event.type,
              widget.event.gameName,
            ),
            Alliance(
              widget.event.teams.findAdd(
                  blueOne[row],
                  "Number DNE",
                  widget.event),
              widget.event.teams.findAdd(
                  blueTwo[row],
                  "Number DNE",
                  widget.event),
              widget.event.type,
              widget.event.gameName,
            ),
            widget.event.type,
          ),
        );
      });
    }
  setState(() {});
  dataModel.saveEvents();
  returnedState = "Completed succesfully. Return to Events!";
  }else{
    returnedState = "Numbers did not match, try again!";
  }


    print(redOne);
    print(redTwo);
    print(blueOne);
    print(blueTwo);
    setState(() {});
  }
}