import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/Change.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:uuid/uuid.dart';
import 'package:date_format/date_format.dart';

class ChangeConfig extends StatefulWidget {
  const ChangeConfig(
      {Key? key, required this.team, this.change, required this.event})
      : super(key: key);
  final Team team;
  final Change? change;
  final Event event;
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
        title:
            Text(widget.change == null ? 'New Change' : widget.change!.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
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
                Text('-'),
                Text(
                  _finalDate != null
                      ? formatDate(
                          _finalDate!,
                          [
                            mm,
                            '/',
                            dd,
                            '/',
                            yyyy,
                          ],
                        )
                      : "Present",
                ),
              ],
            ),
          ),
          PlatformButton(
            child: Text('Start Date'),
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
            child: Text('End Date (Optional)'),
            onPressed: () => showDatePicker(
              context: context,
              initialDate: _finalDate ?? DateTime.now(),
              firstDate: _startDate,
              lastDate: DateTime.now(),
            ).then(
              (date) => setState(
                () {
                  _finalDate = date;
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
            child: Text('Save'),
            onPressed: () async {
              if (widget.change == null) {
                widget.event.addChange(
                  Change(
                    title: controller.text,
                    startDate: Timestamp.fromDate(_startDate),
                    id: Uuid().v4(),
                  ),
                  widget.team,
                );
              } else {
                widget.change?.title = controller.text;
                widget.change?.startDate = Timestamp.fromDate(_startDate);
                if (_finalDate != null)
                  widget.change?.endDate = Timestamp.fromDate(_finalDate!);
                if (widget.event.shared)
                  widget.event.addChange(widget.change!, widget.team);
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
