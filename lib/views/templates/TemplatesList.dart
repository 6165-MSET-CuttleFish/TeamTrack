import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/material.dart';

class TemplatesList extends StatefulWidget {
  TemplatesList({Key? key}) : super(key: key);

  @override
  _TemplatesListState createState() => _TemplatesListState();
}

class _TemplatesListState extends State<TemplatesList> {
  final slider = SlidableStrechActionPane();
  @override
  Widget build(BuildContext context) {
    var collectionRef = firebaseFirestore.collection('templates');
    return FutureBuilder<QuerySnapshot>(
      future: collectionRef.get(),
      builder: (context, query) {
        return PlatformProgressIndicator();
      },
    );
  }
}
