import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';

class PercentChange extends StatelessWidget {
  const PercentChange({
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
          PlatformText("${percentIncrease.abs().toInt()}%",
              style: const TextStyle(fontSize: 14.0)),
        ],
      );
}
