import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PercentIncrease extends StatelessWidget {
  const PercentIncrease({
    Key? key,
    required this.percentIncrease,
  }) : super(key: key);
  final double percentIncrease;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (percentIncrease > 0)
            Icon(Icons.arrow_upward, color: CupertinoColors.systemGreen),
          if (percentIncrease < 0)
            Icon(Icons.arrow_downward, color: CupertinoColors.systemRed),
          Text(percentIncrease.abs().toStringAsFixed(2) + " %",
              style: const TextStyle(fontSize: 14.0)),
        ],
      );
}
