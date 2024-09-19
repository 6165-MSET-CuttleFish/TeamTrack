// Expanding widget that contains a card.
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/Extensions.dart';

class CardView extends StatefulWidget {
  CardView({
    super.key,
    required this.child,
    required this.collapsed,
    this.isActive = true,
    required this.title,
    this.type,
  });
  final Widget child;
  final String title;
  final List<Widget> collapsed;
  final bool isActive;
  final OpModeType? type;
  @override
  State<CardView> createState() => _CardView();
}

class _CardView extends State<CardView> {
  bool _genBool = true;
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          if (widget.isActive) {
            Navigator.of(context).push(
              platformPageRoute(
                builder: (context) => Scaffold(
                  body: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        title: Text(widget.title),
                        expandedHeight: 0,
                        stretch: true,
                        pinned: true,
                      ),
                      SliverList(
                          delegate: SliverChildListDelegate(widget.collapsed)),
                    ],
                  ),
                ),
              ),
            );
          } else {
            showPlatformDialog(
              context: context,
              builder: (context) => PlatformAlert(
                title: Text('Not Enough Data'),
                content: Text(
                  'Add more scores',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                actions: [
                  PlatformDialogAction(
                    isDefaultAction: true,
                    child: Text('Okay'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          }
        },
        onTapDown: (TapDownDetails details) => setState(
              () => _isPressed = true,
        ),
        onTapUp: (TapUpDetails details) => setState(
              () => _isPressed = false,
        ),
        onTapCancel: () => setState(
              () => _isPressed = false,
        ),
        child: AnimatedContainer(
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.type.getColor()
                : Theme.of(context).canvasColor,
            border: Border.all(
              color: widget.type.getColor(),
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: _isPressed ? 0 : 2,
                blurRadius: _isPressed ? 0 : 2, // changes position of shadow
              ),
            ],
          ),
          curve: Curves.fastLinearToSlowEaseIn,
          duration: Duration(milliseconds: 800),
          width: getWidth(),
          height: getHeight(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: widget.title,
                child: widget.child,
              ),
              Divider(
                thickness: 3,
              ),
              Hero(
                tag: widget.type ?? Null,
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text("tap for details",
              style:Theme.of(context).textTheme.bodySmall)
            ],
          ),
        ),
      ),
    );
  }

  double getWidth() {
    double val = !_genBool
        ? MediaQuery.of(context).size.width
        : MediaQuery.of(context).size.width - 50;
    if (_isPressed) {
      val /= 1.05;
    }
    return val;
  }

  double getHeight() {
    double val = _genBool ? 250 : 200;
    if (_isPressed && _genBool) {
      val /= 1.05;
    }
    return val;
  }
}