import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EmptyList extends StatelessWidget {
  const EmptyList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
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
}
