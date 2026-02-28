import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:collection';

import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request necessary permissions for WebRTC (Mic/Camera) in WebView
  await Permission.camera.request();
  await Permission.microphone.request();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xbox Cloud Gaming',
      theme: ThemeData.dark(),
      home: const XCloudWebView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class XCloudWebView extends StatefulWidget {
  const XCloudWebView({super.key});

  @override
  State<XCloudWebView> createState() => _XCloudWebViewState();
}

class _XCloudWebViewState extends State<XCloudWebView> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  String? betterXCloudScript;

  late final InAppWebViewSettings settings;

  @override
  void initState() {
    super.initState();
    settings = InAppWebViewSettings(
      // Essential Xbox Cloud Gaming & Userscript requirements
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone; fullscreen; display-capture; autoplay",
      iframeAllowFullscreen: true,
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      domStorageEnabled: true,
      supportMultipleWindows: true,
      supportZoom: false,
      isElementFullscreenEnabled: true,
      transparentBackground: true,
      
      // Multi-touch for virtual controller
      disableContextMenu: true,

      // iOS specific
      isInspectable: true,
      allowsAirPlayForMediaPlayback: true,
      allowsPictureInPictureMediaPlayback: true,
      selectionGranularity: SelectionGranularity.CHARACTER,
      ignoresViewportScaleLimits: true,
      limitsNavigationsToAppBoundDomains: false,
      alwaysBounceVertical: false,
      alwaysBounceHorizontal: false,
    );

    _loadScript();
  }

  Future<void> _loadScript() async {
    try {
      final script = await rootBundle.loadString('assets/better_xcloud.js');
      setState(() {
        betterXCloudScript = script;
      });
    } catch (e) {
      debugPrint("Failed to load Better xCloud script: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: betterXCloudScript == null 
            ? const Center(child: CircularProgressIndicator())
            : InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(url: WebUri("https://www.xbox.com/play")),
                initialSettings: settings,
                initialUserScripts: UnmodifiableListView<UserScript>([
                  UserScript(
                    source: betterXCloudScript!,
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                    forMainFrameOnly: true,
                  )
                ]),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  debugPrint("Started loading: $url");
                },
                onLoadStop: (controller, url) async {
                  debugPrint("Finished loading: $url");
                },
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint("Console: ${consoleMessage.message}");
                },
              ),
      ),
    );
  }
}
