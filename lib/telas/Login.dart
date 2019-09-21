import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/model/Usuario.dart';
class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController _controllerEmail = TextEditingController();
  TextEditingController _controllerSenha = TextEditingController();
  String _mensagemErro = "";
  bool _carregando = false;

  _validarCampos(){
    String email = _controllerEmail.text;
    String senha = _controllerSenha.text;


    if(email.isNotEmpty){
      if(email.contains("@")){
        if(senha.isNotEmpty){
          if(senha.length >= 6){
            Usuario usuario = Usuario();
            usuario.email = email;
            usuario.senha = senha;

            _logarUsuario(usuario);

          } else{
            setState(() {
              _mensagemErro = "Senha precisa ter pelo menos 6 digitos";
            });
          }
        } else {
          setState(() {
            _mensagemErro = "Preenheca a senha";
          });
        }
      } else {
        setState(() {
          _mensagemErro = "Utilize um @ no email";
        });
      }
    } else {
      setState(() {
        _mensagemErro = "Preenheca o email";
      });
    }
  }
  _logarUsuario(Usuario usuario){
    setState(() {
      _carregando = true;
    });
    FirebaseAuth auth = FirebaseAuth.instance;
    auth.signInWithEmailAndPassword(email: usuario.email, password: usuario.senha)
    .then((firebaseUser){
//      Navigator.pushReplacementNamed(context, "/painel-passageiro");
      _redirecionaTipoUsuario(firebaseUser.user.uid);

    }).catchError((error){
      print(error);
      setState(() {
        _mensagemErro = "Erro ao autenticar usuário! Tente novamente mais tarde";
      });
    });
  }

  _redirecionaTipoUsuario(String idUsuario) async {
    Firestore db = Firestore.instance;
    DocumentSnapshot snapshot = await db.collection("usuarios")
    .document(idUsuario).get();

    Map<String, dynamic> dados = snapshot.data;
    String tipoUsuario = dados["tipoUsuario"];
    setState(() {
      _carregando = false;
    });
    switch(tipoUsuario){
      case "motorista":
        Navigator.pushReplacementNamed(
          context,
          "/painel-motorista",
        );
        break;
      case "passageiro":
        Navigator.pushReplacementNamed(
          context,
          "/painel-passageiro",
        );
        break;
    }
  }
  _verificaUsuarioLogadio() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();
    if(usuarioLogado != null){
      String idUsuario = usuarioLogado.uid;
      _redirecionaTipoUsuario(idUsuario);
    }
  }

  @override
  void initState() {
    super.initState();
    _verificaUsuarioLogadio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(image: DecorationImage(
          image: AssetImage("images/fundo.png"),
          fit: BoxFit.cover,
        )),
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: Image.asset("images/logo.png", width: 200, height: 150,),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      _mensagemErro,
                      style: TextStyle(color: Colors.white,fontSize: 20),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _carregando
                      ? Center(child: CircularProgressIndicator(backgroundColor: Colors.white,))
                      : Container(),
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
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 10),
                  child: RaisedButton(
                    onPressed: (){
                      _validarCampos();
                    },
                    child: Text("Entrar", style: TextStyle(color: Colors.white, fontSize: 20),),
                    color: Color(0xff1ebbd8),
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    child: Text(
                      "Não tem conta? cadaste-se",
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: (){
                      Navigator.pushNamed(context, "/cadastro");
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
