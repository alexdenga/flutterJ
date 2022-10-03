import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:ade_flutterwave_working_version/example.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdeFlutterEntrance());
}

class AdeFlutterEntrance extends StatelessWidget {
  const AdeFlutterEntrance({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ade Flutterwave payment',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      debugShowCheckedModeBanner: false,
      home: const AdeFlutterExample(),
    );
  }
}
