// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();

  List _toDoList = [];
  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPos;

//Ler os dados
  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        //Aceita widget text e não só string
        title: Text('Lista de tarefas'),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                      labelText: 'Nova tarefa',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                ElevatedButton(onPressed: _addToDo, child: Text('Add'))
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem),
          ))
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    //widget de arrastar para excluir
    return Dismissible(
      //pega o tempo em milisegundos e transforma em string, essa key aceita qualquer string, mas vai ter que ser diferente para todos os itens
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(Icons.delete, color: Colors.white),
          )),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['ok'] ? Icons.check : Icons.error),
        ),
        //onChanged é chamado quando clico no elemento da lista, passando o parâmetro c como true ou false
        onChanged: (c) {
          setState(() {
            //armazeno esse true ou false no ok do elemento da lista e dá um setState para atualizar a lista com o novo estado
            _toDoList[index]['ok'] = c;
            _saveData();
          });
        },
      ),
      //dentro desse onDismissed terá uma função que será chamada sempre que arrastar o item para a direita para remoção
      onDismissed: (direction) {
        setState(() {
          //duplica o item
          _lastRemoved = Map.from(_toDoList[index]);
          //salvar o item
          _lastRemovedPos = index;
          //removemos o item
          _toDoList.removeAt(index);
          //salva tudo
          _saveData();

          final snack = SnackBar(
            content: Text('Tarefa \'${_lastRemoved['title']}\' removida!'),
            action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () {
                  setState(() {
                    //recoloca o item removido na lista
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  //função que vai retornar o arquivo que vou utilizar para salvar
//tudo que envolve leitura e tratamento de arquivos precisa ser assíncrono já que não ocorre imediatamente
  Future<File> _getFile() async {
    //essa função vai pegar o diretório onde posso armazenar os documentos do meu app
    final directory = await getApplicationDocumentsDirectory();
    //aqui vou abrir o arquivo através do file
    return File('${directory.path}/data.json');
  }

//função para salvar os dados
  Future<File> _saveData() async {
    //transforma a lista em json e armazena numa string
    String data = json.encode(_toDoList);

    //pegamos o arquivo onde vamos salvar
    final file = await _getFile();

    //vamos escrever nossos dados da lista de tarefas como texto dentro do nosso arquivo
    return file.writeAsString(data);
  }

  //função para ler os dados
  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      //tenta ler o arquivo como string e retorna
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  //função de add nova tarefa
  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo['title'] = _toDoController.text;
      _toDoController.text = "";
      newToDo['ok'] = false;
      _toDoList.add(newToDo);
    });
  }

  //função de atualizar e ordernar
  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      //ordena
      _toDoList.sort((a, b) {
        if (a['ok'] && !b['ok'])
          return 1;
        else if (!a['ok'] && b['ok'])
          return -1;
        else
          return 0;
      });
      _saveData();
    });

    return null;
  }
}
