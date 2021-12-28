import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/Change.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:uuid/uuid.dart';
import 'package:date_format/date_format.dart';

class ChangeConfig extends StatefulWidget {
  const ChangeConfig({Key? key, this.team, this.change}) : super(key: key);
  final Team? team;
  final Change? change;
  @override
  _ChangeConfigState createState() => _ChangeConfigState(change);
}

class _ChangeConfigState extends State<ChangeConfig> {
  _ChangeConfigState(Change? change) {
    _startDate = change?.startDate.toDate() ?? DateTime.now();
    _finalDate = change?.endDate?.toDate();
    controller.text = change?.title ?? '';
  }
  final controller = TextEditingController();
  var _startDate = DateTime.now();
  DateTime? _finalDate;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: PlatformText(
            widget.change == null ? 'New Change' : widget.change!.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                PlatformText(
                  formatDate(
                    _startDate,
                    [
                      mm,
                      '/',
                      dd,
                      '/',
                      yyyy,
                    ],
                  ),
                ),
                if (_finalDate != null) PlatformText('-'),
                if (_finalDate != null)
                  PlatformText(
                    formatDate(
                      _finalDate!,
                      [
                        mm,
                        '/',
                        dd,
                        '/',
                        yyyy,
                      ],
                    ),
                  ),
              ],
            ),
          ),
          PlatformButton(
            child: PlatformText('Start Date'),
            onPressed: () => showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime(2020, 1, 1),
              lastDate: DateTime.now(),
            ).then(
              (date) => setState(
                () {
                  if (date != null) _startDate = date;
                },
              ),
            ),
            color: Colors.blue,
          ),
          PlatformButton(
            child: PlatformText('End Date'),
            onPressed: () => showDatePicker(
              context: context,
              initialDate: _finalDate ?? DateTime.now(),
              firstDate: _startDate,
              lastDate: DateTime.now(),
            ).then(
              (date) => setState(
                () {
                  if (date != null) _finalDate = date;
                },
              ),
            ),
            color: Colors.red,
          ),
          PlatformTextField(
            keyboardType: TextInputType.name,
            controller: controller,
            placeholder: 'Name',
          ),
          PlatformButton(
            child: PlatformText('Save'),
            onPressed: () {
              if (widget.change == null) {
                widget.team?.addChange(
                  Change(
                    title: controller.text,
                    startDate: Timestamp.fromDate(_startDate),
                    id: Uuid().v4(),
                  ),
                );
              } else {
                widget.change?.title = controller.text;
                widget.change?.startDate = Timestamp.fromDate(_startDate);
                if (_finalDate != null)
                  widget.change?.endDate = Timestamp.fromDate(_finalDate!);
              }
              controller.clear();
              _startDate = DateTime.now();
              dataModel.saveEvents();
              Navigator.pop(context);
            },
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}
