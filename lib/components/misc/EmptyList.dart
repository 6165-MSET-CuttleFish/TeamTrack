import 'package:flutter/material.dart';

/// Class to display an empty list
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
            Text(
              "No Data",
              style: Theme.of(context).textTheme.bodyText2,
            )
          ],
        ),
      );
}
