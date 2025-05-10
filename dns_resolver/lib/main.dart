import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'pages/login.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  const keyApplicationId = 'LoZzWyJU1wnQ9VR7V8OCnxLOh9qgfuSagdcLyD20';
  const keyClientKey = 'RcreWrtdBUGJhzMnCs1eNN6RUJKhZDFVuAHXmgBm';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(
    keyApplicationId,
    keyParseServerUrl,
    clientKey: keyClientKey,
    autoSendSessionId: true,
    debug: true,
  );
  runApp( MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Doc',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}
