import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final toDoController = TextEditingController();
  final comentController = TextEditingController();

  List toDoList = [];

  GlobalKey<FormState> formkey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    readData().then((data) {
      setState(() {
        toDoList = json.decode(data);
      });
    });
  }

  Map<String, dynamic> lastRemoved;
  int lastRemovedPos;

  void addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = toDoController.text;
      newToDo["coment"] = "";
      newToDo["ok"] = false;
      toDoList.add(newToDo);
      saveData();
      toDoController.clear();
    });
  }

  Future<Null> refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else
          return 0;
      });
      saveData();
    });
  }

  Future<File> getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> saveData() async {
    String data = json.encode(toDoList);
    final file = await getFile();
    return file.writeAsString(data);
  }

  Future<String> readData() async {
    try {
      final file = await getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: ListTile(
          onTap: () {
            setState(() {
              bool status = toDoList[index]["ok"];
              if (status == true) {
                toDoList[index]["ok"] = false;
              } else {
                toDoList[index]["ok"] = true;
              }
              saveData();
            });
          },
          title: Text(toDoList[index]["title"]),
          subtitle: Text(toDoList[index]["coment"]),
          leading: CircleAvatar(
            backgroundColor: toDoList[index]["ok"] ? Colors.green : Colors.blue,
            child: mudaIcone(toDoList[index]["ok"]),
          ),
          trailing: Container(
            child: IconButton(
                icon: Icon(Icons.add_comment),
                onPressed: () {
                  if (toDoList[index]["coment"] == null ||
                      toDoList[index]["coment"] == "") {
                    comentController.clear();
                  } else {
                    comentController.text = toDoList[index]["coment"];
                  }
                  _settingModalBottomSheet(context, index);
                }),
            height: 50,
            width: 50,
          )),
      onDismissed: (direction) {
        setState(() {
          lastRemoved = Map.from(toDoList[index]);
          lastRemovedPos = index;
          toDoList.removeAt(index);
          saveData();
          final snack = SnackBar(
            content: Text("Tarefa \"${lastRemoved["title"]}\" removida"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    toDoList.insert(lastRemovedPos, lastRemoved);
                    saveData();
                  });
                }),
            duration: Duration(seconds: 3),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Widget mudaIcone(bool status) {
    if (status == true) {
      return Icon(
        Icons.check,
        color: Colors.white,
      );
    } else {
      return Icon(
        Icons.error,
        color: Colors.white,
      );
    }
  }

  void _settingModalBottomSheet(context, int index) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: Container(
                    child: new Wrap(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Container(
                            alignment: AlignmentDirectional.center,
                            child: Text(
                              "Digite uma descrição:",
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        new Padding(
                          padding: EdgeInsets.fromLTRB(10.0, 15.0, 15.0, 10.0),
                          child: TextField(
                            controller: comentController,
                            decoration: InputDecoration(
                              icon: Icon(Icons.edit),
                              labelText: "Descrição",
                              labelStyle: TextStyle(color: Colors.blueAccent),
                            ),
                            onChanged: (value) {
                              setState(() {
                                lastRemoved = Map.from(toDoList[index]);
                                lastRemovedPos = index;
                                toDoList.removeAt(index);
                                lastRemoved["coment"] = comentController.text;

                                toDoList.insert(lastRemovedPos, lastRemoved);
                                saveData();
                              });
                            },
                          ),
                        )
                      ],
                    ),
                  ))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              int i = 0;
              String mensagem = "      *** Lista de Tarefas ***\n";
              int j = 1;
              for (i = 0; i < toDoList.length; i++) {
                String titulo = toDoList[i]["title"];
                String situacao = toDoList[i]["ok"] ? "Feito" : "Pendente";
                String coment = toDoList[i]["coment"];
                dynamic meg = (titulo + situacao).split("").length;
                int limite = 30;
                String pontos = "";
                int h;
                if (meg < limite) {
                  int calc = limite - meg;

                  for (h = 0; h < calc; h++) {
                    pontos += ".";
                  }
                }
                mensagem += "$j - $titulo $pontos $situacao\n" + (coment != "" ? "*$coment\n" : "");
                j++;
              }
              Share.share(mensagem);
            },
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Form(
                key: formkey,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: toDoController,
                        decoration: InputDecoration(
                            labelText: "Nova Tarefa",
                            labelStyle: TextStyle(color: Colors.blueAccent)),
                        validator: (value) {
                          if (value.isEmpty) {
                            return "ops.. Esta sem tarefas?";
                          }
                        },
                      ),
                    ),
                    RaisedButton(
                      onPressed: () {
                        if (formkey.currentState.validate()) {
                          addToDo();
                        }
                      },
                      color: Colors.blueAccent,
                      child: Icon(Icons.add, color: Colors.white),
                      textColor: Colors.white,
                    )
                  ],
                ),
              )),
          Expanded(
              child: RefreshIndicator(
            child: ListView.builder(
              padding: EdgeInsets.only(top: 10.0),
              itemCount: toDoList.length,
              itemBuilder: buildItem,
            ),
            onRefresh: refresh,
          )),
        ],
      ),
    );
  }
}
