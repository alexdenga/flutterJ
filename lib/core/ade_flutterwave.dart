// ignore_for_file: prefer_collection_literals, avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class AdeFlutterWavePay extends StatefulWidget {
  final data;
  AdeFlutterWavePay(this.data);

  @override
  _AdeFlutterWavePayState createState() => _AdeFlutterWavePayState(this.data);
}

class _AdeFlutterWavePayState extends State<AdeFlutterWavePay> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  _AdeFlutterWavePayState(this.data);
  String filepath = "files/flutterwave.html";
  late WebViewController _webViewController;
  dynamic data;
  bool isGeneratingCode = true;
  bool cango = false;
  dynamic result = null;

  loadfunction() {
    Timer(const Duration(seconds: 5), () {
      _webViewController.evaluateJavascript(
          'makePayment("${data["tx_ref"]}", "${data["amount"]}", "${data["email"]}", "${data["title"]}", "${data["name"]}", "${data["currency"]}", "${data["icon"]}", "${data["public_key"]}", "${data["phone"]}")');
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
        key: _scaffoldKey,
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.refresh_sharp),
          onPressed: () {
            _webViewController.evaluateJavascript(
                'makePayment("${data["tx_ref"]}", "${data["amount"]}", "${data["email"]}", "${data["title"]}", "${data["name"]}", "${data["currency"]}", "${data["icon"]}", "${data["public_key"]}", "${data["phone"]}")');
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
                _scaffoldKey.currentState?.showSnackBar(const SnackBar(
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
                    _scaffoldKey.currentState?.showSnackBar(const SnackBar(
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
                        _scaffoldKey.currentState?.showSnackBar(const SnackBar(
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
                        _scaffoldKey.currentState?.showSnackBar(const SnackBar(
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
                      _scaffoldKey.currentState?.showSnackBar(const SnackBar(
                        content: Text(
                          "Something went wrong!",
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 5),
                      ));
                    }
                  } else {
                    _scaffoldKey.currentState?.showSnackBar(const SnackBar(
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
            _loadhtmlFromAssets();
          },
        ),
      ),
    );
  }

  _loadhtmlFromAssets() async {
    String filehtml = await rootBundle.loadString(filepath);
    _webViewController.loadUrl(Uri.dataFromString(filehtml,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
    //flutter snackbars
    _scaffoldKey.currentState?.showSnackBar(const SnackBar(
      content: Text("Loading..."),
      duration: Duration(seconds: 5),
    ));
    //delay for 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      loadfunction();
    });
  }
}
