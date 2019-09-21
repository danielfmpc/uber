import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uber/model/Usuario.dart';
import 'dart:io';

import 'package:uber/util/Status.dart';
import 'package:uber/util/UsuarioFirebase.dart';

class Corrida extends StatefulWidget {
  String idRequisicao;
  Corrida(this.idRequisicao);
  @override
  _CorridaState createState() => _CorridaState();
}

class _CorridaState extends State<Corrida> {
  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _posicaoCamera = CameraPosition(
    target: LatLng(-23.562436, -46.655005),
  );
  List<String> itensMenu = [
    "Configurações", "Deslogar"
  ];


  Set<Marker> _marcadores = {};

  String _textoBotao = "Aceitar corrida";
  Color _corBotao = Color(0xff1ebbd8);
  Function _funcaoBotao;

  Map<String, dynamic> _dadosRequisicao;

  Position _localMotorista;

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

  _alterarBotaoPrincipal(String texto, Color cor, Function funcao){
    setState(() {
      _textoBotao = texto;
      _corBotao = cor;
      _funcaoBotao = funcao;
    });
  }

  _onMapCreated(GoogleMapController controller){
    _controller.complete(controller);
  }

  _exibirMarcador(Position position) async{

    double pixelRatio =MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRatio),
        "images/motorista.png"
    ).then((BitmapDescriptor icone){
      Marker marcadoPassageiro = Marker(
        markerId: MarkerId("marcador-motorista"),
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

  _movimentarCamera(CameraPosition cameraPosition) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
            cameraPosition
        )
    );
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
        _movimentarCamera(_posicaoCamera);
        _localMotorista = position;
      }
    });
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
      _movimentarCamera(_posicaoCamera);
      setState(() {
        _localMotorista = position;
      });
    });
  }
  _recuperarRequisicao() async{
    String idRequisicao = widget.idRequisicao;
    Firestore db = Firestore.instance;
    DocumentSnapshot documentSnapshot = await db.collection("requisicoes").document(idRequisicao)
    .get();

    _dadosRequisicao = documentSnapshot.data;
    _adicionarListenerRequisicao();

  }

  _adicionarListenerRequisicao() async {
    Firestore db = Firestore.instance;
    String idRequisicao = _dadosRequisicao["id"];
    await db.collection("requisicoes").document(idRequisicao)
    .snapshots().listen((snapshot){
      if (snapshot.data != null){
        Map<String, dynamic> dados = snapshot.data;
        String status = dados["status"];

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
      }
    });
  }

  _statusAguardando(){
    _alterarBotaoPrincipal(
        "Aceitar corrida",
        Color(0xff1ebbd8),
        (){
          _aceitarUber();
        }
    );
  }

  _statusACaminho(){
    _alterarBotaoPrincipal(
        "A caminho do passageiro",
        Colors.grey,
        null
    );
    double latitudePassageiro = _dadosRequisicao["passageiro"]["latitude"];
    double longitudePassageiro = _dadosRequisicao["passageiro"]["longitude"];

    double latitudeMotorista = _dadosRequisicao["motorista"]["latitude"];
    double longitudeMotorista = _dadosRequisicao["motorista"]["longitude"];

    _exibirDoisMacadores(
      LatLng(latitudeMotorista, longitudeMotorista),
      LatLng(latitudePassageiro, longitudePassageiro),
    );

  }

  _exibirDoisMacadores(LatLng latLng1, LatLng latLng2){
    double pixelRatio =MediaQuery.of(context).devicePixelRatio;
    Set<Marker> _listaMarcadores = {};
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRatio),
        "images/motorista.png"
    ).then((BitmapDescriptor icone){
      Marker marcado1 = Marker(
        markerId: MarkerId("marcador-motorista"),
        position: LatLng(latLng1.latitude, latLng1.longitude),
        infoWindow: InfoWindow(
            title: "Local motorista"
        ),
        icon: icone,
      );
      _listaMarcadores.add(marcado1);
    });

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRatio),
        "images/passageiro.png"
    ).then((BitmapDescriptor icone){
      Marker marcado2 = Marker(
        markerId: MarkerId("marcador-passageiro"),
        position: LatLng(latLng2.latitude, latLng2.longitude),
        infoWindow: InfoWindow(
            title: "Local passageiro"
        ),
        icon: icone,
      );
      _listaMarcadores.add(marcado2);
    });

    setState(() {
      _marcadores = _listaMarcadores;
      _movimentarCamera(CameraPosition(
        target: LatLng(latLng1.latitude, latLng1.longitude),
        zoom: 15
      ));
    });
  }

  _aceitarUber() async {
    Usuario motorista = await UsuarioFirebase.getDadosUsuarioLogado();
    motorista.longitude = _localMotorista.latitude;
    motorista.longitude = _localMotorista.longitude;


    String idRequisicao = _dadosRequisicao["id"];
    Firestore db = Firestore.instance;

    db.collection("requisicoes")
    .document(idRequisicao)
    .updateData({
      "motorista": motorista.toMap(),
      "status": Status.A_CAMINHO,
    }).then((_){

      String idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"];
      db.collection("requisicao_ativa")
          .document( idPassageiro ).updateData({
        "status" : Status.A_CAMINHO,
      });

      //Salvar requisicao ativa para motorista
      String idMotorista = motorista.idUsuario;
      db.collection("requisicao_ativa_motorista")
          .document( idMotorista )
          .setData({
        "id_requisicao" : idRequisicao,
        "id_usuario" : idMotorista,
        "status" : Status.A_CAMINHO,
      });

    });
  }
  @override
  void initState() {
    super.initState();
    _recuperarUltimaLocalizacao();
    _adicionarListenerLocalizado();

    _recuperarRequisicao();
  }
  @override
  Widget build(BuildContext context) {
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
