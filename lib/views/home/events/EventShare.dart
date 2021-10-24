import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/functions/Extensions.dart';
import 'package:teamtrack/models/GameModel.dart';

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
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          items: Role.values.map((e) => Text(e.name())).toList(),
          arr: Role.values,
        ),
        PlatformTextField(
          placeholder: widget.event.shared ? 'Email' : '(Optional) Email',
          keyboardType: TextInputType.emailAddress,
          controller: widget.emailController,
          autoCorrect: false,
        ),
      ],
    );
  }
}