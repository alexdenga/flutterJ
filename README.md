# ade_flutterwave_working_version

A simple Flutterwave payment that works.

## Youtube Preview

[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/uOvP3rwnVwQ/0.jpg)](https://www.youtube.com/watch?v=uOvP3rwnVwQ)

[![Pub](https://img.shields.io/pub/v/flutter_slidable.svg)](https://pub.dev/packages/ade_flutterwave_working_version)

![Overview](https://github.com/adeleyeayodeji/ade_flutterwave_working_version/blob/main/screenshot1.png)

## Features

- Webview interface
- Simple to use.
- No stress added.
- Many more . . .

## Getting started

In the `pubspec.yaml` of your flutter project, add the following dependency:

```yaml
dependencies:
  ...
  ade_flutterwave_working_version: ^0.0.1+3
```

In your library add the following import:

```dart
import 'package:ade_flutterwave_working_version/core/ade_flutterwave.dart';
```

For help getting started with Flutter, view the online [documentation](https://flutter.io/).

### Constructors

You can create a `AdeFlutterWavePay`:

```dart
 var data = {
        'amount': _amountController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'name': _fullNameController.text,
        'title': 'Flutterwave payment',
        'currency': "NGN",
        'tx_ref':
            "AdeFlutterwave-${DateTime.now().millisecondsSinceEpoch}",
        'icon':
            "https://www.aqskill.com/wp-content/uploads/2020/05/logo-pde.png",
        'public_key':
            "FLWPUBK_TEST-your-key",
        'sk_key':
            'FLWSECK_TEST-your-key'
    };

    Navigator.push(
        context,
        MaterialPageRoute(
        builder: (context) => AdeFlutterWavePay(data),
        ),
    ).then((response) {
        //response is the response from the payment
        print(response);
    });
```

### Full Example

```Dart
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:ade_flutterwave_working_version/core/ade_flutterwave.dart';

class AdeFlutterExample extends StatefulWidget {
  const AdeFlutterExample({Key? key}) : super(key: key);

  @override
  State<AdeFlutterExample> createState() => _AdeFlutterExampleState();
}

class _AdeFlutterExampleState extends State<AdeFlutterExample> {
  //controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Ade Flutterwave payment'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Form(
            child: Column(
              children: [
                //title
                const Text(
                  'Flutterwave payment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                  ),
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    var data = {
                      'amount': _amountController.text,
                      'email': _emailController.text,
                      'phone': _phoneController.text,
                      'name': _fullNameController.text,
                      'title': 'Flutterwave payment',
                      'currency': "NGN",
                      'tx_ref':
                          "AdeFlutterwave-${DateTime.now().millisecondsSinceEpoch}",
                      'icon':
                          "https://www.aqskill.com/wp-content/uploads/2020/05/logo-pde.png",
                      'public_key':
                          "FLWPUBK_TEST-e0787ab2e5b0b6fcb3d32ce465ad44d0-X",
                      'sk_key':
                          'FLWSECK_TEST-af1af523da3f141f894a26be4b071230-X'
                    };

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdeFlutterWavePay(data),
                      ),
                    ).then((response) {
                      //response is the response from the payment
                      print(response);
                    });
                  },
                  child: const Text('Pay'),
                ),
              ],
            ),
          ),
        ));
  }
}
```
