import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/Change.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:uuid/uuid.dart';
import 'package:date_format/date_format.dart';

class ChangeConfig extends StatefulWidget {
  const ChangeConfig({Key? key, required this.team}) : super(key: key);
  final Team team;
  @override
  _ChangeConfigState createState() => _ChangeConfigState();
}

class _ChangeConfigState extends State<ChangeConfig> {
  final controller = TextEditingController();
  var _date = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Change'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        children: [
          Text(formatDate(_date, [dd, '/', mm, '/', yyyy, ' ', HH, ':', nn])),
          PlatformButton(
            child: Text('Date'),
            onPressed: () => showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2020, 1, 1),
              lastDate: DateTime.now(),
            ).then(
              (date) => setState(() => _date = date ?? DateTime.now()),
            ),
            color: Colors.blue,
          ),
          PlatformTextField(
            keyboardType: TextInputType.name,
            controller: controller,
            placeholder: 'Name',
          ),
          PlatformButton(
            child: Text('Save'),
            onPressed: () {
              widget.team.addChange(
                Change(
                  title: controller.text,
                  startDate: Timestamp.fromDate(_date),
                  id: Uuid().v4(),
                ),
              );
              controller.clear();
              _date = DateTime.now();
              Navigator.pop(context);
            },
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}
