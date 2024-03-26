import 'package:flutter/material.dart';
import 'package:tcp_socket_connection/tcp_socket_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:convert';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  late TcpSocketConnection socketConnection;
  final textContent = TextEditingController();
  final ctrlLimit = TextEditingController(text: "1500");
  double voltage = 0, current = 0, energy = 0, power = 0, powerLimit = 1500;
  bool isConnected = false;
  @override
  void initState() {
    super.initState();
    prefs.then((value) => {
          textContent.text = value.getString('ip') ?? '192.168.4.1',
        });
  }

  void messageReceived(String msg) {
    setState(() {
      final dataList = msg.split(',');
      energy = double.parse(dataList[0]);
      power = double.parse(dataList[1]);
      voltage = double.parse(dataList[2]);
    });
    // List<int> bytes = utf8.encode(msg);
    // debugPrint(bytes.toString());
  }

  Future<bool> startConnection(String ip) async {
    socketConnection = TcpSocketConnection(ip, 1322);

    if (await socketConnection.canConnect(5000, attempts: 3)) {
      await socketConnection.connect(5000, messageReceived, attempts: 3);
    }
    return socketConnection.isConnected();
  }

  @override
  Widget build(BuildContext context) {
    double scrWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(15),
            decoration:
                BoxDecoration(border: Border.all(), color: Colors.blueGrey),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                  child: SizedBox(
                    width: scrWidth * 0.40,
                    height: 55,
                    child: TextField(
                      controller: textContent,
                      decoration: const InputDecoration(
                          labelText: 'IP: ',
                          labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          hintText: '192.168.4.1',
                          hintStyle: TextStyle(fontSize: 12)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                    onPressed: () {
                      if (!isConnected) {
                        startConnection(textContent.text).then((value) => {
                              setState(() {
                                isConnected = value;
                                prefs.then((value) =>
                                    {value.setString('ip', textContent.text)});
                              })
                            });
                      } else {
                        setState(() {
                          socketConnection.disconnect();
                          isConnected = false;
                        });
                      }
                    },
                    style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(
                            (isConnected
                                ? Colors.lightGreenAccent
                                : Colors.redAccent))),
                    icon: const Icon(Icons.connect_without_contact_sharp),
                    label: Text((isConnected ? 'Disconnect' : 'Connect')))
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(15),
            decoration:
                BoxDecoration(border: Border.all(), color: Colors.blueGrey),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                  child: SizedBox(
                    width: scrWidth * 0.40,
                    height: 55,
                    child: TextField(
                      controller: ctrlLimit,
                      decoration: const InputDecoration(
                          labelText: 'Power Limit: ',
                          labelStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          hintText: 'watts',
                          hintStyle: TextStyle(fontSize: 12)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                    onPressed: () {
                      if (isConnected) {
                        socketConnection.sendMessage(ctrlLimit.text);
                        powerLimit = double.parse(ctrlLimit.text);
                        ctrlLimit.clear();
                      }
                    },
                    style: const ButtonStyle(
                        backgroundColor:
                            MaterialStatePropertyAll<Color>((Colors.white))),
                    icon: const Icon(Icons.electric_bolt),
                    label: const Text('Set'))
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 50, 0, 30),
            child: SfRadialGauge(
              axes: [
                RadialAxis(
                  minimum: 0,
                  maximum: powerLimit,
                  ranges: [
                    GaugeRange(
                      startValue: 0,
                      endValue: (powerLimit / 6),
                      color: const Color.fromARGB(255, 36, 187, 247),
                    ),
                    GaugeRange(
                      startValue: (powerLimit / 6),
                      endValue: (powerLimit / 6) * 2,
                      color: const Color.fromARGB(255, 36, 92, 247),
                    ),
                    GaugeRange(
                      startValue: (powerLimit / 6) * 2,
                      endValue: (powerLimit / 6) * 3,
                      color: const Color.fromARGB(255, 15, 250, 7),
                    ),
                    GaugeRange(
                      startValue: (powerLimit / 6) * 3,
                      endValue: (powerLimit / 6) * 4,
                      color: const Color.fromARGB(255, 250, 246, 7),
                    ),
                    GaugeRange(
                      startValue: (powerLimit / 6) * 4,
                      endValue: (powerLimit / 6) * 5,
                      color: const Color.fromARGB(255, 255, 115, 0),
                    ),
                    GaugeRange(
                      startValue: (powerLimit / 6) * 5,
                      endValue: powerLimit,
                      color: const Color.fromARGB(255, 255, 0, 0),
                    ),
                  ],
                  pointers: [
                    NeedlePointer(
                      value: power,
                      enableAnimation: true,
                    )
                  ],
                  annotations: [
                    GaugeAnnotation(
                      widget: Container(
                          padding: const EdgeInsets.fromLTRB(0, 175, 0, 0),
                          child: Text(
                            '${power.toStringAsFixed(1)}W',
                            style: const TextStyle(
                              fontFamily: 'Calibre',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                      angle: 180.0 * (power / 180.0),
                      positionFactor: 0,
                    )
                  ],
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 50, 0, 30),
            child: SfRadialGauge(
              axes: [
                RadialAxis(
                  minimum: 0,
                  maximum: 380,
                  ranges: [
                    GaugeRange(
                      startValue: 0,
                      endValue: 80,
                      color: const Color.fromARGB(255, 36, 187, 247),
                    ),
                    GaugeRange(
                      startValue: 80.1,
                      endValue: 160,
                      color: const Color.fromARGB(255, 36, 92, 247),
                    ),
                    GaugeRange(
                      startValue: 160.1,
                      endValue: 260,
                      color: const Color.fromARGB(255, 250, 246, 7),
                    ),
                    GaugeRange(
                      startValue: 260.1,
                      endValue: 300,
                      color: const Color.fromARGB(255, 250, 153, 7),
                    ),
                    GaugeRange(
                      startValue: 300.1,
                      endValue: 380,
                      color: const Color.fromARGB(255, 250, 35, 7),
                    ),
                  ],
                  pointers: [
                    NeedlePointer(
                      value: voltage,
                      enableAnimation: true,
                    )
                  ],
                  annotations: [
                    GaugeAnnotation(
                      widget: Container(
                          padding: const EdgeInsets.fromLTRB(0, 175, 0, 0),
                          child: Text(
                            '${voltage.toStringAsFixed(1)}V',
                            style: const TextStyle(
                              fontFamily: 'Calibre',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                      angle: 180.0 * (voltage / 180.0),
                      positionFactor: 0,
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
