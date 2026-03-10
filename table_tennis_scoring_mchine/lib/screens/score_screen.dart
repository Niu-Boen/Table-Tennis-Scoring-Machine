import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';

class ScoreScreen extends StatefulWidget {
  final Match match;

  const ScoreScreen({super.key, required this.match});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  @override
  void initState() {
    super.initState();
    // 如果发球方尚未决定且比赛未开始，显示选择发球方对话框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.match.firstServerDetermined &&
          widget.match.currentGameNumber == 0 &&
          !widget.match.isCompleted) {
        _showChooseServerDialog();
      }
    });
  }

  void _showChooseServerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose First Server'),
          content: const Text('Select which team will serve first:'),
          actions: [
            TextButton(
              onPressed: () {
                widget.match.setFirstServer(1);
                Navigator.of(context).pop();
                _showSuccessSnackbar('${widget.match.team1.name} serves first');
              },
              child: Text(widget.match.team1.name),
            ),
            TextButton(
              onPressed: () {
                widget.match.setFirstServer(2);
                Navigator.of(context).pop();
                _showSuccessSnackbar('${widget.match.team2.name} serves first');
              },
              child: Text(widget.match.team2.name),
            ),
          ],
        );
      },
    );
  }

  // 显示半透明绿色浮窗
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // 显示所有已结束局数的对话框
  void _showAllFinishedGamesDialog(BuildContext context, Match match) {
    final finishedGames = match.games.asMap().entries.where((entry) => entry.value.isCompleted).toList();
    if (finishedGames.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finished Games'),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: finishedGames.length,
            itemBuilder: (context, index) {
              final entry = finishedGames[index];
              final gameNum = entry.key + 1;
              final game = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: game.winner?.color ?? Colors.grey,
                    child: Text('$gameNum'),
                  ),
                  title: Text('Game $gameNum'),
                  subtitle: Text('Winner: ${game.winner?.name ?? 'Unknown'}'),
                  trailing: Text(
                    '${game.team1Score} : ${game.team2Score}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.match,
      child: Consumer<Match>(
        builder: (context, match, child) {
          // 当局结束且未确认时显示可调整分数的确认对话框
          if (match.isGameEndedPending) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showAdjustableGameEndDialog(context, match);
            });
          }

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
            body: OrientationBuilder(
              builder: (context, orientation) {
                double scoreFontSize = orientation == Orientation.portrait ? 120 : 100;
                return Column(
                  children: [
                    // 大比分显示
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: Colors.grey[200],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              CircleAvatar(
                                radius: orientation == Orientation.portrait ? 30 : 20,
                                backgroundColor: match.team1.color,
                                child: Text(
                                  match.team1.name[0],
                                  style: TextStyle(
                                    fontSize: orientation == Orientation.portrait ? 24 : 16,
                                    color: Colors.white,
                                  ),
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
                                radius: orientation == Orientation.portrait ? 30 : 20,
                                backgroundColor: match.team2.color,
                                child: Text(
                                  match.team2.name[0],
                                  style: TextStyle(
                                    fontSize: orientation == Orientation.portrait ? 24 : 16,
                                    color: Colors.white,
                                  ),
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
                    // 局信息和发球提示
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.blue[50],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Game ${match.currentGameNumber + 1}/${match.totalGames}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              // 查看历史按钮（如果存在已结束局）
                              if (match.games.any((g) => g.isCompleted))
                                IconButton(
                                  icon: const Icon(Icons.history, size: 20),
                                  onPressed: () {
                                    _showAllFinishedGamesDialog(context, match);
                                  },
                                  tooltip: 'View finished games',
                                ),
                            ],
                          ),
                          if (!match.isCompleted && match.firstServerDetermined)
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
                          if (!match.firstServerDetermined && !match.isCompleted)
                            const Text('Choose first server...'),
                          if (match.isTieBreak)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                match.deuceWinScore != null ? 'Deuce (${match.deuceWinScore})' : 'Deuce',
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 当前局比分 - 可点击加分
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          // 队伍1得分区域
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!match.isCompleted &&
                                    match.firstServerDetermined &&
                                    !match.currentGame.isCompleted) {
                                  match.addPoint(1);
                                }
                              },
                              child: Container(
                                color: match.currentServer == 1 && match.firstServerDetermined
                                    ? match.team1.color.withValues(alpha: 0.2)
                                    : match.team1.color.withValues(alpha: 0.1),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${match.currentGame.team1Score}',
                                      style: TextStyle(
                                        fontSize: scoreFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: match.team1.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 分隔线
                          Container(
                            width: 2,
                            color: Colors.grey[300],
                          ),
                          // 队伍2得分区域
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!match.isCompleted &&
                                    match.firstServerDetermined &&
                                    !match.currentGame.isCompleted) {
                                  match.addPoint(2);
                                }
                              },
                              child: Container(
                                color: match.currentServer == 2 && match.firstServerDetermined
                                    ? match.team2.color.withValues(alpha: 0.2)
                                    : match.team2.color.withValues(alpha: 0.1),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${match.currentGame.team2Score}',
                                      style: TextStyle(
                                        fontSize: scoreFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: match.team2.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 局歇提示
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
                    // 底部按钮（回退/返回主页）
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!match.isCompleted && match.currentGame.pointHistory.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () => match.undoLastPoint(),
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
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAdjustableGameEndDialog(BuildContext context, Match match) {
    int tempScore1 = match.currentGame.team1Score;
    int tempScore2 = match.currentGame.team2Score;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Game ${match.currentGameNumber + 1} Finished'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Adjust scores if needed:'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Team 1 score control
                      Column(
                        children: [
                          Text(
                            match.team1.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle),
                                onPressed: tempScore1 > 0
                                    ? () {
                                        setStateDialog(() {
                                          tempScore1--;
                                        });
                                      }
                                    : null,
                              ),
                              Text(
                                '$tempScore1',
                                style: const TextStyle(fontSize: 24),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: () {
                                  setStateDialog(() {
                                    tempScore1++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Team 2 score control
                      Column(
                        children: [
                          Text(
                            match.team2.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle),
                                onPressed: tempScore2 > 0
                                    ? () {
                                        setStateDialog(() {
                                          tempScore2--;
                                        });
                                      }
                                    : null,
                              ),
                              Text(
                                '$tempScore2',
                                style: const TextStyle(fontSize: 24),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: () {
                                  setStateDialog(() {
                                    tempScore2++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Winner: ${tempScore1 > tempScore2 ? match.team1.name : match.team2.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    match.correctGameScore(tempScore1, tempScore2);
                    match.confirmGameEnd();
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}