import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:ui' as ui;

import '../models/GameModel.dart';

class AutonPainter extends StatefulWidget {
  final Event event;
  final Team team;

  const AutonPainter({
    Key? key,
    required this.event,
    required this.team,
  }) : super(key: key);
  String getScope(){
    return scope;
  }
  @override
  _AutonPainterState createState() => _AutonPainterState(team, event);

}
final GlobalKey _key = GlobalKey();
double magicOffset=0.0;
double xLow=85.0, xHigh=xLow+300.0;
double yLow=0.0, yHigh=300.0;
double kCanvasSize = 800.0;
String _eKey="";
String scope="None";
double pointsLeft=0;
double pointsRight=0;
var accuracyMarks = <String>[" ","< 25%", "26-50%", "51-75%", ">75%"];
String dropdownValue=accuracyMarks.first;
var  _offsets = <Offset>[];
String pictureInfo="";
Uint8List temp=new Uint8List(0);
class _AutonPainterState extends State<AutonPainter> {
  Event event;
  Team team;
  _AutonPainterState(this.team, this.event);
  void clearPath() {
    setState(() {
      _offsets.clear();
    });
    pointsLeft=0;
    pointsRight=0;
  }
  void savePath() {
    print("Saving...");
    _takeScreenshot(); //Get picture
    dropdownValue=accuracyMarks.first;
    print("Uploaded!");
  }
  void _takeScreenshot() async {
    RenderRepaintBoundary boundary =
    _key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    if (boundary.debugNeedsPaint) {
      print("Waiting for boundary to be painted.");
      await Future.delayed(const Duration(milliseconds: 1000));
      return _takeScreenshot();
    }

    ui.Image image = await boundary.toImage();
    pictureInfo = image.toString();
    print(pictureInfo);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      Uint8List pngBytes = byteData.buffer.asUint8List();
      setState(() {
        uploadFile(pngBytes);
        //uploadFile2(image);
      });
    }
  }
  void setTeam(String? key){
    _eKey=key!;
  }
  void uploadFile(Uint8List image) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    if(pointsRight>0&&pointsLeft>0){
      scope="Both_Side";
    }else if(pointsLeft>(pointsRight)){
      scope="Blue_Side";
    }else if(pointsRight>(pointsLeft)){
      scope="Red_Side";
    }
    Reference ref = storage.ref().child('${_eKey} - ${team.number} - ${scope}.png');
    UploadTask uploadTask = ref.putData(image, SettableMetadata(contentType: 'image/png'));
    try{
      await uploadTask
          .whenComplete((){
        print('All Done');
      });
    }catch (e){
      print('something went wrong');
    }
    print(image);
    print(temp);
    String url = await ref.getDownloadURL();
  }
  void uploadFile2(ui.Image image) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    if(pointsRight>0&&pointsLeft>0){
      scope="Both_Side";
    }else if(pointsLeft>(pointsRight)){
      scope="Blue_Side";
    }else if(pointsRight>(pointsLeft)){
      scope="Red_Side";
    }
    Reference ref = storage.ref().child('${_eKey} - ${team.number} - ${scope}.svg');
    UploadTask uploadTask = ref.putData(temp, SettableMetadata(contentType: 'image/svg'));
    try{
      await uploadTask
          .whenComplete((){
        print('All Done');
      });
    }catch (e){
      print('something went wrong');
    }
    String url = await ref.getDownloadURL();
  }
  Widget build(BuildContext context) {
    setTeam(event.id);
    return RepaintBoundary(
        key: _key,
        child: Scaffold(
            resizeToAvoidBottomInset: true,
            body:SingleChildScrollView(
                child:Column(
                    children: <Widget>[
                      Container(
                        height: 350,
                        child: Stack(children: <Widget>[
                          Align(
                            alignment: Alignment.center,
                            child: Image.asset(
                              "assets/images/field.jpg",
                              height: 350,
                            ),
                          ),
                          GestureDetector(
                            onPanDown: (details) {
                              final localPosition = context.findRenderObject() as RenderBox;
                              final renderBox = localPosition.globalToLocal(details.globalPosition);
                              if(renderBox.dx<((xLow+xHigh)/2)){
                                pointsLeft++;
                              }else if(renderBox.dx>((xLow+xHigh)/2)){
                                pointsRight++;
                              }
                              if(renderBox.dx>=xLow&&renderBox.dy>=yLow&&renderBox.dx<=xHigh&&renderBox.dy<=yHigh) {
                                setState(() {
                                  _offsets.add(renderBox);
                                });
                              }
                            },
                            onPanUpdate: (details) {
                              final localPosition = context.findRenderObject() as RenderBox;
                              final renderBox = localPosition.globalToLocal(details.globalPosition);
                              if(renderBox.dx<((xLow+xHigh)/2)){
                                pointsLeft++;
                              }else if(renderBox.dx>((xLow+xHigh)/2)){
                                pointsRight++;
                              }
                              if(renderBox.dx>=xLow&&renderBox.dy>=yLow&&renderBox.dx<=xHigh&&renderBox.dy<=yHigh) {
                                setState(() {
                                  _offsets.add(renderBox);
                                });
                              }
                            },),
                          CustomPaint(size: const ui.Size(0.0, 0.0), painter: PainterPen(_offsets)),
                        ],),
                      ),
                      Container(
                        child: Row(
                          children: <Widget>[
                            IconButton(
                                onPressed: savePath,
                                icon: const Icon(Icons.cloud)
                            ),
                            const Spacer(flex: 1),
                            DropdownButton(
                                value: dropdownValue,
                                items: accuracyMarks.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  // This is called when the user selects an item.
                                  setState(() {
                                    dropdownValue = value!;
                                  });
                                }),
                            const Spacer(flex: 1),
                            IconButton(
                              onPressed: clearPath,
                              icon: const Icon(Icons.clear_sharp),
                            ),
                          ],
                        ),
                      ),
                    ]
                )
            )
        )
    );
  }
}
class PainterPen extends CustomPainter {
  final List<Offset> offsets;

  PainterPen(this.offsets) : super();

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..isAntiAlias = true
      ..strokeWidth = 3.0;
    for (var index = 1; index < offsets.length; ++index) {
      if (offsets[index - 1] != null && offsets[index] != null) {
        Offset a = Offset(
            offsets[index - 1].dx, offsets[index - 1].dy - magicOffset);
        Offset b = Offset(offsets[index].dx, offsets[index].dy - magicOffset);
        canvas.drawLine(a, b, paint);
      }
      else if (offsets[index - 1] != null && offsets[index] == null) {
        Offset a = Offset(
            offsets[index - 1].dx, offsets[index - 1].dy - magicOffset);
        canvas.drawPoints(
            PointMode.points,
            [a],
            paint
        );
      }
      temp = canvas.getTransform().buffer.asUint8List();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}