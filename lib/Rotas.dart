import 'package:flutter/material.dart';
import 'package:uber/telas/Cadastro.dart';
import 'package:uber/telas/Corrida.dart';
import 'package:uber/telas/Home.dart';
import 'package:uber/telas/Login.dart';
import 'package:uber/telas/PainelMotorista.dart';
import 'package:uber/telas/PainelPassageiro.dart';
class Rotas {
  // ignore: missing_return
  static Route<dynamic> rotas(RouteSettings settings){
    final args = settings.arguments;
    switch(settings.name){
      case "/":
        return MaterialPageRoute(builder: (_) =>Login());
        break;
      case "/login":
        return MaterialPageRoute(builder: (_) =>Login());
        break;
      case "/cadastro":
        return MaterialPageRoute(builder: (_) =>Cadastro());
        break;
      case "/home":
        return MaterialPageRoute(builder: (_) =>Home());
        break;
      case "/painel-passageiro":
        return MaterialPageRoute(builder: (_) =>PainelPassageiro());
        break;
      case "/painel-motorista":
        return MaterialPageRoute(builder: (_) =>PainelMotororista());
        break;
      case "/corrida":
        return MaterialPageRoute(builder: (_) =>Corrida(
          args
        ));
        break;
      default:
        _erroRota();
    }
  }
  static Route<dynamic> _erroRota() {
    return MaterialPageRoute(
        builder: (_) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Tela não encontrada"),
            ),
            body: Center(
              child: Text("Tela não encontrada"),
            ),
          );
        }
    );
  }
}