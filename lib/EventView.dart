import 'dart:io';

import 'package:TeamTrack/TeamView.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:TeamTrack/MatchView.dart';
import 'package:tuple/tuple.dart';
import 'backend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:TeamTrack/PlatformGraphics.dart';

class EventView extends StatefulWidget {
  EventView({Key key, this.event}) : super(key: key);
  Event event;
  @override
  _EventView createState() => _EventView(event: event);
}
class _EventView extends State<EventView> {
  List<Widget> materialTabs(){
    return <Widget>[
      ListView(
        children: event.teams.map((e) => ListTile(
          title: Text(e.name),
          leading: Text(e.number, style: Theme.of(context).textTheme.caption),
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => TeamView(team: e)));
          },
        )).toList(),
      ),
      ListView(
        children: event.matches.map((e) => ListTile(
          leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(e.red.item1.name + ' & ' + e.red.item2.name),
                Text('VS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),),
                Text(e.blue.item1.name + ' & ' + e.blue.item2.name)
              ]
          ),
          trailing: Text(e.score()),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MatchView(match: e)));
          },
        )).toList(),
      )
    ];
  }
  List<Widget> cupertinoTabs() {
   return <Widget>[
    CupertinoPageScaffold(
      child: SafeArea(
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text('Teams'),
                previousPageTitle: 'Events',
                trailing: CupertinoButton(
                child: Text('Add'),
                onPressed: () {
                  setState(() {
                    event.teams.add(Team('7390', 'Jellyfish'));
                  });
                },
                ),
              ),
              SliverList(
              delegate: SliverChildListDelegate(
                event.teams.map((e) => ListTile(
                  title: Text(e.name),
                  leading: Text(e.number, style: Theme.of(context).textTheme.caption),
                  onTap: () {
                    Navigator.push(context, CupertinoPageRoute(builder: (context) => TeamView(team: e)));
                  },
                )).toList()
              ),
              ),
            ],
          )
        )
      )
    ),
     CupertinoPageScaffold(
         child: SafeArea(
             child: Scaffold(
                 body: CustomScrollView(
                   slivers: [
                     CupertinoSliverNavigationBar(
                       largeTitle: Text('Matches'),
                       previousPageTitle: 'Events',
                       trailing: CupertinoButton(
                         child: Text('Add'),
                         onPressed: () {
                           setState(() {
                             event.matches.add(Match.defaultMatch(EventType.local));
                           });
                         },
                       ),
                       leading: CupertinoButton(
                         child: Text('Events'),
                         onPressed: () {
                           Navigator.pop(context);
                         },
                       ),
                     ),
                     SliverList(
                       delegate: SliverChildListDelegate(
                           event.matches.map((e) => ListTile(
                             leading: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(e.red.item1.name + ' & ' + e.red.item2.name),
                                  Text('VS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),),
                                  Text(e.blue.item1.name + ' & ' + e.blue.item2.name)
                                ]
                             ),
                             trailing: Text(e.score()),
                             onTap: () {
                               Navigator.push(context, CupertinoPageRoute(builder: (context) => MatchView(match: e)));
                             },
                           )).toList()
                       ),
                     ),
                   ],
                 )
             )
         )
     ),
    ];
  }

  int _x = 0;
  Event event;

  _EventView({this.event});

  @override
  Widget build(BuildContext context) {
    if(Platform.isAndroid) {
      return Scaffold(
          appBar: AppBar(
            title: _x == 0 ? Text('Teams') : Text('Matches'),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _x,
            onTap: (int index) {
              setState(() {
                _x = index;
              });
            },
            items: [BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Teams',
            ), BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports_rounded),
              label: 'Matches',
            )
            ],
          ),
          body: materialTabs()[_x],
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: (){
            setState(() {
              if(_x == 0){
                event.teams.add(Team('7390', 'Jellyfish'));
              } else {
                event.matches.add(Match.defaultMatch(EventType.local));
              }
            });
          },
        ),
        );
    }
    else{
      return CupertinoTabScaffold(
        tabBuilder: (BuildContext context, int index){
          return CupertinoTabView(
            builder: (BuildContext context) {
              return CupertinoPageScaffold(child: cupertinoTabs()[_x]);
            },
          );
        },
        tabBar: CupertinoTabBar(
          currentIndex: _x,
          items: [BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Teams',
          ), BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports_rounded),
            label: 'Matches',
          )
          ],
          onTap: (int x){ _x = x; },
        ),
      );
    }
  }

}