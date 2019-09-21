import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/model/Requisicao.dart';
import 'package:uber/util/Status.dart';
import 'package:uber/util/UsuarioFirebase.dart';

class PainelMotororista extends StatefulWidget {
  @override
  _PainelMotororistaState createState() => _PainelMotororistaState();
}

class _PainelMotororistaState extends State<PainelMotororista> {
  List<String> itensMenu = [
    "Configurações", "Deslogar"
  ];
  final _controller = StreamController<QuerySnapshot>.broadcast();
  Firestore db = Firestore.instance;
  _escolhaMenuItem(String escolha){
    switch(escolha){
      case "Configurações":
        break;
      case "Deslogar":
        _deslogarUsuario();
        break;
    }
  }

  _deslogarUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    Navigator.pushReplacementNamed(context, "/");
  }

  Stream<QuerySnapshot> _adicionarListinerRequisicoes() {
    final stream = db.collection("requisicoes")
        .where("status", isEqualTo: Status.AGUARDANDO)
        .snapshots();
    stream.listen((dados){
      _controller.add(dados);
    });
  }
  _recuperarRequisicaoAtivaMotorista()async{
    FirebaseUser firebaseUser = await UsuarioFirebase.getUsuarioAtual();
    DocumentSnapshot documentSnapshot = await db.collection("requisicao_ativa_motorista")
        .document(firebaseUser.uid).get();

    var dadosRequisicao = documentSnapshot.data;

    if(dadosRequisicao == null){
      _adicionarListinerRequisicoes();
    } else {
      String idRequisicao = dadosRequisicao["id_requisicao"];
      Navigator.pushReplacementNamed(context, "/corrida", arguments: idRequisicao);
    }

  }

  @override
  void initState() {
    super.initState();
    _recuperarRequisicaoAtivaMotorista();


  }

  @override
  Widget build(BuildContext context) {
    var mensagemCarregando = Center(
      child: Column(
        children: <Widget>[
          Text("Carregando requisições"),
          CircularProgressIndicator()
        ],
      ),
    );
    var mensagemNaoTemDado = Center(
      child: Text(
        "Carregando requisições",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel motorista"),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _escolhaMenuItem,
            itemBuilder: (context){
              return itensMenu.map((String item){
                return PopupMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList();
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        // ignore: missing_return
        builder: (context, snapshot){
          switch(snapshot.connectionState){
            case ConnectionState.none:
            case ConnectionState.waiting:
              return mensagemCarregando;
              break;
            case ConnectionState.active:
            case ConnectionState.done:
              if(snapshot.hasError){
                return Text("Erro ao carergar os dados!");
              }else {
                QuerySnapshot querySnapshot = snapshot.data;
                if(querySnapshot.documents.length == 0){
                  return mensagemNaoTemDado;
                } else {
                  return ListView.separated(
                    itemCount: querySnapshot.documents.length,
                    separatorBuilder: (context, indice) => Divider(
                      height: 2,
                      color: Colors.grey,
                    ),
                    itemBuilder: (context, indice){
                      List<DocumentSnapshot> requisicoes = querySnapshot.documents.toList();
                      DocumentSnapshot item = requisicoes[indice];

                      String idRequisicao = item["id"];
                      String nomePassageiro = item["passageiro"]["nome"];
                      String rua = item["destino"]["rua"];
                      String numero = item["destino"]["numero"];

                      return ListTile(
                        title: Text(nomePassageiro),
                        subtitle: Text("Destino: $rua, $numero"),
                        onTap: (){
                          Navigator.pushNamed(context, "/corrida", arguments: idRequisicao);
                        },
                      );
                    },
                  );
                }
              }
              break;
          }
        },
      ),
    );
  }
}
