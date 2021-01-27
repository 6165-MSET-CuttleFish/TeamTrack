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
  _EventView createState() => _EventView();
}
class _EventView extends State<EventView> {
  List<Widget> materialTabs(){
    return <Widget>[
      ListView(
        children: widget.event.teams.map((e) => ListTile(
          title: Text(e.name),
          leading: Text(e.number, style: Theme.of(context).textTheme.caption),
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => TeamView(team: e)));
          },
        )).toList(),
      ),
      ListView(
        semanticChildCount: widget.event.matches.length,
        children: widget.event.matches.map((e) => ListTile(
          leading: Column(
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
      ),
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
                    widget.event.teams.add(Team('7390', 'JCjos'));
                  });
                },
                ),
              ),
              SliverList(
              delegate: SliverChildListDelegate(
                  widget.event.teams.map((e) => ListTile(
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
                             widget.event.matches.add(Match.defaultMatch(EventType.local));
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
                           widget.event.matches.map((e) => ListTile(
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

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    if(Platform.isAndroid) {
      return Scaffold(
          appBar: AppBar(
            title: _tab == 0 ? Text('Teams') : Text('Matches'),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (int index) {
              setState(() {
                _tab = index;
              });
            },
            items: [BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person_3_fill),
              label: 'Teams',
            ), BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.sportscourt_fill),
              label: 'Matches',
            )
            ],
          ),
          body: materialTabs()[_tab],
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: (){
            if(_tab == 0){
              _teamConfig();
            } else {
              _matchConfig();
            }
          },
        ),
        );
    }
    else{
      return CupertinoTabScaffold(
        tabBuilder: (BuildContext context, int index){
          return CupertinoTabView(
            builder: (BuildContext context) {
              return CupertinoPageScaffold(child: cupertinoTabs()[_tab]);
            },
          );
        },
        tabBar: CupertinoTabBar(
          currentIndex: _tab,
          items: [BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_3_fill),
            label: 'Teams',
          ), BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.sportscourt_fill),
            label: 'Matches',
          )
          ],
          onTap: (int x){ _tab = x; },
        ),
      );
    }
  }
  void _matchConfig(){
    if(Platform.isAndroid) {
      showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) {
        return _addMatch();
      });
    } else {
      showCupertinoModalPopup(context: null, builder: (context) {
        return CupertinoPageScaffold(child: Text('Hello'));
      });
    }
  }
  String _newName;
  String _newNumber;
  void _teamConfig(){
    showDialog(
        context: context,
        builder: (BuildContext context) => PlatformAlert(
          title: Text('New Team'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlatformTextField(
                  placeholder: 'Team name',
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (String input){
                    _newName = input;
                  },
                ),
                PlatformTextField(
                  placeholder: 'Team number',
                  keyboardType: TextInputType.number,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (String input){
                    _newNumber = input;
                  },
                ),
              ],
            ),
          actions: [
            PlatformDialogAction(
              isDefaultAction: true,
              child: Text('Cancel'),
              onPressed: () {
                _newName = '';
                _newNumber = '';
                Navigator.of(context).pop();
              },
            ),
            PlatformDialogAction(
              isDefaultAction: false,
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  if(_newNumber.isNotEmpty && _newName.isNotEmpty)
                    widget.event.addTeam(Team(_newNumber, _newName));
                  _newName = '';
                  _newNumber = '';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
      )
    );
  }
  Tuple2<String, TextEditingController> _r0 = Tuple2('', TextEditingController());
  Tuple2<String, TextEditingController> _r1 = Tuple2('', TextEditingController());
  Tuple2<String, TextEditingController> _b0 = Tuple2('', TextEditingController());
  Tuple2<String, TextEditingController> _b1 = Tuple2('', TextEditingController());
  Widget _addMatch() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Match'),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: Center(
          child: Form(
            child: ListView(
              children: [
                Container(alignment: Alignment.center,color: Colors.red,child: Text('Red Alliance', style: Theme.of(context).textTheme.headline6,)),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Team number'),
                        validator: (String value) {
                          if(value.isEmpty) {
                            return 'Number is required';
                          } else {
                            return null;
                          }
                        },
                        onChanged: (String val){
                          setState(() {
                            _r0.item2.value = TextEditingValue(
                              text: widget.event.teams.firstWhere((element) => element.number == val.replaceAll(new RegExp(r' [^\w\s]+'),'').replaceAll(' ', '')).name,
                              selection: TextSelection.fromPosition(
                                TextPosition(offset: val.length),
                              ),
                            );
                            //_r0 = Tuple2(val, TextEditingController().text = widget.event.teams.firstWhere((element) => element.number == val.trim())?.name ?? _r0.item2);
                          });
                        },
                      ),
                    ),
                    Expanded(
                        child: TextFormField(
                          controller: _r0.item2,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(labelText: 'Name'),
                          validator: (String value) {
                            if(value.isEmpty) {
                              return 'Name is required';
                            } else {
                              return null;
                            }
                          },
                          onChanged: (String val){
                            setState(() {
                              _r0.item2.value = TextEditingValue(
                                text: val,
                                selection: TextSelection.fromPosition(
                                  TextPosition(offset: val.length),
                                ),
                              );
                            });
                          },
                        )
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Team number'),
                      validator: (String value) {
                        if(value.isEmpty) {
                          return 'Number is required';
                        } else {
                          return null;
                        }
                      },
                      onChanged: (String val){
                        print(widget.event.teams.firstWhere((element) => element.number == val.replaceAll(new RegExp(r' [^\w\s]+'),'').replaceAll(' ', '')).name);
                        setState(() {
                          _r1.item2.value = TextEditingValue(
                            text: widget.event.teams.firstWhere((element) => element.number == val.replaceAll(new RegExp(r' [^\w\s]+'),'').replaceAll(' ', '')).name,
                            selection: TextSelection.fromPosition(
                              TextPosition(offset: val.length),
                            ),
                          );
                        });
                      },
                    ),),
                    Expanded(
                      child: TextFormField(
                        controller: _r1.item2,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(labelText: 'Name'),
                        validator: (String value) {
                          if(value.isEmpty) {
                            return 'Name is required';
                          } else {
                            return null;
                          }
                        },
                        onChanged: (String val){
                          setState(() {
                            _r1.item2.value = TextEditingValue(
                              text: val,
                              selection: TextSelection.fromPosition(
                                TextPosition(offset: val.length),
                              ),
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Container(alignment: Alignment.center,color: Colors.blue,child: Text('Blue Alliance', style: Theme.of(context).textTheme.headline6,)),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Team number'),
                        validator: (String value) {
                          if(value.isEmpty) {
                            return 'Number is required';
                          } else {
                            return null;
                          }
                        },
                        onChanged: (String val){
                          setState(() {
                            _b0.item2.value = TextEditingValue(
                              text: widget.event.teams.firstWhere((element) => element.number == val.replaceAll(new RegExp(r' [^\w\s]+'),'').replaceAll(' ', '')).name,
                              selection: TextSelection.fromPosition(
                                TextPosition(offset: val.length),
                              ),
                            );
                          });
                        },
                      ),
                    ),
                    Expanded(
                        child: TextFormField(
                          controller: _b0.item2,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(labelText: 'Name'),
                          validator: (String value) {
                            if(value.isEmpty) {
                              return 'Name is required';
                            } else {
                              return null;
                            }
                          },
                          onChanged: (String val){
                            setState(() {
                              _b0.item2.value = TextEditingValue(
                                text: val,
                                selection: TextSelection.fromPosition(
                                  TextPosition(offset: val.length),
                                ),
                              );
                            });
                          },
                        )
                    ),

                  ],
                ),
                Row(
                  children: [
                    Expanded(child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Team number'),
                      validator: (String value) {
                        if(value.isEmpty) {
                          return 'Number is required';
                        } else {
                          return null;
                        }
                      },
                      onChanged: (String val){
                        setState(() {
                          _b1.item2.value = TextEditingValue(
                            text: widget.event.teams.firstWhere((element) => element.number == val.replaceAll(new RegExp(r' [^\w\s]+'),'').replaceAll(' ', '')).name,
                            selection: TextSelection.fromPosition(
                              TextPosition(offset: val.length),
                            ),
                          );
                        });
                      },
                    ),),
                    Expanded(
                      child: TextFormField(
                        controller: _b1.item2,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(labelText: 'Name'),
                        validator: (String value) {
                          if(value.isEmpty) {
                            return 'Name is required';
                          } else {
                            return null;
                          }
                        },
                        onChanged: (String val){
                          setState(() {
                            _b1.item2.value = TextEditingValue(
                              text: val,
                              selection: TextSelection.fromPosition(
                                TextPosition(offset: val.length),
                              ),
                            );
                          });
                        },
                      ),
                    ),

                  ],
                ),
              ]
            )
          )
        ),
      )
    );
  }
}