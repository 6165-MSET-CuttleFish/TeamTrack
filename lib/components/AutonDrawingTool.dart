import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/rendering.dart';

import 'dart:ui' as ui;

import '../models/GameModel.dart';

class AutonPainter extends StatefulWidget {
  final Team team;

  const AutonPainter({
    Key? key,
    required this.team,
  }) : super(key: key);

  @override
  _AutonPainterState createState() => _AutonPainterState(team);
}
final GlobalKey _key = GlobalKey();
double magicOffset=0.0;
double xLow=50.0, xHigh=290.0;
double yLow=10.0, yHigh=250.0;
double kCanvasSize = 800.0;
String _teamNumber="6165";
String scope="Carousel";
double pointsLeft=0;
double pointsRight=0;
var  _offsets = <Offset>[];
class _AutonPainterState extends State<AutonPainter> {
  Team team;
  _AutonPainterState(this.team);
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
    print("Uploaded!");
  }
  void _takeScreenshot() async {
    RenderRepaintBoundary boundary =
    _key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    if (boundary.debugNeedsPaint) {
      print("Waiting for boundary to be painted.");
      await Future.delayed(const Duration(milliseconds: 20));
      return _takeScreenshot();
    }

    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      Uint8List pngBytes = byteData.buffer.asUint8List();
      setState(() {
        uploadFile(pngBytes);
      });
    }
  }
  void setTeam(String team){
    _teamNumber=team;
  }
  void uploadFile(Uint8List image) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    if(pointsLeft-pointsRight>(pointsRight+pointsLeft)/2+10){
      scope="Carousel";
    }else if(pointsLeft-pointsRight<(pointsRight+pointsLeft)/2-10){
      scope="Cycling";
    }else{
      scope="Both";
    }
    Reference ref = storage.ref().child('${_teamNumber} - ${scope}.svg');
    UploadTask uploadTask = ref.putData(image, SettableMetadata(contentType: 'image/svg'));
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
    setTeam(team.number);
    return RepaintBoundary(
        key: _key,
        child: Scaffold(
            resizeToAvoidBottomInset: true,
            body:SingleChildScrollView(
                child:Column(
                    children: <Widget>[
                      Container(
                        height: 250,
                        child: Stack( children: <Widget>[
                          Opacity(opacity: 1,child: Image.asset('assets/images/field.jpg')),
                          GestureDetector(
                            onPanDown: (details) {
                              final localPosition = context.findRenderObject() as RenderBox;
                              final renderBox = localPosition.globalToLocal(details.globalPosition);
                              if(renderBox.dx<((xLow+xHigh)/2)){
                                pointsLeft++;
                              }else{
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
                              }else{
                                pointsRight++;
                              }
                              if(renderBox.dx>=xLow&&renderBox.dy>=yLow&&renderBox.dx<=xHigh&&renderBox.dy<=yHigh) {
                                setState(() {
                                  _offsets.add(renderBox);
                                });
                              }
                            },),
                          CustomPaint(size: const Size(0.0, 0.0), painter: PainterPen(_offsets)),
                        ],),
                      ),
                      Container(
                          child: Row(
                            children: <Widget>[
                              IconButton(
                                  onPressed: savePath,
                                  icon: const Icon(Icons.cloud)
                              ),
                              const Spacer(flex: 2),
                              IconButton(
                                onPressed: clearPath,
                                icon: const Icon(Icons.clear_sharp),
                              ),
                            ],
                          )
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
  void paint(Canvas canvas, Size size) {
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
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}