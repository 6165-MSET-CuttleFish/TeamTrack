import 'package:flutter/material.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/logic/backend.dart';

class MatchConfig extends StatefulWidget {
  const MatchConfig({Key? key, required this.event}) : super(key: key);
  final Event event;
  @override
  _MatchConfigState createState() => _MatchConfigState();
}

class _MatchConfigState extends State<MatchConfig> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Match'),
        backgroundColor: Theme.of(context).accentColor,
      ),
      body: SafeArea(
        child: Center(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.only(left: 5, right: 5),
              child: ListView(
                children: _textFields(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final List<TextEditingController> controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final names = ['', '', '', ''];
  final _formKey = GlobalKey<FormState>();
  List<Widget> _textFields() {
    var list = <Widget>[];
    for (int i = 0; i < 4; i++) {
      if (i == 0) {
        list.add(
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.transparent,
                width: 6,
              ),
              borderRadius: BorderRadius.circular(60),
              color: Colors.red,
            ),
            alignment: Alignment.center,
            child: Text(
              'Red Alliance',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
        );
      } else if (i == 2) {
        list.add(
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.transparent,
                width: 6,
              ),
              borderRadius: BorderRadius.circular(60),
              color: Colors.blue,
            ),
            alignment: Alignment.center,
            child: Text(
              'Blue Alliance',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
        );
      }
      list.add(
        Row(
          children: [
            Expanded(
              child: TextFormField(
                autofillHints: widget.event.teams.keys,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Team number'),
                validator: (String? value) {
                  if (names[i].isEmpty) {
                    return 'Number is required';
                  } else {
                    return null;
                  }
                },
                onChanged: (String val) {
                  setState(
                    () {
                      names[i] = val.split('').reduce((value, element) =>
                          int.tryParse(element) != null
                              ? value += element
                              : value = value);
                      controllers[i].value = TextEditingValue(
                        text: widget.event.teams[names[i]]?.name ?? '',
                        selection: TextSelection.fromPosition(
                          TextPosition(offset: val.length),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controllers[i],
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (String? value) {
                  if (value?.isEmpty ?? false)
                    return 'Name is required';
                  else
                    return null;
                },
                onChanged: (String val) {
                  setState(
                    () {
                      controllers[i].value = TextEditingValue(
                        text: val,
                        selection: TextSelection.fromPosition(
                          TextPosition(offset: val.length),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    list.add(
      PlatformButton(
        color: Colors.green,
        child: Text('Save'),
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            setState(
              () {
                widget.event.addMatch(
                  Match(
                    Alliance(
                      widget.event.teams
                          .findAdd(names[0], controllers[0].text, widget.event),
                      widget.event.teams
                          .findAdd(names[1], controllers[1].text, widget.event),
                      widget.event.type,
                      widget.event.gameName,
                    ),
                    Alliance(
                      widget.event.teams
                          .findAdd(names[2], controllers[2].text, widget.event),
                      widget.event.teams
                          .findAdd(names[3], controllers[3].text, widget.event),
                      widget.event.type,
                      widget.event.gameName,
                    ),
                    widget.event.type,
                  ),
                );
              },
            );
            for (TextEditingController controller in controllers) {
              controller.text = '';
            }
            dataModel.saveEvents();
            Navigator.pop(context);
          }
        },
      ),
    );
    return list;
  }
}
