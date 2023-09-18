// Class for the BarGraph component which can represent singular proportions
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';

/// Used to show proportion of [val]/[max] in a color coded format
// ignore: must_be_immutable
class BarGraph extends StatelessWidget {
  BarGraph({
    super.key,
    this.max = 2,
    this.val = 9,
    this.height = 120,
    this.width = 30,
    this.title = '',
    this.fontSize = 12,
    this.units = '',
    this.percentage = 0,
    this.vertical = true, // vertical or horizontal bar
    this.compressed = false, // whether to show the text or not
    this.showPercentage = true, // whether to show the percentage or not
    this.lessIsBetter = false, // if true, lower numbers are better
    this.titleWidthConstraint,
  }) {
    percentage = ((max != 0 ? (val / max).clamp(0, 1) : 0) * 100.0).toInt();
    if (!vertical) {
      double temp = width;
      width = height;
      height = temp;
    }
  }
  final bool compressed;
  final bool showPercentage;
  final bool lessIsBetter;
  final double? titleWidthConstraint;
  final String title;
  final double fontSize;
  final double max;
  double width;
  final double val;
  double height;
  final String units; // units of [val]
  final bool vertical;
  int percentage;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compressed)
            SizedBox(
              width: titleWidthConstraint,
              child: Center(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
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
                    : (max != 0 ? (val / max).clamp(0, 1) : 0) * width,
                height: vertical
                    ? (max != 0 ? (val / max).clamp(0, 1) : 0) * height
                    : height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  color: _colorSelect(val, max),
                ),
                child: showPercentage
                    ? Center(
                        child: Text(
                          percentage != 0 ? '$percentage%' : '',
                          style: GoogleFonts.montserrat(
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
            Text(
              val.toInt().toString() + units,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      );

  Color _colorSelect(double val, double max) {
    Color color;
    if (val / max < 0.5) {
      color = lessIsBetter
          ? CupertinoColors.systemGreen
          : CupertinoColors.systemRed;
    } else if (val / max < 0.7) {
      color = CupertinoColors.systemYellow;
    } else {
      color = lessIsBetter
          ? CupertinoColors.systemRed
          : CupertinoColors.systemGreen;
    }
    return color;
  }
}

extension colorExtensions on Color {
  Color inverseColor(double opacity) {
    return Color.fromRGBO(
        255 - this.red, 255 - this.green, 255 - this.blue, opacity);
  }
}
