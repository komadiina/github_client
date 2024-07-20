import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';

final _authEndpoint = Uri.parse("https://github.com/login/oauth/authorize");
final _tokenEndpoint = Uri.parse("https://github.com/login/oauth/access_token");

class GithubLoginWidget extends StatefulWidget {
  const GithubLoginWidget({
    required this.builder,
    required this.githubClientId,
    required this.githubClientSecret,
    required this.githubScopes,
    super.key
  });

  final AuthenticatedBuilder builder;
  final String githubClientId;
  final String githubClientSecret;
  final List<String> githubScopes;

  @override
  State<StatefulWidget> createState() => _GithubLoginState();
}

typedef AuthenticatedBuilder = Widget Function(
    BuildContext context, oauth2.Client client
    );

class _GithubLoginState extends State<GithubLoginWidget> {
  HttpServer? _redirectServer;
  oauth2.Client? _client;

  @override
  Widget build(BuildContext context) {
    final client = _client;

    if (client != null) {
      return widget.builder(context, client);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("GitHub Login"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await _redirectServer?.close();
            _redirectServer = await HttpServer.bind('localhost', 0);
            var authHttpClient = await _getOauth2Client(
              Uri.parse('http://localhost:${_redirectServer!.port}/auth')
            );

            setState(() {
              _client = authHttpClient;
            });
          },

          child: const Text("Login to GitHub"),
        ),
      ),
    );
  }

  Future<oauth2.Client> _getOauth2Client(Uri redirectUrl) async {
    if (widget.githubClientId.isEmpty || widget.githubClientSecret.isEmpty) {
      throw const GithubLoginException(
        'githubClientId and githubClientSecret must not be empty.'
      );
    }

    var grant = oauth2.AuthorizationCodeGrant(
        widget.githubClientId,
        _authEndpoint,
        _tokenEndpoint,
        secret: widget.githubClientSecret,
        httpClient: _JsonAcceptingClient()
    );

    var authUrl = grant.getAuthorizationUrl(
        redirectUrl,
        scopes: widget.githubScopes
    );

    await _redirect(authUrl);
    var responseQueryParams = await _listen();
    var client = await grant.handleAuthorizationResponse(responseQueryParams);
    return client;
  }

  Future<void> _redirect(Uri authUrl) async {
    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl);
    } else {
      throw const GithubLoginException('Failed to redirect.');
    }
  }

  Future<Map<String, String>> _listen() async {
    var req = await _redirectServer!.first;
    var params = req.uri.queryParameters;

    req.response.statusCode = 200;
    req.response.headers.set('content-type', 'text/plain');
    req.response.writeln('Authenticated! You may now close this tab.');

    await req.response.close();
    await _redirectServer!.close();

    _redirectServer = null;
    return params;
  }
}

class _JsonAcceptingClient extends http.BaseClient {
  final _httpClient = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return _httpClient.send(request);
  }
}

class GithubLoginException implements Exception {
  const GithubLoginException(this.message);
  final String message;

  @override
  String toString() => message;
}