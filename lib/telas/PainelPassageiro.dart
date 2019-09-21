import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

import 'package:uber/model/Destino.dart';
import 'package:uber/model/Requisicao.dart';
import 'package:uber/model/Usuario.dart';
import 'package:uber/util/Status.dart';
import 'package:uber/util/UsuarioFirebase.dart';

class PainelPassageiro extends StatefulWidget {
  @override
  _PainelPassageiroState createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro> {
  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _posicaoCamera = CameraPosition(
      target: LatLng(-23.562436, -46.655005),
  );
  List<String> itensMenu = [
    "Configurações", "Deslogar"
  ];
  Set<Marker> _marcadores = {};
  TextEditingController _controllerDestino = TextEditingController();
  bool _exibirCaixaEnderecoDestino = true;
  String _textoBotao = "Chamar uber";
  Color _corBotao = Color(0xff1ebbd8);
  Function _funcaoBotao;
  String _idRequisicao;
  Position _definirLocalPassageiro;

  _exibirMarcador(Position position) async{

    double pixelRatio =MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRatio),
        "images/passageiro.png"
    ).then((BitmapDescriptor icone){
      Marker marcadoPassageiro = Marker(
        markerId: MarkerId("marcador-passageiro"),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(
            title: "Meu local"
        ),
        icon: icone,
      );
      setState(() {
        _marcadores.add(marcadoPassageiro);
      });
    });


  }

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

  _onMapCreated(GoogleMapController controller){
    _controller.complete(controller);
  }

  _adicionarListenerLocalizado(){
    var geolocator = Geolocator();
    var localOptions = LocationOptions(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10
    );
    geolocator.getPositionStream(localOptions).listen((Position position){
      _exibirMarcador(position);
      _posicaoCamera = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 19,
      );
      _definirLocalPassageiro = position;
      _movimentarCamera(_posicaoCamera);
    });
  }

  _recuperarUltimaLocalizacao() async {
    Position position = await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      if(position != null){
        _exibirMarcador(position);
        _posicaoCamera = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 19,
        );
        _definirLocalPassageiro = position;
        _movimentarCamera(_posicaoCamera);
      }
    });
  }

  _movimentarCamera(CameraPosition cameraPosition) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        cameraPosition
      )
    );
  }

  _salvarRequisicao(Destino destino) async {
    Requisicao requisicao = Requisicao();
    Usuario passageiro = await UsuarioFirebase.getDadosUsuarioLogado();
    passageiro.latitude = _definirLocalPassageiro.latitude;
    passageiro.longitude = _definirLocalPassageiro.longitude;
    requisicao.destino = destino;
    requisicao.passageiro = passageiro;
    requisicao.status = Status.AGUARDANDO;
    
    Firestore db = Firestore.instance;
    db.collection("requisicoes")
    .document(requisicao.id)
    .setData(requisicao.toMap());

    Map<String, dynamic> dadosRequisicaoAtiva = {};
    dadosRequisicaoAtiva["id_requisicao"] = requisicao.id;
    dadosRequisicaoAtiva["id_usuario"] = passageiro.idUsuario;
    dadosRequisicaoAtiva["status"] = Status.AGUARDANDO;

    db.collection("requisicao_ativa")
    .document(passageiro.idUsuario)
    .setData(dadosRequisicaoAtiva);

  }

  _chamarUber() async {
    String enderecoDestino = _controllerDestino.text;
    if(enderecoDestino.isNotEmpty){
      List<Placemark> listaEnderecos = await Geolocator()
          .placemarkFromAddress(enderecoDestino);

      if(listaEnderecos != null && listaEnderecos.length >0){
        Placemark endereco = listaEnderecos[0];
        Destino destino = Destino();

        destino.cidade = endereco.administrativeArea;
        destino.cep = endereco.postalCode;
        destino.bairro = endereco.subLocality;
        destino.rua = endereco.thoroughfare;
        destino.numero = endereco.subThoroughfare;

        destino.latitude = endereco.position.latitude;
        destino.longitude = endereco.position.longitude;

        String enderecoConfirmacao;
        enderecoConfirmacao = "\n Cidade: " + destino.cidade;
        enderecoConfirmacao += "\n Bairro: " + destino.bairro;
        enderecoConfirmacao += "\n Rua: " + destino.rua;
        enderecoConfirmacao += "\n Número: " + destino.numero;

        showDialog(
            context: context,
            builder: (context){
              return AlertDialog(
                title: Text("Confirmação do endereço"),
                content: Text(enderecoConfirmacao),
                contentPadding: EdgeInsets.all(16),
                actions: <Widget>[
                  FlatButton(
                    onPressed: (){
                      _salvarRequisicao(destino);
                      Navigator.pop(context);
                    },
                    child: Text("Confirmar", style: TextStyle(color: Colors.green),)
                  ),
                  FlatButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancelar", style: TextStyle(color: Colors.red),)
                  ),
                ],
              );
            }
        );
      }
    } else{
      showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: Text("O campo não estar vazia! Preencha com um endereço "),
            contentPadding: EdgeInsets.all(16),
            actions: <Widget>[
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Confirmar", style: TextStyle(color: Colors.green),)
              ),
            ],
          );
        }
      );
    }
  }

  _alterarBotaoPrincipal(String texto, Color cor, Function funcao){
    setState(() {
      _textoBotao = texto;
      _corBotao = cor;
      _funcaoBotao = funcao;
    });
  }

  _statusUberNaoChamado(){
    _exibirCaixaEnderecoDestino = true;

    _alterarBotaoPrincipal(
        "Chamar uber",
        Color(0xff1ebbd8),
        (){
          _chamarUber();
        }
    );
  }

  _cancelarUber() async {
    FirebaseUser firebaseUser = await UsuarioFirebase.getUsuarioAtual();
    Firestore db = Firestore.instance;

    db.collection("requisicoes")
    .document(_idRequisicao)
    .updateData({
      "status": Status.CANCELADA
    }).then((_){
      db.collection("requisicao_ativa")
          .document(firebaseUser.uid).delete();
    });
  }

  _adicionarListenerRequisicaoAtiva() async {
    FirebaseUser firebaseUser = await UsuarioFirebase.getUsuarioAtual();
    Firestore db = Firestore.instance;
    await db.collection("requisicao_ativa")
    .document(firebaseUser.uid)
    .snapshots()
    .listen((snapshot){
      if(snapshot.data != null ){
        Map<String, dynamic> dados = snapshot.data;
        String status = dados["status"];
        _idRequisicao = dados["id_requisicao"];
        switch(status){
          case Status.AGUARDANDO:
            _statusAguardando();
            break;
          case Status.A_CAMINHO:
            _statusACaminho();
            break;
          case Status.VIAGEM:
            break;
          case Status.FINALIZADA:
            break;
          case Status.CANCELADA:
            break;
        }
      } else {
        _statusUberNaoChamado();
      }

    });
  }

  _statusACaminho(){
    _exibirCaixaEnderecoDestino = false;

    _alterarBotaoPrincipal(
        "Motorista a caminho",
        Colors.grey,
        null
    );
  }

  _statusAguardando(){
    _exibirCaixaEnderecoDestino = false;

    _alterarBotaoPrincipal(
        "Cancelar",
        Colors.red,
            (){
          _cancelarUber();
        }
    );
  }

  @override
  void initState() {
    super.initState();
    _recuperarUltimaLocalizacao();
    _adicionarListenerLocalizado();
    _adicionarListenerRequisicaoAtiva();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel passageiro"),
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
      body: Container(
        child: Stack(
          children: <Widget>[
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _posicaoCamera,
              onMapCreated: _onMapCreated,
//              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: _marcadores,
            ),
           Visibility(
             visible: _exibirCaixaEnderecoDestino,
             child: Stack(
               children: <Widget>[
                 Positioned(
                   top: 0,
                   left: 0,
                   right: 0,
                   child: Padding(
                     padding: EdgeInsets.all(10),
                     child: Container(
                       height: 50,
                       width: double.infinity,
                       decoration: BoxDecoration(
                           border: Border.all(color: Colors.grey),
                           borderRadius: BorderRadius.circular(3),
                           color: Colors.white
                       ),
                       child: TextField(
                         readOnly: true,
                         decoration: InputDecoration(
                             icon: Container(
                               margin: EdgeInsets.only(left: 20),
                               width: 10,
                               height: 10,
                               child: Icon(Icons.location_on, color: Colors.green),
                             ),
                             hintText: "Meu local",
                             border: InputBorder.none,
                             contentPadding: EdgeInsets.only(left: 15, top: 16)
                         ),
                       ),
                     ),
                   ),
                 ),
                 Positioned(
                   top: 55,
                   left: 0,
                   right: 0,
                   child: Padding(
                     padding: EdgeInsets.all(10),
                     child: Container(
                       height: 50,
                       width: double.infinity,
                       decoration: BoxDecoration(
                           border: Border.all(color: Colors.grey),
                           borderRadius: BorderRadius.circular(3),
                           color: Colors.white
                       ),
                       child: TextField(
                         controller: _controllerDestino,
                         decoration: InputDecoration(
                             icon: Container(
                               margin: EdgeInsets.only(left: 20),
                               width: 10,
                               height: 10,
                               child: Icon(Icons.local_taxi, color: Colors.black),
                             ),
                             hintText: "Meu destino",
                             border: InputBorder.none,
                             contentPadding: EdgeInsets.only(left: 15, top: 16)
                         ),
                       ),
                     ),
                   ),
                 ),
               ],
             ),
           ),
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: Padding(
                padding: Platform.isIOS
                    ? EdgeInsets.fromLTRB(20, 10, 20, 25)
                    : EdgeInsets.all(10),
                child: RaisedButton(
                  child: Text(
                    _textoBotao,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  color: _corBotao,
                  padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                  onPressed:_funcaoBotao
                ),
              )
            ),
          ],
        ),
      ),
    );
  }
}
