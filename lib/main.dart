import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'dart:io' show Platform;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const FlutterAppAuth appAuth = FlutterAppAuth();
String _clientId = 'fdcadc93-770e-4b9a-92d8-383c56f2ee38';
String _redirectUrl = 'msalfdcadc93-770e-4b9a-92d8-383c56f2ee38://auth';
String _discoveryURL = 'https://tecnivacalendarapp.b2clogin.com/TecnivaCalendarApp.onmicrosoft.com/v2.0/.well-known/openid-configuration?p=B2C_1_singUpSignInFlutter';
String _authorizeUrl = 'https://TecnivaCalendarApp.b2clogin.com/TecnivaCalendarApp.onmicrosoft.com/B2C_1_singUpSignInFlutter/oauth2/v2.0/authorize';
String _tokenUrl = 'https://TecnivaCalendarApp.b2clogin.com/TecnivaCalendarApp.onmicrosoft.com/B2C_1_singUpSignInFlutter/oauth2/v2.0/token';
String _idToken = '';
String _codeVerifier = '';
String _authorizationCode = '';
String _refreshToken  = '';
String _accessToken = '';
String _accessTokenExpiration = '';
String _firstName = "";
String _lastName = "";
String _displayName = "";
String _email = "";
Map<String, dynamic> _jwt = {};
List<String> _scopes = ['openid'];


class _MyHomePageState extends State<MyHomePage> {

  Future<void> _logIn() async {
    try {
      final AuthorizationTokenResponse? result = await appAuth
          .authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: _authorizeUrl, 
            tokenEndpoint: _tokenUrl
            ),
          scopes: _scopes,
        ),
      );

      if (result != null) {
        _processAuthTokenResponse(result);
      }
      
    } catch (e) {
      print(e.toString());
    }
  }

   void _processAuthTokenResponse(AuthorizationTokenResponse response) {
    setState(() {
      _accessToken = response.accessToken!;
      _refreshToken = response.refreshToken!;
      _accessTokenExpiration = response.accessTokenExpirationDateTime!.toIso8601String();
      _idToken = response.idToken!;
      //get individual claims from jwt token
      _jwt = parseJwt(response.idToken!);
      _firstName = _jwt['given_name'].toString();
      _lastName = _jwt['family_name'].toString();
      _displayName = _jwt['name'].toString();
      _email = _jwt['emails'][0];
    });
  }

  Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('invalid token');
    }
    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('invalid payload');
    }
    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }
    return utf8.decode(base64Url.decode(output));
  }

 Future<void> _logOut() async {
  try {
    Map<String, String> additionalParameters;
    if (Platform.isAndroid) {
      additionalParameters = {
        "id_token_hint": _idToken,
        "post_logout_redirect_uri": _redirectUrl,
      };
    } else if (Platform.isIOS) {
      additionalParameters = {
        "id_token_hint": _idToken,
        "post_logout_redirect_uri": _redirectUrl,
        'p': 'B2C_1_susi',
      };
    } else {
      additionalParameters = {}; // Inicialización predeterminada para otras plataformas
    }
    await appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _clientId,
        _redirectUrl,
        promptValues: ['login'],
        discoveryUrl: _discoveryURL,
        additionalParameters: additionalParameters,
        scopes: _scopes,
      ),
    );
  } catch (e) {
    print(e);
  }
  setState(() {
    _jwt = {};
  });
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: const Text('Aplicacion de Flutter con Azure B2C'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: (_jwt.isNotEmpty)
            ? <Widget>[
                Text('Display Name: $_displayName'),
                const Text(' '),
                Text('Name: $_firstName $_lastName'),
                const Text(' '),
                Text('Email: $_email'),
                const Text(' '),
                ElevatedButton(
                  onPressed: _logOut,
                  child:const Text('Logout'),
                ),
              ]
            : <Widget>[
              const Text('Please press + sign to log in'),
              ElevatedButton(
                  onPressed: _logOut,
                  child:const Text('Logout'),
              ),
            ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _logIn,
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    ),
  );
}

}