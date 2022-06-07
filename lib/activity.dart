import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_material_pickers/flutter_material_pickers.dart';
import 'package:editable/editable.dart';
import 'package:emojis/emoji.dart';
import 'package:charcode/charcode.dart';
import 'dataModel.dart';
import 'locale/language.dart';

String netPhoto = 'https://wallpaper.dog/large/5514437.jpg';
Widget activityList() {
  Timestamp deadline = Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
  return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('GolferActivities').orderBy('teeOff').snapshots(), //.where(FieldPath.documentId, whereIn: myActivities)
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            } else {
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                if ((doc.data()! as Map)["teeOff"] == null) {
                  return LinearProgressIndicator();
                } else if ((doc.data()! as Map)["teeOff"].compareTo(deadline) < 0) {
                  //delete the activity
                  FirebaseFirestore.instance.collection('GolferActivities').doc(doc.id).delete();
                  return const SizedBox.shrink();
                } else {
                  return Card(
                    child: ListTile(
                      title: (doc.data()! as Map)['course'],
                      subtitle: Text(Language.of(context).teeOff + ((doc.data()! as Map)['teeOff']).toDate().toString().substring(0, 16) + '\n' + 
                                    Language.of(context).max + (doc.data()! as Map)['max'].toString() + '\t' + 
                                    Language.of(context).now + ((doc.data()! as Map)['golfers'] as List).length.toString() + "\t" + 
                                    Language.of(context).fee + (doc.data()! as Map)['fee'].toString()),
                      leading: Image.network(coursePhoto),
                      trailing: const Icon(Icons.keyboard_arrow_right),
                      onTap: () async {                          
                          Navigator.push(context, ShowActivityPage(doc, golferID, await golferName((doc.data()! as Map)['uid'] as int)!, golferID == (doc.data()! as Map)['uid'] as int))
                          .then((value) async {
                            var glist = doc.get('golfers');
                            if (value == -1) {
                              myActivities.remove(doc.id);
                              storeMyActivities();
                              glist.removeWhere((item) => item['uid'] == golferID);
                              var subGroups = doc.get('subgroups');
                              for (int i = 0; i < subGroups.length; i++) {
                                for (int j = 0; j < (subGroups[i] as Map).length; j++) {
                                  if ((subGroups[i] as Map)[j.toString()] == golferID) {
                                    for (; j<(subGroups[i] as Map).length - 1; j++)
                                      (subGroups[i] as Map)[j.toString()] = (subGroups[i] as Map)[(j+1).toString()];
                                    (subGroups[i] as Map).remove(j.toString());
                                  }                                   
                                }
                              }
                              FirebaseFirestore.instance.collection('GolferActivities').doc(doc.id).update({
                                'golfers': glist,
                                'subgroups': subGroups
                              });
                            } else if (value == 1) {
                              glist.add({
                                'uid': golferID,
                                'name': userName + ((userSex == gender.Female) ? Language.of(context).femaleNote : ''),
                                'scores': []
                              });
                              FirebaseFirestore.instance.collection('GolferActivities').doc(doc.id).update({
                                'golfers': glist
                              });                                
                            } 
                          });
                      }
                    )
                  );
                }
              }).toList());
            }
          }
        );
}

Widget myActivityBody() {
  Timestamp deadline = Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
  var allActivities = [];
  return myActivities.isEmpty ? ListView()
      : StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('GolferActivities').orderBy('teeOff').snapshots(), //.where(FieldPath.documentId, whereIn: myActivities)
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            } else {
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                if ((doc.data()! as Map)["teeOff"] == null) {
                  return LinearProgressIndicator();
                } else if (myActivities.indexOf(doc.id) < 0) {
                  return SizedBox.shrink();
                } else if ((doc.data()! as Map)["teeOff"].compareTo(deadline) < 0) {
                  //delete the activity
                  FirebaseFirestore.instance.collection('GolferActivities').doc(doc.id).delete();
                  myActivities.remove(doc.id);
                  storeMyActivities();
                  return SizedBox.shrink();
                } else {
                  allActivities.add(doc.id);
                  return Card(
                      child: ListTile(
                          title: (doc.data()! as Map)['course'],
                          subtitle: Text(Language.of(context).teeOff + ((doc.data()! as Map)['teeOff']).toDate().toString().substring(0, 16) + '\n' + 
                                        Language.of(context).max + (doc.data()! as Map)['max'].toString() + '\t' + 
                                        Language.of(context).now + ((doc.data()! as Map)['golfers'] as List).length.toString() + "\t" + 
                                        Language.of(context).fee + (doc.data()! as Map)['fee'].toString()),
                          leading: Image.network(coursePhoto),
                          trailing: Icon(Icons.keyboard_arrow_right),
                          onTap: () async {                          
                            Navigator.push(context, ShowActivityPage(doc, golferID, await golferName((doc.data()! as Map)['uid'] as int)!, (doc.data()! as Map)['uid'] as int == golferID)).then((value) async {
                              var glist = doc.get('golfers');
                              if (value == -1) {
                                myActivities.remove(doc.id);
                                storeMyActivities();
                                glist.removeWhere((item) => item['uid'] == golferID);
                                var subGroups = doc.get('subgroups');
                                for (int i = 0; i < subGroups.length; i++) {
                                  for (int j = 0; j < (subGroups[i] as Map).length; j++) {
                                    if ((subGroups[i] as Map)[j.toString()] == golferID) {
                                      for (; j<(subGroups[i] as Map).length - 1; j++)
                                        (subGroups[i] as Map)[j.toString()] = (subGroups[i] as Map)[(j+1).toString()];
                                      (subGroups[i] as Map).remove(j.toString());
                                    }                                   
                                  }
                                }
                                FirebaseFirestore.instance.collection('GolferActivities').doc(doc.id).update({
                                  'golfers': glist,
                                  'subgroups': subGroups
                                });
                                print(myActivities);
                              } else if (value == 1) {
                                glist.add({
                                  'uid': golferID,
                                  'name': userName + ((userSex == gender.Female) ? Language.of(context).femaleNote : ''),
                                  'scores': []
                                });
                                myActivities.add(doc.id);
                                storeMyActivities();
                                FirebaseFirestore.instance.collection('GolferActivities').doc(doc.id).update({
                                  'golfers': glist
                                });                                
                              } else if (myActivities.length != allActivities.length) {
                                  myActivities = allActivities;
                                  storeMyActivities();
                              }
                            });
                          }));
                }
              }).toList());
            }
          }
        );
}

void doAddActivity(BuildContext context) {
  Navigator.push(context, NewActivityPage(golferID));
}

class ShowActivityPage extends MaterialPageRoute<int> {
  ShowActivityPage(var activity, int uId, String title, bool editable)
      : super(builder: (BuildContext context) {
          bool alreadyIn = false, scoreReady = false, scoreDone = false, isBackup = false;
          String uName = '';
          int uIdx = 0;
          var rows = [];

          List buildRows() {
            var oneRow = {};
            int idx = 0;

            for (var e in activity.data()!['golfers']) {
              if (idx % 4 == 0) {
                oneRow = Map();
                if (idx >= (activity.data()!['max'] as int))
                  oneRow['row'] = Language.of(context).waiting;
                else
                  oneRow['row'] = (idx >> 2) + 1;
                oneRow['c1'] = e['name'];
                oneRow['c2'] = '';
                oneRow['c3'] = '';
                oneRow['c4'] = '';
              } else if (idx % 4 == 1)
                oneRow['c2'] = e['name'];
              else if (idx % 4 == 2)
                oneRow['c3'] = e['name'];
              else if (idx % 4 == 3) {
                oneRow['c4'] = e['name'];
                rows.add(oneRow);
              }
              idx++;
              if (idx == (activity.data()!['max'] as int)) {
                if (idx % 4 != 0)
                  rows.add(oneRow);
                while (idx % 4 != 0) idx++;
              }
            }
            if ((idx % 4) != 0)
              rows.add(oneRow);
            else if (idx == 0) {
              oneRow['row'] = '1';
              oneRow['c1'] = oneRow['c2'] = oneRow['c3'] = oneRow['c4'] = '';
              rows.add(oneRow);
            }
            return rows;
          }

          List buildScoreRows() {
            var scoreRows = [];
            int idx = 1;    
            for (var e in activity.data()!['golfers']) {
              if ((e['scores'] as List).length > 0) {
                int eg = 0, bd =0, par = 0, bg = 0, db = 0;
                List pars = e['pars'] as List;              
                List scores = e['scores'] as List;
                for (var ii=0; ii < pars.length; ii++) {
                  if (scores[ii] == pars[ii]) par++;
                  else if (scores[ii] == pars[ii] + 1) bg++;
                  else if (scores[ii] == pars[ii] + 2) db++;
                  else if (scores[ii] == pars[ii] - 1) bd++;
                  else if (scores[ii] == pars[ii] - 2) eg++;
                }
                String net = e['net'].toString();
                scoreRows.add({
                  'rank': idx,
                  'total': e['total'],
                  'name': e['name'],
                  'net': net.substring(0, min(net.length, 5)),
                  'EG' : eg,
                  'BD' : bd,
                  'PAR' : par,
                  'BG' : bg,
                  'DB' : db
                });
                idx++;
              }
            }
            scoreRows.sort((a, b) => a['total'] - b['total']);
            for (idx = 0; idx < scoreRows.length; idx++)
              scoreRows[idx]['rank'] = idx + 1;
            return scoreRows;
          }

          bool teeOffPass = activity.data()!['teeOff'].compareTo(Timestamp.now()) < 0;
          Map course = {};
          void updateScore() {
            FirebaseFirestore.instance.collection('GolferActivities').doc(activity.id).get().then((value) {
              var glist = value.get('golfers');
              glist[uIdx]['pars'] = myScores[0]['pars'];
              glist[uIdx]['scores'] = myScores[0]['scores'];
              glist[uIdx]['total'] = myScores[0]['total'];
              glist[uIdx]['net'] = myScores[0]['total'] - userHandicap;
              FirebaseFirestore.instance.collection('GolferActivities').doc(activity.id).update({
                'golfers': glist
              }).whenComplete(() => Navigator.of(context).pop(0));
            });           
          }

          // prepare parameters
          int eidx = 0;
          for (var e in activity.data()!['golfers']) {
            if (e['uid'] as int == uId) {
              uIdx = eidx;
              alreadyIn = true;
              isBackup = eidx >= (activity.data()!['max'] as int);
              uName = e['name'];
              if (myActivities.indexOf(activity.id) < 0) {
                myActivities.add(activity.id);
                storeMyActivities();
              }
            }
            if ((e['scores'] as List).length > 0) {
              scoreReady = true;
              if (e['uid'] as int == uId) 
                scoreDone = true;              
            }
            eidx++;
          }

          return Scaffold(
              appBar: AppBar(title: Text(title), elevation: 1.0),
              body: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                return Container(
                  decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(netPhoto), fit: BoxFit.cover)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                  const SizedBox(height: 10.0),
                  Text(Language.of(context).teeOff + activity.data()!['teeOff'].toDate().toString().substring(0, 16) + '\t' + Language.of(context).fee + activity.data()!['fee'].toString(), style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 10.0),
                  Text(activity.data()!['course'] + "\t" + Language.of(context).max + activity.data()!['max'].toString(), style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 10.0),
                  Visibility(
                    visible: !scoreReady,
                    child: Flexible(
                      child: Editable(
                      borderColor: Colors.black,
                      tdStyle: TextStyle(fontSize: 14),
                      trHeight: 16,
                      tdAlignment: TextAlign.center,
                      thAlignment: TextAlign.center,
                      columnRatio: 0.2,
                      columns: [
                        {"title": Language.of(context).tableGroup, 'index': 1, 'key': 'row', 'editable': false, 'widthFactor': 0.15},
                        {"title": "A", 'index': 2, 'key': 'c1', 'editable': false},
                        {"title": "B", 'index': 3, 'key': 'c2', 'editable': false},
                        {"title": "C", 'index': 4, 'key': 'c3', 'editable': false},
                        {"title": "D", 'index': 5, 'key': 'c4', 'editable': false}
                      ],
                      rows: buildRows(),
                    ))
                  ),
                  Text(Language.of(context).actRemarks + activity.data()!['remarks']),
                  const SizedBox(height: 4.0),
                  Visibility(
                    visible: ((activity.data()!['golfers'] as List).length > 4) && alreadyIn && !isBackup && !scoreReady,
                    child: ElevatedButton(
                      child: Text(Language.of(context).subGroup),
                      onPressed: () {
                        Navigator.push(context, SubGroupPage(activity, uId)).then((value) {
                          if (value ?? false) Navigator.of(context).pop(0);
                        });
                      }
                    )
                  ),
                  const SizedBox(height: 4.0),
                  Visibility(
                    visible: scoreReady,
                    child : Flexible(
                      child: Editable(
                      borderColor: Colors.black,
                      tdStyle: TextStyle(fontSize: 14),
                      trHeight: 16,
                      tdAlignment: TextAlign.center,
                      thAlignment: TextAlign.center,
                      columnRatio: 0.1,
                      columns: [
                        {'title': Language.of(context).rank, 'index': 1, 'key': 'rank', 'editable': false},
                        {'title': Language.of(context).total, 'index': 2, 'key': 'total', 'editable': false, 'widthFactor': 0.13},
                        {'title': Language.of(context).name, 'index': 3, 'key': 'name', 'editable': false, 'widthFactor': 0.2},
                        {'title': Language.of(context).net, 'index': 4, 'key': 'net', 'editable': false, 'widthFactor': 0.15},
                        {'title': '${Emoji.byName('dove')!.char}', 'index': 5, 'key': 'BD', 'editable': false},
                        {'title': '${Emoji.byName('person golfing')!.char}', 'index': 6, 'key': 'PAR', 'editable': false},
                        {'title': '${Emoji.byName('index pointing up')!.char}', 'index': 7, 'key': 'BG', 'editable': false},
                        {'title': '${Emoji.byName('victory hand')!.char}', 'index': 8, 'key': 'DB', 'editable': false},
                        {'title': '${Emoji.byName('eagle')!.char}', 'index': 9, 'key': 'EG', 'editable': false},      
                      ],
                      rows: buildScoreRows(),
                    ))
                  ),
                  Visibility(
                    visible: teeOffPass && alreadyIn && !isBackup && !scoreDone,
                    child : ElevatedButton(
                      child: Text(Language.of(context).enterScore),
                      onPressed: () {
                      }
                    )
                  ),
                  Visibility(
                    visible: !teeOffPass && alreadyIn,
                    child: ElevatedButton(
                      child: Text(Language.of(context).cancel),
                      onPressed: () => Navigator.of(context).pop(-1)
                    )
                  ),
                  Visibility(
                    visible: !teeOffPass && !alreadyIn,
                    child: ElevatedButton(
                      child: Text(Language.of(context).apply),
                      onPressed: () => Navigator.of(context).pop(1)
                    )
                  ),
                  const SizedBox(height: 4.0)
                ]));
              }),
              floatingActionButton: Visibility(
                  visible: editable,
                  child: FloatingActionButton(
                      onPressed: () {
                        // modify activity info
                        Navigator.push(context, _EditActivityPage(activity, course['name'])).then((value) {
                          if (value ?? false) Navigator.of(context).pop(0);
                        });
                      },
                      child: const Icon(Icons.edit),
                  )
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.endTop);
        });
}

class NewActivityPage extends MaterialPageRoute<bool> {
  NewActivityPage(int uid)
      : super(builder: (BuildContext context) {
          String _courseName = '', _remarks = '';
          var _selectedCourse;
          DateTime _selectedDate = DateTime.now();
          bool _includeMe = true;
          int _fee = 2500, _max = 4;
          var activity = FirebaseFirestore.instance.collection('GolferActivities');

          return Scaffold(
              appBar: AppBar(title: Text(Language.of(context).createNewActivity), elevation: 1.0),
              body: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                return Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 12.0),
                  Flexible(child: 
                    TextFormField(
                      initialValue: _courseName,
//                      key: Key(_courseName),
                      showCursor: true,
                      onChanged: (String value) => setState(() => _courseName = value),
                      //keyboardType: TextInputType.name,
                      decoration: InputDecoration(labelText: Language.of(context).courseName, icon: const Icon(Icons.golf_course), border: const UnderlineInputBorder()),
                    )
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                      child: Row(children: <Widget>[
                    ElevatedButton(
                        child: Text(Language.of(context).teeOff),
                        onPressed: () {
                          showMaterialDatePicker(
                            context: context,
                            title: Language.of(context).pickDate,
                            selectedDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 180)),
                            //onChanged: (value) => setState(() => _selectedDate = value),
                          ).then((date) {
                            if (date != null) showMaterialTimePicker(
                              context: context, 
                              title: Language.of(context).pickTime, 
                              selectedTime: TimeOfDay.now()).then((time) => 
                                setState(() => _selectedDate = DateTime(date.year, date.month, date.day, time!.hour, time.minute)))
                              ;
                          });
                        }),
                    const SizedBox(width: 5),
                    Flexible(
                        child: TextFormField(
                      initialValue: _selectedDate.toString().substring(0, 16),
                      key: Key(_selectedDate.toString().substring(0, 16)),
                      showCursor: true,
                      onChanged: (String? value) => _selectedDate = DateTime.parse(value!),
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(labelText: Language.of(context).teeOffTime, border: OutlineInputBorder()),
                    )),
                    const SizedBox(width: 5)
                  ])),
                  const SizedBox(height: 12),
                  Flexible(
                      child: Row(children: <Widget>[
                    const SizedBox(width: 5),
                    Flexible(
                        child: TextFormField(
                      initialValue: _max.toString(),
                      showCursor: true,
                      onChanged: (String value) => setState(() => _max = int.parse(value)),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: Language.of(context).max, icon: Icon(Icons.group), border: OutlineInputBorder()),
                    )),
                    const SizedBox(width: 5),
                    Flexible(
                        child: TextFormField(
                      initialValue: _fee.toString(),
                      showCursor: true,
                      onChanged: (String value) => setState(() => _fee = int.parse(value)),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: Language.of(context).fee, icon: Icon(Icons.money), border: OutlineInputBorder()),
                    )),
                    const SizedBox(width: 5)
                  ])),
                  const SizedBox(height: 12.0),
                  TextFormField(
                    showCursor: true,
                    initialValue: _remarks,
                    onChanged: (String value) => setState(() => _remarks = value),
                    //keyboardType: TextInputType.name,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: Language.of(context).actRemarks, icon: Icon(Icons.edit_note), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Row(children: <Widget>[
                    const SizedBox(width: 5),
                    Checkbox(value: _includeMe, onChanged: (bool? value) => setState(() => _includeMe = value!)),
                    const SizedBox(width: 5),
                    const Text('Include myself')
                  ])),
                  const SizedBox(height: 12.0),
                  ElevatedButton(
                      child: Text(Language.of(context).create, style: TextStyle(fontSize: 24)),
                      onPressed: () async {
                        if (_courseName != '') {
                          activity.add({
                            'uid': uid,
                            'locale': theLocale,
                            "course": _courseName,
                            "teeOff": Timestamp.fromDate(_selectedDate),
                            "max": _max,
                            "fee": _fee,
                            "remarks": _remarks,
                            'subgroups': [],
                            "golfers": _includeMe ? [{"uid": uid, "name": userName, "scores": []}] : []
                          }).then((value) {
                            if (_includeMe) {
                              myActivities.add(value.id);
                              storeMyActivities();
                            }
                            Navigator.of(context).pop(true);
                          });
                        }
                      })
                ]);
              }));
        });
}

class _EditActivityPage extends MaterialPageRoute<bool> {
  _EditActivityPage(var actDoc, String _courseName)
      : super(builder: (BuildContext context) {
          String _remarks = (actDoc.data()! as Map)['remarks'];
          int _fee = (actDoc.data()! as Map)['fee'], _max = (actDoc.data()! as Map)['max'];
          DateTime _selectedDate = (actDoc.data()! as Map)['teeOff'].toDate();
          List<NameID> golfers = [];
          var _selectedGolfer;
          var blist = [];

          ((actDoc.data()! as Map)['golfers'] as List).forEach((element) {
            blist.add(element['uid']);
          });
          if (blist.length > 0)
            FirebaseFirestore.instance.collection('Golfers').where('uid', whereIn: blist).get().then((value) {
              value.docs.forEach((result) {
                var items = result.data();
                if (((actDoc.data()! as Map)['golfers'] as List).indexOf(items['uid'] as int) < 0)
                  golfers.add(NameID(items['name'] + '(' + items['phone'] + ')', items['uid'] as int));
              });
            });

          return Scaffold(
              appBar: AppBar(title: Text(Language.of(context).editActivity), elevation: 1.0),
              body: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                return Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                  const SizedBox(height: 12),
                  Text(Language.of(context).courseName + _courseName, style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 12),
                  Flexible(
                      child: Row(children: <Widget>[
                    ElevatedButton(
                        child: Text(Language.of(context).teeOff),
                        onPressed: () {
                          showMaterialDatePicker(
                            context: context,
                            title: Language.of(context).pickDate,
                            selectedDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 180)),
                            //onChanged: (value) => setState(() => _selectedDate = value),
                          ).then((date) {
                            if (date != null) showMaterialTimePicker(
                              context: context, 
                              title: Language.of(context).pickTime, 
                              selectedTime: TimeOfDay.now()).then((time) => 
                                setState(() => _selectedDate = DateTime(date.year, date.month, date.day, time!.hour, time.minute))
                              );
                          });
                        }),
                    const SizedBox(width: 5),
                    Flexible(
                        child: TextFormField(
                      initialValue: _selectedDate.toString().substring(0, 16),
                      key: Key(_selectedDate.toString().substring(0, 16)),
                      showCursor: true,
                      onChanged: (String? value) => _selectedDate = DateTime.parse(value!),
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(labelText: Language.of(context).teeOffTime, border: OutlineInputBorder()),
                    )),
                    const SizedBox(width: 5)
                  ])),
                  const SizedBox(height: 12),
                  Flexible(
                      child: Row(children: <Widget>[
                    const SizedBox(width: 5),
                    Flexible(
                        child: TextFormField(
                      initialValue: _max.toString(),
                      showCursor: true,
                      onChanged: (String value) => _max = int.parse(value),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: Language.of(context).max, icon: Icon(Icons.group), border: OutlineInputBorder()),
                    )),
                    const SizedBox(width: 5),
                    Flexible(
                        child: TextFormField(
                      initialValue: _fee.toString(),
                      showCursor: true,
                      onChanged: (String value) => _fee = int.parse(value),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: Language.of(context).fee, icon: Icon(Icons.money), border: OutlineInputBorder()),
                    )),
                    const SizedBox(width: 5)
                  ])),
                  const SizedBox(height: 12),
                  TextFormField(
                    showCursor: true,
                    initialValue: _remarks,
                    onChanged: (String value) => _remarks = value,
                    //keyboardType: TextInputType.name,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: Language.of(context).actRemarks, icon: Icon(Icons.edit_note), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                    ElevatedButton(
                      child: Text(Language.of(context).modify, style: TextStyle(fontSize: 18)),
                      onPressed: () async {
                        FirebaseFirestore.instance.collection('GolferActivities').doc(actDoc.id).update({
                          "teeOff": Timestamp.fromDate(_selectedDate),
                          "max": _max,
                          "fee": _fee,
                          "remarks": _remarks,
                        }).then((value) {
                          Navigator.of(context).pop(true);
                        });
                      }
                    ),
                    Visibility(
                      visible: blist.length > 0,
                      child: ElevatedButton(
                        child: Text(Language.of(context).kickMember, style: TextStyle(fontSize: 18)),
                        onPressed: () {
                          showMaterialScrollPicker<NameID>(
                            context: context,
                            title: Language.of(context).selectKickMember,
                            items: golfers,
                            showDivider: false,
                            selectedItem: golfers[0],
                            onChanged: (value) => setState(() => _selectedGolfer = value),
                          ).then((value) {
                            if (_selectedGolfer != null) 
                              removeGolferActivity(actDoc, _selectedGolfer.toID());
                            Navigator.of(context).pop(true);
                          });
                        }
                      )
                    )
                  ])
                ]);
              }));
        });
}

class SubGroupPage extends MaterialPageRoute<bool> {
  SubGroupPage(var activity, int uId)
      : super(builder: (BuildContext context) {
          var subGroups = activity.data()!['subgroups'] as List;
          int max = (activity.data()!['max'] + 3) >> 2;
          List<List<int>> subIntGroups = [];

          void storeAndLeave() {
            var newGroups = [];
            for (int i = 0; i < subIntGroups.length; i++) {
              Map subMap = Map();
              for (int j = 0; j < subIntGroups[i].length; j++) 
                subMap[j.toString()] = subIntGroups[i][j];
              newGroups.add(subMap);
            }
            subGroups = newGroups;
            FirebaseFirestore.instance.collection('GolferActivities').doc(activity.id).update({
              'subgroups': newGroups
            }).whenComplete(() => Navigator.of(context).pop(true));
          }

          int alreadyIn = -1;
          for (int i = 0; i < subGroups.length; i++) {
            subIntGroups.add([]);
            for (int j = 0; j < (subGroups[i] as Map).length; j++) {
              subIntGroups[i].add((subGroups[i] as Map)[j.toString()]);
              if (subIntGroups[i][j] == uId) alreadyIn = i;
            }
          }
          if (subIntGroups.length == 0 || ( subIntGroups[subIntGroups.length - 1].length > 0 && 
              subIntGroups.length < max && alreadyIn < 0))
              subIntGroups.add([]);

          return Scaffold(
              appBar: AppBar(title: Text(Language.of(context).subGroup), elevation: 1.0),
              body: ListView.builder(
                  itemCount: subIntGroups.length,
                  padding: const EdgeInsets.all(10.0),
                  itemBuilder: (BuildContext context, int i) {
                    bool isfull = subIntGroups[i].length == 4;
                    return ListTile(
                      leading: CircleAvatar(
                          child: Text(String.fromCharCodes([$A + i]))),
                      title: subIntGroups[i].length == 0
                          ? Text(Language.of(context).name)
                          : FutureBuilder(
                              future: golferNames(subIntGroups[i]),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData)
                                  return const LinearProgressIndicator();
                                else
                                  return Text(snapshot.data!.toString(), style: TextStyle(fontWeight: FontWeight.bold));
                              }),
                      trailing: (alreadyIn == i) ? Icon(Icons.person_remove_rounded, color: Colors.red,)
                              : (!isfull && alreadyIn < 0) ? Icon(Icons.add_box_outlined, color: Colors.blue,)
                              : Icon(Icons.stop, color: Colors.grey),
                      onTap: () {
                        if (alreadyIn == i) {
                          subIntGroups[i].remove(uId);
                          if (subIntGroups[i].length == 0) subIntGroups.removeAt(i);
                          storeAndLeave();
                        } else if (!isfull && alreadyIn < 0) {
                          subIntGroups[i].add(uId);
                          storeAndLeave();
                        }
                      },
                    );
                  }));
        });
}
