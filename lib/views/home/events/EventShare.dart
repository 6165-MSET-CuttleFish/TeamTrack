import 'dart:convert';
import 'package:firebase_database/firebase_database.dart' as Database;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/util/Permissions.dart';

class EventShare extends StatefulWidget {
  const EventShare({
    Key? key,
    required this.emailController,
    required this.event,
  }) : super(key: key);
  final TextEditingController emailController;
  final Event event;
  @override
  _EventShareState createState() => _EventShareState();
}

Role shareRole = Role.editor;

class _EventShareState extends State<EventShare> {
  EmailContact? _emailContact;
  @override
  Widget build(BuildContext context) => StreamBuilder<Database.Event>(
        stream: widget.event.getRef()?.onValue,
        builder: (context, eventHandler) {
          if (eventHandler.hasData && !eventHandler.hasError) {
            widget.event.updateLocal(
              json.decode(
                json.encode(eventHandler.data?.snapshot.value),
              ),
              context,
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: PlatformText(
                'Share Event',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            body: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _onPressed,
                      tooltip: 'Select Contact',
                      icon: Icon(Icons.contact_mail),
                    ),
                    Expanded(
                      child: PlatformTextField(
                        textInputAction: TextInputAction.done,
                        placeholder: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        controller: widget.emailController,
                        autoCorrect: false,
                      ),
                    ),
                  ],
                ),
                PlatformPicker<Role>(
                  value: shareRole,
                  onSelectedItemChanged: (newValue) {
                    HapticFeedback.lightImpact();
                    try {
                      setState(() => shareRole = newValue ?? Role.editor);
                    } catch (e) {
                      setState(() => shareRole = Role.values[newValue]);
                    }
                  },
                  items: Role.values
                      .map(
                        (e) => PlatformText(
                          e.name(),
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                      )
                      .toList(),
                  arr: Role.values,
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  child: PlatformButton(
                    child: PlatformText('Share'),
                    color: Colors.green,
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      if (widget.event.shared) {
                        if (widget.emailController.text.trim().isNotEmpty) {
                          await dataModel.shareEvent(
                            event: widget.event,
                            email: widget.emailController.text.trim(),
                            role: shareRole,
                          );
                        }
                      }
                      Navigator.pop(context);
                    },
                  ),
                ),
                Expanded(
                  child: Permissions(
                    users: widget.event.users,
                    ref: widget.event.getRef()?.child('Permissions'),
                  ),
                ),
              ],
            ),
          );
        },
      );
  void _onPressed() async {
    _emailContact = await FlutterContactPicker.pickEmailContact();
    widget.emailController.text = _emailContact?.email?.email ?? '';
  }
}
