import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/util/Permissions.dart';
import 'package:provider/provider.dart';

class EventShare extends StatefulWidget {
  const EventShare({
    super.key,
    required this.event,
  });
  final Event event;
  @override
  State<EventShare> createState() => _EventShareState();
}

Role shareRole = Role.editor;

class _EventShareState extends State<EventShare> {
  EmailContact? _emailContact;
  final emailController = TextEditingController();
  @override
  Widget build(BuildContext context) => StreamBuilder<DatabaseEvent>(
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
          final currentUser = TeamTrackUser.fromUser(context.read<User?>());
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.event.role == Role.admin ? 'Share Event' : 'Permissions',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            body: Column(
              children: [
                if (widget.event.role == Role.admin)
                  Row(
                    children: [
                      IconButton(
                        onPressed: _onPressed,
                        tooltip: 'Select Contact',
                        icon: Icon(Icons.contacts),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Expanded(
                        child: PlatformTextField(
                          textInputAction: TextInputAction.done,
                          placeholder: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          controller: emailController,
                          autoCorrect: false,
                        ),
                      ),
                    ],
                  ),
                if (widget.event.role == Role.admin)
                  DropdownButton<Role>(
                    value: shareRole,
                    onChanged: (newValue) {
                      HapticFeedback.lightImpact();
                      setState(() => shareRole = newValue ?? Role.editor);
                    },
                    items: Role.values
                        .map(
                          (e) => DropdownMenuItem<Role>(
                            child: Text(e.name()),
                            value: e,
                          ),
                        )
                        .toList(),
                  ),
                if (widget.event.role == Role.admin)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: PlatformButton(
                        child: Text('Share'),
                        color: Colors.green,
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          if (widget.event.shared) {
                            if (emailController.text.trim().isNotEmpty) {
                              showPlatformDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (_) => PlatformAlert(
                                  content: Center(
                                    child: PlatformProgressIndicator(),
                                  ),
                                ),
                              );
                              await widget.event.shareEvent(
                                email: emailController.text.trim(),
                                role: shareRole,
                              );
                              emailController.clear();
                            }
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ),
                Expanded(
                  child: Permissions(
                    event: widget.event,
                    users: widget.event.users,
                    currentUser: currentUser,
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
    emailController.text = _emailContact?.email?.email ?? '';
  }
}
