import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Displays the [percentIncrease] with a widget
class PercentChange extends StatelessWidget {
  const PercentChange(
    this.percentIncrease, {
    super.key,
    this.label,
    this.lessIsBetter = false,
  });
  final double percentIncrease;
  final String? label;
  final bool lessIsBetter;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (percentIncrease > 0)
                Icon(Icons.arrow_upward,
                    color: lessIsBetter
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGreen),
              if (percentIncrease < 0)
                Icon(Icons.arrow_downward,
                    color: lessIsBetter
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemRed),
              Text("${percentIncrease.abs().toInt()}%",
                  style: const TextStyle(fontSize: 14.0)),
            ],
          ),
          if (label != null)
            Text(
              label!,
              style: Theme.of(context).textTheme.caption,
            ),
        ],
      );
}
