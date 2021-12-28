import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';

class PercentChange extends StatelessWidget {
  const PercentChange(
    this.percentIncrease, {
    Key? key,
    this.label,
  }) : super(key: key);
  final double percentIncrease;
  final String? label;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (percentIncrease > 0)
                Icon(Icons.arrow_upward, color: CupertinoColors.systemGreen),
              if (percentIncrease < 0)
                Icon(Icons.arrow_downward, color: CupertinoColors.systemRed),
              PlatformText("${percentIncrease.abs().toInt()}%",
                  style: const TextStyle(fontSize: 14.0)),
            ],
          ),
          if (label != null)
            PlatformText(
              label!,
              style: Theme.of(context).textTheme.caption,
            ),
        ],
      );
}
