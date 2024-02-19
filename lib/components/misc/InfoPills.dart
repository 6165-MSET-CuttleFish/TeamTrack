import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InfoPills extends StatelessWidget {

  final String text;
  final Color color;
  const InfoPills(
      {
        super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) =>
  Padding(
    padding: EdgeInsets.fromLTRB(0, 5, 5, 5),
     child: Container(
  decoration: BoxDecoration(
  color: color,
    borderRadius: BorderRadius.circular(12),
  ),
        child:Padding(
  padding: EdgeInsets.fromLTRB(8, 3, 8, 3),child:Text(text,style: Theme.of(context).textTheme.bodySmall?.apply(color: Colors.white),textScaleFactor: .9,)),
      ));
}