import 'package:flutter/material.dart';
import 'package:uber/model/Usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Cadastro extends StatefulWidget {
  @override
  _CadastroState createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  TextEditingController _controllerNome = TextEditingController();
  TextEditingController _controllerEmail = TextEditingController();
  TextEditingController _controllerSenha = TextEditingController();
  bool _escolhaModo = false;
  String _mensagemErro = "";

  _validarCampos(){
    String nome = _controllerNome.text;
    String email = _controllerEmail.text;
    String senha = _controllerSenha.text;

    if(nome.isNotEmpty){
      if(senha.isNotEmpty){
        if(senha.length >= 6){
          if(email.isNotEmpty){
            if(email.contains("@")){


              Usuario usuario = Usuario();
              usuario.nome = nome;
              usuario.email = email;
              usuario.senha = senha;
              usuario.tipoUsuario = usuario.verificaTipoUsuario(_escolhaModo);

              _cadastrarUsuario(usuario);

            } else {
              setState(() {
                _mensagemErro = "Utilize um @ no email";
              });
            }
          } else {
            setState(() {
              _mensagemErro = "Preenhca o email";
            });
          }
        } else{
          setState(() {
            _mensagemErro = "Senha precisa ter pelo menos 6 digitos";
          });
        }
      } else {
        setState(() {
          _mensagemErro = "Preenhca a senha";
        });
      }
    } else {
      setState(() {
        _mensagemErro = "Preencha o nome";
      });
    }

  }

  _cadastrarUsuario(Usuario usuario){
    FirebaseAuth auth = FirebaseAuth.instance;
    Firestore db = Firestore.instance;
    auth.createUserWithEmailAndPassword(
        email: usuario.email,
        password: usuario.senha
    ).then((firebaseUser){
      db.collection("usuarios").document(firebaseUser.user.uid)
          .setData(usuario.toMap());
    });
    switch(usuario.tipoUsuario){
      case "motorista":
        Navigator.pushNamedAndRemoveUntil(
            context,
            "/painel-motorista",
            (_) => false
        );
        break;
      case "passageiro":
        Navigator.pushNamedAndRemoveUntil(
            context,
            "/painel-passageiro",
                (_) => false
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cadastro"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[

              TextField(
                keyboardType: TextInputType.text,
                controller: _controllerNome,
                style: TextStyle(
                    fontSize: 20
                ),
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    hintText: "Nome",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6)
                    )
                ),
              ),
              TextField(
                keyboardType: TextInputType.emailAddress,
                controller: _controllerEmail,
                style: TextStyle(
                    fontSize: 20
                ),
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    hintText: "e-mail",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6)
                    )
                ),
              ),
              TextField(
                obscureText: true,
                keyboardType: TextInputType.text,
                controller: _controllerSenha,
                style: TextStyle(
                    fontSize: 20
                ),
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    hintText: "Senha",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6)
                    )
                ),
              ),
              Row(
                children: <Widget>[
                  Text("Passageiro"),
                  Switch(
                    value: _escolhaModo,
                    onChanged: (bool valor){
                      setState(() {
                        _escolhaModo = valor;
                      });
                    },
                  ),
                  Text("Motorista"),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    _mensagemErro,
                    style: TextStyle(color: Colors.red,fontSize: 20),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: RaisedButton(
                  onPressed: (){
                    _validarCampos();
                  },
                  child: Text("Cadastrar", style: TextStyle(color: Colors.white, fontSize: 20),),
                  color: Color(0xff1ebbd8),
                  padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
