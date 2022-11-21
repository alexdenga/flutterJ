// ignore_for_file: prefer_collection_literals, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, no_logic_in_create_state, prefer_typing_uninitialized_variables, avoid_init_to_null

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class AdeFlutterWavePay extends StatefulWidget {
  final data;
  const AdeFlutterWavePay(this.data, {super.key});

  @override
  _AdeFlutterWavePayState createState() => _AdeFlutterWavePayState(data);
}

class _AdeFlutterWavePayState extends State<AdeFlutterWavePay> {
  _AdeFlutterWavePayState(this.data);
  String filepath = "files/flutterwave.html";
  late WebViewController _webViewController;
  dynamic data;
  bool isGeneratingCode = true;
  bool cango = false;
  dynamic result = null;

  loadfunction() {
    Timer(const Duration(seconds: 5), () {
      _webViewController.runJavascriptReturningResult(
          'makePayment("${data["tx_ref"]}", "${data["amount"]}", "${data["email"]}", "${data["title"]}", "${data["name"]}", "${data["currency"]}", "${data["icon"]}", "${data["public_key"]}", "${data["phone"]}", "${data["payment_options"]}")');
      setState(() {
        isGeneratingCode = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isGeneratingCode,
      opacity: 1,
      color: Colors.black54,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.refresh_sharp),
          onPressed: () {
            _webViewController.runJavascriptReturningResult(
                'makePayment("${data["tx_ref"]}", "${data["amount"]}", "${data["email"]}", "${data["title"]}", "${data["name"]}", "${data["currency"]}", "${data["icon"]}", "${data["public_key"]}", "${data["phone"]}", "${data["payment_options"]}")');
          },
        ),
        appBar: AppBar(
          title: Text(data["title"]),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              try {
                Future.delayed(const Duration(seconds: 2), () {
                  // WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pop();
                  // });
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                    "Something went wrong!",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ));
              }
            },
          ),
        ),
        body: WebView(
          initialUrl: '',
          javascriptMode: JavascriptMode.unrestricted,
          javascriptChannels: Set.from([
            JavascriptChannel(
                name: "messageHandler",
                onMessageReceived: (message) async {
                  var d = message.message;
                  _webViewController.goBack();
                  _webViewController.clearCache();
                  var response = jsonDecode(d);
                  if (response["status"] != "cancelled") {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Verifying transactions, please wait.."),
                      duration: Duration(seconds: 5),
                    ));
                    // print(response);
                    setState(() {
                      isGeneratingCode = true;
                    });
                    try {
                      var response2 = await http.get(
                          Uri.parse(
                              "https://api.flutterwave.com/v3/transactions/${response["transaction_id"]}/verify"),
                          headers: {
                            "Authorization": "Bearer ${data["sk_key"]}",
                            "Content-Type": "application/json",
                            "Accept": "application/json"
                          });
                      var d2 = jsonDecode(response2.body);
                      _webViewController.goBack();
                      _webViewController.clearCache();
                      // print(d2);
                      if (d2["status"] == "success") {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text(
                            "Transaction verified!, redirecting...",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 10),
                        ));
                        setState(() {
                          result = d2;
                        });
                        Future.delayed(const Duration(seconds: 10), () {
                          if (mounted) {
                            setState(() {
                              isGeneratingCode = false;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              //Moving forward
                              Navigator.pop(context, d2);
                            });
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text(
                            "Transaction failed!",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 5),
                        ));
                        setState(() {
                          isGeneratingCode = false;
                        });
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                          "Something went wrong!",
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 5),
                      ));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                        "Transaction cancelled!",
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                    ));
                  }
                })
          ]),
          onWebViewCreated: (WebViewController webViewController) async {
            _webViewController = webViewController;
            _loadhtmlFromString();
          },
        ),
      ),
    );
  }

  // _loadhtmlFromAssets() async {
  //   String filehtml = await rootBundle.loadString(filepath);
  //   _webViewController.loadUrl(Uri.dataFromString(filehtml,
  //           mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
  //       .toString());
  //   //flutter snackbars
  //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //     content: Text("Loading..."),
  //     duration: Duration(seconds: 5),
  //   ));
  //   //delay for 5 seconds
  //   Future.delayed(const Duration(seconds: 5), () {
  //     loadfunction();
  //   });
  // }

  htmlString() {
    return '''
    <!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Ade Flutterwave</title>
  </head>
  <body>
    <h2 style="text-align:center;">Making payment, please wait</h2>
    <script src="https://checkout.flutterwave.com/v3.js"></script>
    <script>
      function test(params) {
        let d = document.querySelector("h2");
        d.innerHTML = 'Making payment for'+ params + ', <br>please wait...';
      }

      function sendBack(data) {
        messageHandler.postMessage(data);
      }

      function closeWebView(){
        //close the tab
        window.stop();
        var data = {
            "status" : "cancelled",
        };
        //stringify
        var dataString = JSON.stringify(data);
        messageHandler.postMessage(dataString);
      }

      function makePayment(tx_ref, amount, email, title, name, currency, icon, public_key, phone, payment_options) {
        test(title);

        FlutterwaveCheckout({
          public_key: public_key,
          tx_ref: tx_ref,
          amount: amount,
          currency: currency,
          payment_options: payment_options,
          // specified redirect URL
          //   redirect_url:
          //     "https://callbacks.piedpiper.com/flutterwave.aspx?ismobile=34",
          customer: {
            email: email,
            phone_number: phone,
            name: name
          },
          callback: function (data) {
            console.log(data);
            let dd = JSON.stringify(data);
            // console.log(dd);
             window.stop();
            sendBack(dd);
          },
          onclose: function () {
            // close modal
            closeWebView();
          },
          customizations: {
            title: title,
            description: "Payment for items in cart",
            logo: icon
          }
        });
      }
    </script>
  </body>
</html>
    ''';
  }

  _loadhtmlFromString() async {
    _webViewController.loadUrl(Uri.dataFromString(htmlString(),
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());

    //flutter snackbars
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Loading..."),
      duration: Duration(seconds: 5),
    ));
    //delay for 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      loadfunction();
    });
  }
}
