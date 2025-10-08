// ignore_for_file: prefer_collection_literals, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, no_logic_in_create_state, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class AdeFlutterWavePay extends StatefulWidget {
  final Map<String, dynamic> data;

  const AdeFlutterWavePay(this.data, {super.key});

  @override
  _AdeFlutterWavePayState createState() => _AdeFlutterWavePayState();
}

class _AdeFlutterWavePayState extends State<AdeFlutterWavePay> {
  late WebViewController _webViewController;
  bool isGeneratingCode = true;
  dynamic result;

  @override
  void initState() {
    super.initState();
    // Optional for Android 12+ (uncomment if WebView fails to render)
    // WebView.platform = SurfaceAndroidWebView();
  }

  void _loadPaymentScript() {
    if (mounted) {
      Timer(const Duration(seconds: 3), () async {
        if (!mounted) return;
        try {
          await _webViewController.runJavascriptReturningResult(
            'makePayment("${widget.data["tx_ref"]}", "${widget.data["amount"]}", "${widget.data["email"]}", "${widget.data["title"]}", "${widget.data["name"]}", "${widget.data["currency"]}", "${widget.data["icon"]}", "${widget.data["public_key"]}", "${widget.data["phone"]}", "${widget.data["payment_options"]}")',
          );
          if (mounted) {
            setState(() => isGeneratingCode = false);
          }
        } catch (e) {
          print("Error running JS: $e");
        }
      });
    }
  }

  void _showSnack(String text, {Color color = Colors.orange, int seconds = 4}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: Duration(seconds: seconds),
      ),
    );
  }

  Future<void> _verifyTransaction(String id) async {
    try {
      final response = await http.get(
        Uri.parse("https://api.flutterwave.com/v3/transactions/$id/verify"),
        headers: {
          "Authorization": "Bearer ${widget.data["sk_key"]}",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      final body = jsonDecode(response.body);

      if (body["status"] == "success") {
        _showSnack("Transaction verified! Redirecting...",
            color: Colors.green, seconds: 3);
        result = body;

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.pop(context, body);
        });
      } else {
        _showSnack("Transaction failed!", color: Colors.red);
      }
    } catch (e) {
      _showSnack("Error verifying transaction!", color: Colors.red);
      print("Verify error: $e");
    } finally {
      if (mounted) setState(() => isGeneratingCode = false);
    }
  }

  String _htmlContent() => '''
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Ade Flutterwave</title>
      </head>
      <body>
        <h2 style="text-align:center;">Preparing payment...</h2>
        <script src="https://checkout.flutterwave.com/v3.js"></script>
        <script>
          function sendBack(data) {
            messageHandler.postMessage(data);
          }

          function closeWebView() {
            var data = {"status": "cancelled"};
            messageHandler.postMessage(JSON.stringify(data));
          }

          function makePayment(tx_ref, amount, email, title, name, currency, icon, public_key, phone, payment_options) {
            document.querySelector("h2").innerHTML = "Initializing payment for " + title + "...";

            FlutterwaveCheckout({
              public_key: public_key,
              tx_ref: tx_ref,
              amount: amount,
              currency: currency,
              payment_options: payment_options,
              customer: {
                email: email,
                phone_number: phone,
                name: name
              },
              callback: function (data) {
                sendBack(JSON.stringify(data));
              },
              onclose: function () {
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

  Future<void> _loadHtmlToWebView() async {
    final html = Uri.dataFromString(
      _htmlContent(),
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8'),
    ).toString();

    await _webViewController.loadUrl(html);
    _showSnack("Loading payment page...");
    _loadPaymentScript();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isGeneratingCode,
      opacity: 0.7,
      color: Colors.black54,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.data["title"] ?? "Flutterwave Payment"),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.refresh),
          onPressed: () => _loadPaymentScript(),
        ),
        body: WebView(
          initialUrl: '',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (controller) async {
            _webViewController = controller;
            await _loadHtmlToWebView();
          },
          javascriptChannels: {
            JavascriptChannel(
              name: "messageHandler",
              onMessageReceived: (message) async {
                final msg = message.message;
                try {
                  final response = jsonDecode(msg);
                  if (response["status"] == "cancelled") {
                    _showSnack("Transaction cancelled.", color: Colors.red);
                  } else {
                    _showSnack("Verifying transaction, please wait...");
                    setState(() => isGeneratingCode = true);
                    await _verifyTransaction("${response["transaction_id"]}");
                  }
                } catch (e) {
                  print("Message decode error: $e");
                  _showSnack("Invalid response from payment",
                      color: Colors.red);
                }
              },
            ),
          },
        ),
      ),
    );
  }
}
