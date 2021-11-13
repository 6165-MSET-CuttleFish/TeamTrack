import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/views/home/team/TeamView.dart';

class CheckList extends StatefulWidget {
  const CheckList({Key? key, required this.state}) : super(key: key);
  final TeamViewState state;
  @override
  _CheckListState createState() => _CheckListState();
}

class _CheckListState extends State<CheckList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          value: widget.state.removeOutliers,
          onChanged: (_) => setState(
            () => widget.state.setState(
              () => widget.state.removeOutliers = _ ?? false,
            ),
          ),
          checkColor: Colors.black,
          tileColor: Colors.green,
          title: PlatformText('Remove Outliers'),
          secondary: Icon(CupertinoIcons.arrow_branch),
        ),
        CheckboxListTile(
          value: widget.state.showPenalties,
          onChanged: (_) => setState(
            () => widget.state.setState(
              () => widget.state.showPenalties = _ ?? false,
            ),
          ),
          checkColor: Colors.black,
          tileColor: Colors.red,
          title: PlatformText('Count Penalties'),
          secondary: Icon(CupertinoIcons.xmark_seal_fill),
        ),
        if (widget.state.widget.event.type != EventType.remote)
          CheckboxListTile(
            value: widget.state.matchIsScore,
            onChanged: (_) => setState(
              () => widget.state.setState(
                () => widget.state.matchIsScore = _ ?? false,
              ),
            ),
            checkColor: Colors.black,
            tileColor: Colors.blue,
            title: PlatformText('Alliance Total'),
            subtitle: PlatformText('Consider alliance total as total score'),
            secondary: Icon(Icons.stacked_line_chart),
          ),
      ],
    );
  }
}
