import 'package:flutter/material.dart';
import 'package:flutter_testdrive/src/github_summary.dart';
import 'package:github/github.dart';
import 'package:window_to_front/window_to_front.dart';

import 'github/login.dart';
import 'github/client_credentials.dart';

void main() {
  runApp(const GithubLoginApp());
}

class GithubLoginApp extends StatelessWidget {
  const GithubLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "GitHub Client",

      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const ClientHomePage(title: 'GitHub Client'),
    );
  }
}

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return GithubLoginWidget(
        builder: (context, httpClient) {
          WindowToFront.activate();
          return FutureBuilder<CurrentUser>(
             future: viewerDetail(httpClient.credentials.accessToken),
             builder: (context, snapshot) {
               return Scaffold(
                 appBar: AppBar(
                   title: Text(title),
                   elevation: 2,
                 ),
                 body: GitHubSummary(
                   gitHub: _getGitHub(httpClient.credentials.accessToken),
                 )
               );
             });
        },

        githubClientId: githubClientId,
        githubClientSecret: githubClientSecret,
        githubScopes: githubScopes
    );
  }
}

GitHub _getGitHub(String accessToken) {
  return GitHub(auth: Authentication.withToken(accessToken));
}

Future<CurrentUser> viewerDetail(String accessToken) async {
  final gitHub = GitHub(auth: Authentication.withToken(accessToken));
  return gitHub.users.getCurrentUser();
}