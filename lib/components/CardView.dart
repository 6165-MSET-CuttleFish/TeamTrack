// Expanding widget that contains a card.
import 'package:teamtrack/components/Collapsible.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teamtrack/models/GameModel.dart';

class CardView extends StatefulWidget {
  CardView({
    Key? key,
    required this.child,
    required this.collapsed,
    this.isActive = true,
    required this.hero,
    required this.tag,
  }) : super(key: key);
  final Widget child;
  final Widget hero;
  final Widget collapsed;
  final bool isActive;
  final String tag;
  @override
  State<StatefulWidget> createState() => _CardView();
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
            // setState(
            //   () => _genBool = !_genBool,
            // );
            Navigator.of(context).push(
              platformPageRoute(
                builder: (context) => Scaffold(
                  body: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 200,
                        stretch: true,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          expandedTitleScale: 1.0,
                          background: Hero(
                            tag: widget.tag,
                            child: widget.hero,
                          ),
                          title: Text(widget.tag),
                        ),
                      ),
                      SliverFillRemaining(
                        child: widget.collapsed,
                      ),
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
                  style: Theme.of(context).textTheme.bodyText1,
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
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.all(
              Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: 2,
                blurRadius: 2, // changes position of shadow
              ),
            ],
          ),
          child: Column(
            children: [
              AnimatedContainer(
                curve: Curves.fastLinearToSlowEaseIn,
                duration: Duration(milliseconds: 800),
                width: getWidth(),
                height: getHeight(),
                child: widget.child,
              ),
              // Collapsible(
              //   isCollapsed: _genBool,
              //   child: Column(
              //     children: [
              //       Padding(
              //         padding: EdgeInsets.only(bottom: 50),
              //       ),
              //       widget.collapsed
              //     ],
              //   ),
              // )
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
