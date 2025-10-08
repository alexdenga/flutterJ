// ignore_for_file: prefer_collection_literals, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, no_logic_in_create_state, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class FlutterWavePay extends StatefulWidget {
  final Map<String, dynamic> data;

  const FlutterWavePay(this.data, {super.key});

  @override
  _FlutterWavePayState createState() => _FlutterWavePayState();
}

class _FlutterWavePayState extends State<FlutterWavePay> {
  late final WebViewController _webViewController;
  bool isGeneratingCode = true;
  dynamic result;

  @override
  void initState() {
    super.initState();
    // Configure WebViewController (webview_flutter 4.x)
    const PlatformWebViewControllerCreationParams params =
        PlatformWebViewControllerCreationParams();

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) {
          if (!mounted) return;
          _showSnack("Payment page ready...");
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) _runPaymentScript();
          });
        },
      ),
    );

    controller.addJavaScriptChannel(
      'messageHandler',
      onMessageReceived: (JavaScriptMessage message) async {
        try {
          final response = jsonDecode(message.message);
          if (response["status"] == "cancelled") {
            _showSnack("Transaction cancelled", color: Colors.red);
          } else {
            _showSnack("Verifying transaction...");
            setState(() => isGeneratingCode = true);
            await _verifyTransaction("${response["transaction_id"]}");
          }
        } catch (e) {
          print("Decode error: $e");
          _showSnack("Invalid response from payment", color: Colors.red);
        }
      },
    );

    _webViewController = controller;
    _loadHtmlToWebView();
  }

  /// Show short snack messages
  void _showSnack(String text, {Color color = Colors.orange, int seconds = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: Duration(seconds: seconds),
      ),
    );
  }

  /// Verify transaction from Flutterwave API
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
        _showSnack("Transaction verified!", color: Colors.green, seconds: 2);
        result = body;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, body);
        });
      } else {
        _showSnack("Verification failed!", color: Colors.red);
      }
    } catch (e) {
      print("Verify error: $e");
      _showSnack("Error verifying transaction", color: Colors.red);
    } finally {
      if (mounted) setState(() => isGeneratingCode = false);
    }
  }

  /// HTML page for Flutterwave checkout
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
                description: "Payment for your order",
                logo: icon
              }
            });
          }
        </script>
      </body>
    </html>
  ''';

  /// Load HTML and set up navigation listener
  Future<void> _loadHtmlToWebView() async {
    final htmlUri = Uri.dataFromString(
      _htmlContent(),
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8'),
    );

    await _webViewController.loadRequest(htmlUri);
  }

  /// Runs the Flutterwave JS function once HTML is loaded
  Future<void> _runPaymentScript() async {
    try {
      await _webViewController.runJavaScriptReturningResult(
        'makePayment("${widget.data["tx_ref"]}", "${widget.data["amount"]}", "${widget.data["email"]}", "${widget.data["title"]}", "${widget.data["name"]}", "${widget.data["currency"]}", "${widget.data["icon"]}", "${widget.data["public_key"]}", "${widget.data["phone"]}", "${widget.data["payment_options"]}")',
      );
      if (mounted) setState(() => isGeneratingCode = false);
    } catch (e) {
      print("Error running JS: $e");
      _showSnack("Failed to start payment", color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isGeneratingCode,
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
          onPressed: _runPaymentScript,
          child: const Icon(Icons.refresh),
        ),
        body: WebViewWidget(controller: _webViewController),
      ),
    );
  }
}
