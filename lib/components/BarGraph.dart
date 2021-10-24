import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BarGraph extends StatelessWidget {
  BarGraph({
    Key? key,
    this.max = 2,
    this.val = 9,
    this.inverted = false,
    this.height = 120,
    this.width = 30,
    this.title = 'Default',
    this.percentage = 0,
  }) : super(key: key) {
    percentage = (inverted
            ? (val != 0 ? (max / val).clamp(0, 1) : 1) * 100.0
            : (max != 0 ? val / max : 0) * 100.0)
        .toInt();
  }
  final String title;
  double max;
  final double width;
  double val;
  final bool inverted;
  final double height;
  int percentage;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.caption),
          Padding(
            padding: EdgeInsets.all(2),
          ),
          Stack(
            alignment: AlignmentDirectional.bottomStart,
            children: [
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  color: Theme.of(context).canvasColor.inverseColor(1),
                ),
              ),
              AnimatedContainer(
                curve: Curves.fastLinearToSlowEaseIn,
                duration: Duration(milliseconds: 600),
                width: width,
                height: inverted
                    ? (val != 0 ? (max / val).clamp(0, 1) : 1) * height
                    : (max != 0 ? (val / max).clamp(0, 1) : 0) * height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  color: _colorSelect(val, max),
                ),
                child: Center(
                  child: Text(
                    percentage != 0 ? percentage.toString() + '%' : '',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(2),
          ),
          Text(val.toInt().toString(),
              style: Theme.of(context).textTheme.caption),
        ],
      );

  Color _colorSelect(double val, double max) {
    if (!inverted) {
      if (val / max < 0.5) {
        return CupertinoColors.systemRed;
      } else if (val / max < 0.7) {
        return CupertinoColors.systemYellow;
      } else {
        return CupertinoColors.systemGreen;
      }
    } else {
      if (max / val < 0.5) {
        return CupertinoColors.systemRed;
      } else if (max / val < 0.7) {
        return CupertinoColors.systemYellow;
      } else {
        return CupertinoColors.systemGreen;
      }
    }
  }
}

extension colorExtensions on Color {
  Color inverseColor(double opacity) {
    return Color.fromRGBO(
        255 - this.red, 255 - this.green, 255 - this.blue, opacity);
  }
}
