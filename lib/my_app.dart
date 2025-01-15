import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sota_snake_game/main.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sota Snake Game',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
      ),
      home: const SnakeGame(),
    );
  }
}
