import 'package:flutter/material.dart';
import 'package:uber/telas/Login.dart';
import 'Rotas.dart';

final ThemeData temaPadrao = ThemeData(
  primaryColor: Color(0xff37474f),
  accentColor: Color(0xff546e7a)
);

void main() {
  runApp(
    MaterialApp(
      home: Login(),
      theme: temaPadrao,
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      onGenerateRoute: Rotas.rotas,
    ),
  );
}

