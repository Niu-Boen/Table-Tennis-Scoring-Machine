import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
      ),
      body: Consumer<MatchProvider>(
        builder: (context, provider, child) {
          if (provider.completedMatches.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No matches yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.completedMatches.length,
            itemBuilder: (context, index) {
              final match = provider.completedMatches[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: match.matchWinner?.color ?? Colors.grey,
                    child: const Text('🏆'),
                  ),
                  title: Text('${match.team1.name} vs ${match.team2.name}'),
                  subtitle: Text(
                    '${match.startTime.toLocal().toString().split('.')[0]} · Champion: ${match.matchWinner?.name}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Match Score', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                '${match.team1GameWins.length} : ${match.team2GameWins.length}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Total Games', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('${match.totalGames}', style: const TextStyle(fontSize: 20)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ...match.games.asMap().entries.map((entry) {
                      int gameNum = entry.key + 1;
                      var game = entry.value;
                      return ListTile(
                        title: Text('Game $gameNum'),
                        trailing: Text(
                          '${game.team1Score} : ${game.team2Score}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}