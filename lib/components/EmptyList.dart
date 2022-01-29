import 'package:flutter/material.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';

class EmptyList extends StatelessWidget {
  const EmptyList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
            ),
            PlatformText(
              "No Data",
              style: Theme.of(context).textTheme.bodyText2,
            )
          ],
        ),
      );
}
