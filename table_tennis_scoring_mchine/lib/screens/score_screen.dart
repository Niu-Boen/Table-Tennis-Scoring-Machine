import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';

class ScoreScreen extends StatelessWidget {
  final Match match;

  const ScoreScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: match,
      child: Consumer<Match>(
        builder: (context, match, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('${match.team1.name} vs ${match.team2.name}'),
              backgroundColor: match.isCompleted ? Colors.green : null,
              actions: [
                if (match.isCompleted)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        'Champion: ${match.matchWinner?.name}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.grey[200],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: match.team1.color,
                            child: Text(
                              match.team1.name[0],
                              style: const TextStyle(fontSize: 24, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            match.team1.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '${match.team1GameWins.length} : ${match.team2GameWins.length}',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: match.team2.color,
                            child: Text(
                              match.team2.name[0],
                              style: const TextStyle(fontSize: 24, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            match.team2.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Game ${match.currentGameNumber + 1}/${match.totalGames}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (!match.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: match.currentServer == 1
                                ? match.team1.color.withValues(alpha: 0.2)
                                : match.team2.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Serve: ${match.currentServer == 1 ? match.team1.name : match.team2.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (match.isTieBreak)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Deuce', style: TextStyle(color: Colors.orange)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: match.team1.color.withValues(alpha: 0.1),
                          child: Center(
                            child: Text(
                              '${match.currentGame.team1Score}',
                              style: TextStyle(
                                fontSize: 120,
                                fontWeight: FontWeight.bold,
                                color: match.team1.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 2,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Container(
                          color: match.team2.color.withValues(alpha: 0.1),
                          child: Center(
                            child: Text(
                              '${match.currentGame.team2Score}',
                              style: TextStyle(
                                fontSize: 120,
                                fontWeight: FontWeight.bold,
                                color: match.team2.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (match.needsInterval && !match.isCompleted)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.yellow[100],
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Interval - Switch sides',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                if (!match.isCompleted)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => match.addPoint(1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: match.team1.color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text('+1', style: TextStyle(fontSize: 32)),
                                Text(match.team1.name),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => match.addPoint(2),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: match.team2.color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text('+1', style: TextStyle(fontSize: 32)),
                                Text(match.team2.name),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!match.isCompleted)
                        OutlinedButton.icon(
                          onPressed: match.currentGame.pointHistory.isNotEmpty
                              ? () => match.undoLastPoint()
                              : null,
                          icon: const Icon(Icons.undo),
                          label: const Text('Undo'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      if (match.isCompleted)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          icon: const Icon(Icons.home),
                          label: const Text('Home'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}