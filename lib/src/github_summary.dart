import 'package:flutter/material.dart';
import 'package:fluttericon/octicons_icons.dart';
import 'package:github/github.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GitHubSummary extends StatefulWidget {
  const GitHubSummary(
  {
    required this.gitHub,
    super.key
  });

  final GitHub gitHub;

  @override
  State<StatefulWidget> createState() => _GitHubSummaryState();
}

class _GitHubSummaryState extends State<GitHubSummary> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (idx) {
            setState(() {
              _selectedIndex = idx;
            });
          },
          labelType: NavigationRailLabelType.selected,
          destinations: const [
            NavigationRailDestination(
                icon: Icon(Octicons.repo),
                label: Text("Repositories"),
            ),
            NavigationRailDestination(
                icon: Icon(Octicons.issue_opened),
                label: Text("Issues"),
            ),
            NavigationRailDestination(
                icon: Icon(Octicons.git_pull_request),
                label: Text("Pull Requests"),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1,),

        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              RepositoriesList(gitHub: widget.gitHub),
              IssuesList(gitHub: widget.gitHub),
              PullRequestsList(gitHub: widget.gitHub),
            ],
          )
        )
      ],
    );
  }
}

class RepositoriesList extends StatefulWidget {
  const RepositoriesList({required this.gitHub, super.key});
  final GitHub gitHub;

  @override
  State<StatefulWidget> createState() {
    return _RepositoriesListState();
  }
}

class _RepositoriesListState extends State<RepositoriesList> {
  @override
  void initState() {
    super.initState();
    _repositories = widget.gitHub.repositories.listRepositories().toList();
  }

  late Future<List<Repository>> _repositories;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Repository>>(
      future: _repositories,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("${snapshot.error}"));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var repositories = snapshot.data;

        return ListView.builder(
          primary: false,
          itemBuilder: (context, index) {
            var repo = repositories[index];
            return ListTile(
              title: Text("${repo.owner?.login ?? ''}/${repo.name}"),
              subtitle: Text(repo.description),
              onTap: () => _launchURL(this, repo.htmlUrl),
            );
          },
          itemCount: repositories!.length,
        );
      },
    );
  }
}

class IssuesList extends StatefulWidget {
   const IssuesList({required this.gitHub, super.key});
   final GitHub gitHub;

   @override
   State<IssuesList> createState() => _IssuesListState();
}

class _IssuesListState extends State<IssuesList> {
  @override
  void initState() {
    super.initState();
    _assignedIssues = widget.gitHub.issues.listByUser().toList();
  }

  late Future<List<Issue>> _assignedIssues;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _assignedIssues,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var assignedIssues = snapshot.data;

          return ListView.builder(
            primary: false,
            itemBuilder: (context, index) {
              var assignedIssue = assignedIssues.elementAt(index);
              return ListTile(
                title: Text(assignedIssue.title),
                subtitle: Text(
                    "(#${assignedIssue.number}) "
                    "Opened by ${assignedIssue.user?.login} ?? ''"
                ),
                onTap: () => _launchURL(this, assignedIssue.htmlUrl),
              );
            },
            itemCount: assignedIssues!.length,
          );
        }
    );
  }
}

class PullRequestsList extends StatefulWidget {
  const PullRequestsList({required this.gitHub, super.key});
  final GitHub gitHub;

  @override
  State<StatefulWidget> createState() => _PullRequestsListState();
}

class _PullRequestsListState extends State<PullRequestsList> {
  @override
  void initState() {
    super.initState();
    _pullRequests = widget.gitHub.pullRequests
      .list(RepositorySlug("flutter", "flutter"))
      .toList();
  }

  late Future<List<PullRequest>> _pullRequests;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return FutureBuilder(
        future: _pullRequests,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var pullRequests = snapshot.data;

          return ListView.builder(
            primary: false,
            itemBuilder: (context, index) {
              var pullRequest = pullRequests.elementAt(index);
              return ListTile(
                title: Text(pullRequest.title ?? ''),
                subtitle: Text(
                    "(#${pullRequest.number}) "
                        "Opened by ${pullRequest.user!.login}"
                ),
                onTap: () => _launchURL(this, pullRequest.htmlUrl ?? ''),
              );
            },
            itemCount: pullRequests!.length,
          );
        },
    );
  }
}

Future<void> _launchURL(State state, String url) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url);
  } else {
    if (state.mounted) {
      return showDialog(
          context: state.context,
          builder: (context) => AlertDialog(
            title: const Text("Navigation error."),
            content: Text("Could not launch $url"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close"),
              )
            ],
          ),
      );
    }
  }
}