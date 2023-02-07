import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/models/StatConfig.dart';

class CheckList extends StatefulWidget {
  const CheckList({
    super.key,
    required this.state,
    required this.event,
    required this.statConfig,
    this.showSorting = true,
  });
  final StatConfig statConfig;
  final State state;
  final Event event;
  final bool showSorting;
  @override
  _CheckListState createState() => _CheckListState();
}

class _CheckListState extends State<CheckList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showSorting)
          CheckboxListTile(
            value: widget.statConfig.sorted,
            onChanged: (_) => setState(
              () => widget.state.setState(
                () => widget.statConfig.sorted = _ ?? false,
              ),
            ),
            checkColor: Colors.black,
            tileColor: widget.statConfig.sorted ? Colors.pink : null,
            title: Text('Sort Teams'),
            secondary: Icon(Icons.sort),
          ),
        CheckboxListTile(
          value: widget.statConfig.removeOutliers,
          onChanged: (_) => setState(
            () => widget.state.setState(
              () => widget.statConfig.removeOutliers = _ ?? false,
            ),
          ),
          checkColor: Colors.black,
          tileColor: widget.statConfig.removeOutliers ? Colors.green : null,
          title: Text('Remove Outliers'),
          secondary: Icon(CupertinoIcons.arrow_branch),
        ),
        CheckboxListTile(
          value: widget.statConfig.showPenalties,
          onChanged: (_) => setState(
            () => widget.state.setState(
              () => widget.statConfig.showPenalties = _ ?? false,
            ),
          ),
          checkColor: Colors.black,
          tileColor: widget.statConfig.showPenalties ? Colors.red : null,
          title: Text('Count Penalties'),
          secondary: Icon(CupertinoIcons.xmark_seal_fill),
        ),
        if (widget.event.type != EventType.remote)
          CheckboxListTile(
            value: widget.statConfig.allianceTotal,
            onChanged: (_) => setState(
              () => widget.state.setState(
                () => widget.statConfig.allianceTotal = _ ?? false,
              ),
            ),
            checkColor: Colors.black,
            tileColor: widget.statConfig.allianceTotal ? Colors.blue : null,
            title: Text('Alliance Total'),
            subtitle: Text('Consider alliance total as score'),
            secondary: Icon(Icons.stacked_line_chart),
          ),
      ],
    );
  }
}
