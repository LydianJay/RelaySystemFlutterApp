import 'package:flutter/material.dart';
import 'package:relaysystem/view/mainview.dart';

class RelaySystem extends StatelessWidget {
  const RelaySystem({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relay System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainView(),
    );
  }
}
