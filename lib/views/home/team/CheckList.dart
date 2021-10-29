import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
          title: Text('Remove Outliers'),
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
          title: Text('Count Penalties'),
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
            title: Text('Match Total'),
            subtitle: Text('Consider match total as score total'),
            secondary: Icon(CupertinoIcons.square_stack),
          ),
      ],
    );
  }
}
