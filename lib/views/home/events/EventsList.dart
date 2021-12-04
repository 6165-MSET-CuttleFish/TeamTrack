import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/events/EventShare.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/views/home/events/EventView.dart';
import 'package:provider/provider.dart';
import 'package:teamtrack/functions/Extensions.dart';

class EventsList extends StatefulWidget {
  EventsList({Key? key, this.onTap}) : super(key: key);
  final void Function(Event)? onTap;
  @override
  _EventsList createState() => _EventsList();
}

class _EventsList extends State<EventsList> {
  final slider = SlidableDrawerActionPane();
  final secondaryActions = <Widget>[
    IconSlideAction(
      icon: Icons.delete,
      color: Colors.red,
    )
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          children: [
            ExpansionTile(
              leading: Icon(CupertinoIcons.person_3),
              initiallyExpanded: true,
              title: PlatformText('In-Person Events'),
              children: localEvents(),
            ),
            ExpansionTile(
              leading: Icon(CupertinoIcons.rectangle_stack_person_crop),
              initiallyExpanded: true,
              title: PlatformText('Remote Events'),
              children: remoteEvents(),
            ),
          ],
        ),
      );

  List<Widget> localEvents() => dataModel.localEvents().map(eventTile).toList();

  List<Widget> remoteEvents() =>
      dataModel.remoteEvents().map(eventTile).toList();

  Slidable eventTile(Event e) => Slidable(
        actions: [
          IconSlideAction(
            onTap: () => _onShare(e),
            icon: e.shared ? Icons.share : Icons.upload,
            color: Colors.blue,
          ),
        ],
        secondaryActions: [
          IconSlideAction(
            onTap: () {
              showPlatformDialog(
                context: context,
                builder: (BuildContext context) => PlatformAlert(
                  title: PlatformText('Delete Event'),
                  content: PlatformText('Are you sure?'),
                  actions: [
                    PlatformDialogAction(
                      isDefaultAction: true,
                      child: PlatformText('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    PlatformDialogAction(
                      isDefaultAction: false,
                      isDestructive: true,
                      child: PlatformText('Confirm'),
                      onPressed: () {
                        if (e.shared)
                          onRemove(e);
                        else
                          setState(() => dataModel.events.remove(e));
                        dataModel.saveEvents();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
            icon: Icons.delete,
            color: Colors.red,
          )
        ],
        child: ListTileTheme(
          iconColor: Theme.of(context).primaryColor,
          child: ListTile(
            trailing: Icon(
              e.shared
                  ? CupertinoIcons.cloud_fill
                  : CupertinoIcons.lock_shield_fill,
              color: Theme.of(context).colorScheme.primary,
            ),
            leading: Icon(
              e.type == EventType.remote
                  ? CupertinoIcons.rectangle_stack_person_crop_fill
                  : CupertinoIcons.person_3_fill,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlatformText(
                  e.name,
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                PlatformText(
                  e.gameName.spaceBeforeCapital(),
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
            onTap: () async {
              final map = await e.getRef()?.once();
              e.updateLocal(
                json.decode(
                  json.encode(
                    map?.value,
                  ),
                ),
                context,
              );
              if (widget.onTap != null)
                widget.onTap!(e);
              else
                Navigator.push(
                  context,
                  platformPageRoute(
                    builder: (_) => EventView(
                      event: e,
                    ),
                  ),
                );
            },
          ),
        ),
        actionPane: slider,
      );

  TextEditingController _emailController = TextEditingController();
  void _onShare(Event e) {
    if (!(context.read<User?>()?.isAnonymous ?? true)) {
      if (!e.shared) {
        showPlatformDialog(
          context: context,
          builder: (context) => PlatformAlert(
            title: PlatformText('Upload Event'),
            content: PlatformText(
              'Your event will still be private',
            ),
            actions: [
              PlatformDialogAction(
                child: PlatformText('Cancel'),
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              PlatformDialogAction(
                child: PlatformText('Upload'),
                onPressed: () async {
                  showPlatformDialog(
                    context: context,
                    builder: (_) => PlatformAlert(
                      content: Center(child: PlatformProgressIndicator()),
                      actions: [
                        PlatformDialogAction(
                          child: PlatformText('Back'),
                          isDefaultAction: true,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                  e.shared = true;
                  final json = e.toJson();
                  await firebaseDatabase
                      .reference()
                      .child("Events/${e.gameName}/${e.id}")
                      .set(json);
                  dataModel.events.remove(e);
                  setState(() => dataModel.saveEvents);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      } else {
        Navigator.of(context).push(
          platformPageRoute(
            builder: (context) => EventShare(
              emailController: _emailController,
              event: e,
            ),
          ),
        );
      }
    } else {
      showPlatformDialog(
        context: context,
        builder: (context) => PlatformAlert(
          title: PlatformText('Cannot Share Event'),
          content: PlatformText('You must be logged in to share an event.'),
          actions: [
            PlatformDialogAction(
              child: PlatformText('OK'),
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  void onRemove(Event e) async {
    final uid = context.read<User?>()?.uid;
    final map = await e.getRef()?.once();
    e.updateLocal(json.decode(json.encode(map?.value)), context);
    if (e.users
            .firstWhere((element) => element.uid == context.read<User?>()?.uid)
            .role ==
        Role.admin)
      await e.getRef()?.remove();
    else
      await firebaseDatabase
          .reference()
          .child('Events/${e.gameName}/${e.id}/Permissions/$uid')
          .remove();
    dataModel.saveEvents();
  }
}
