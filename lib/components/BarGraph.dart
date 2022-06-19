// Class for the BarGraph component which can represent singular proportions
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';

class BarGraph extends StatelessWidget {
  BarGraph({
    Key? key,
    this.max = 2,
    this.val = 9,
    this.inverted = false,
    this.height = 120,
    this.width = 30,
    this.title = 'Default',
    this.units = '', // units of measurement
    this.percentage = 0,
    this.vertical = true, // vertical or horizontal bar
    this.compressed = false,
    this.showPercentage = true,
  }) : super(key: key) {
    percentage = (inverted
            ? (val != 0 ? (max / val).clamp(0, 1) : 1) * 100.0
            : (max != 0 ? (val / max).clamp(0, 1) : 0) * 100.0)
        .toInt();
    if (!vertical) {
      double temp = width;
      width = height;
      height = temp;
    }
  }
  final bool compressed;
  final bool showPercentage;
  final String title;
  double max;
  double width;
  double val;
  final bool inverted;
  double height;
  final String units;
  final bool vertical;
  int percentage;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compressed)
            Container(
              width: 74,
              child: Center(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.caption,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ),
          if (!compressed)
            Padding(
              padding: EdgeInsets.all(2),
            ),
          Stack(
            alignment: vertical
                ? AlignmentDirectional.bottomStart
                : AlignmentDirectional.centerStart,
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
                curve: NewPlatform.isWeb ? Curves.easeInOut : Curves.bounceOut,
                duration: Duration(milliseconds: 600),
                width: vertical
                    ? width
                    : (inverted
                        ? (val != 0 ? (max / val).clamp(0, 1) : 1) * width
                        : (max != 0 ? (val / max).clamp(0, 1) : 0) * width),
                height: vertical
                    ? (inverted
                        ? (val != 0 ? (max / val).clamp(0, 1) : 1) * height
                        : (max != 0 ? (val / max).clamp(0, 1) : 0) * height)
                    : height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  color: _colorSelect(val, max),
                ),
                child: showPercentage
                    ? Center(
                        child: Text(
                          percentage != 0 ? percentage.toString() + '%' : '',
                          style: GoogleFonts.gugi(
                            textStyle: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
          if (!compressed)
            Padding(
              padding: EdgeInsets.all(2),
            ),
          if (!compressed)
            Text(val.toInt().toString() + units,
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
