import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

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
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedPos;

  //Para carregar os dados é preciso sobrescrever a função em que é chamada quando o app é iniciado
  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  final _tarefaController = TextEditingController();

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo['title'] = _tarefaController.text;
      _tarefaController.text = '';
      newToDo['ok'] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text(
          'Lista de Tarefas',
        ),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                //Quando der erro 'layoutConstraints.maxWidth < double.infinity' utilizar o Expanded, ele vai expandir o componente o maximo que der
                Expanded(
                  child: TextField(
                    controller: _tarefaController,
                    decoration: InputDecoration(
                        labelText: 'Nova Tarefa',
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem),
          )
        ],
      ),
    );
  }

  //Pega o diretorio documents da aplicação, seja ios ou android (há vários tipos de diretorios)
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  //Salva a lista
  Future<File> _saveData() async {
    //Converte a lista em json
    String data = json.encode(_toDoList);
    final file = await _getFile();
    //Retorna o arquivo como string
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(_toDoList[index].toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(
          _toDoList[index]['title'],
          style: _toDoList[index]['ok']
              ? TextStyle(decoration: TextDecoration.lineThrough)
              : TextStyle(fontStyle: FontStyle.normal),
        ),
        value: _toDoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['ok'] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]['ok'] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved['title']}\" removida!"),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          //Remove a snackbar para exibir a proxima
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }
}
