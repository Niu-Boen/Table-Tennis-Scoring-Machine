import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';
import 'match_setup_screen.dart';
import 'score_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Table Tennis Scorekeeper'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HistoryScreen()),
                );
              },
            ),
          ],
        ),
        body: Consumer<MatchProvider>(
          builder: (context, provider, child) {
            return TabBarView(
              children: [
                // Active Matches Tab
                _buildMatchList(provider.activeMatches, isActive: true),
                // Completed Matches Tab
                _buildMatchList(provider.completedMatches, isActive: false),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MatchSetupScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildMatchList(List<Match> matches, {required bool isActive}) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_tennis, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active matches' : 'No completed matches',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        final avatarColor = match.isCompleted
            ? (match.matchWinner?.color ?? Colors.grey)
            : match.team1.color;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: avatarColor,
              child: Text(match.team1.name[0]),
            ),
            title: Text('${match.team1.name} vs ${match.team2.name}'),
            subtitle: match.isCompleted
                ? Text(
                    'Champion: ${match.matchWinner?.name} · ${match.startTime.toLocal().toString().split('.')[0]}',
                  )
                : Text(
                    'Game ${match.currentGameNumber + 1}/${match.totalGames} · ${match.pointsPerGame} pts',
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${match.team1GameWins.length} : ${match.team2GameWins.length}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScoreScreen(match: match),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
