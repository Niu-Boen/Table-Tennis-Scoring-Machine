import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';
import '../models/team.dart';

class ScoreScreen extends StatefulWidget {
  final Match match;

  const ScoreScreen({super.key, required this.match});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  bool _dialogShown = false; // 防止重复弹窗

  @override
  void initState() {
    super.initState();
    _checkAndShowStartDialog();
  }

  void _checkAndShowStartDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.match.firstServerDetermined &&
          !widget.match.isCompleted &&
          !_dialogShown) {
        _dialogShown = true;
        _showServeAndReceiveDialog();
      }
    });
  }

  void _showTopSnackbar(String message, {Color backgroundColor = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: backgroundColor.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 10,
          right: 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 显示发球/接发选择对话框（两步）
  void _showServeAndReceiveDialog() {
    final match = widget.match;
    int? serverTeam;
    int? serverPlayer;
    int? receiverTeam;
    int? receiverPlayer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // 第一步：选择发球
            if (serverTeam == null) {
              return AlertDialog(
                title: Text('Game ${match.currentGameNumber + 1} - Choose Server'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select who will serve first:'),
                    const SizedBox(height: 16),
                    _buildTeamPlayerSelector(
                      match,
                      setStateDialog,
                      (team, player) {
                        serverTeam = team;
                        serverPlayer = player;
                        setStateDialog(() {});
                      },
                    ),
                  ],
                ),
              );
            }
            // 第二步：选择接发
            else {
              return AlertDialog(
                title: Text('Game ${match.currentGameNumber + 1} - Choose Receiver'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Server: ${_getPlayerName(match, serverTeam!, serverPlayer!)}'),
                    const SizedBox(height: 16),
                    const Text('Select who will receive:'),
                    const SizedBox(height: 16),
                    _buildTeamPlayerSelector(
                      match,
                      setStateDialog,
                      (team, player) {
                        receiverTeam = team;
                        receiverPlayer = player;
                        // 完成选择
                        match.setServeAndReceive(
                          serverTeam: serverTeam!,
                          serverPlayer: serverPlayer!,
                          receiverTeam: receiverTeam!,
                          receiverPlayer: receiverPlayer!,
                        );
                        _dialogShown = false;
                        Navigator.of(context).pop();
                        _showTopSnackbar(
                          'Server: ${_getPlayerName(match, serverTeam!, serverPlayer!)}\n'
                          'Receiver: ${_getPlayerName(match, receiverTeam!, receiverPlayer!)}',
                        );
                      },
                      excludeTeam: serverTeam, // 接发不能选同一队
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    ).then((_) {
      _dialogShown = false;
    });
  }

  // 构建队伍球员选择器（每队一行，显示球员按钮）
  Widget _buildTeamPlayerSelector(
    Match match,
    StateSetter setStateDialog,
    Function(int team, int player) onSelected, {
    int? excludeTeam,
  }) {
    return Column(
      children: [
        _buildTeamRow(
          match.team1,
          1,
          match.team1.playerNames,
          setStateDialog,
          onSelected,
          excludeTeam: excludeTeam,
        ),
        const SizedBox(height: 16),
        _buildTeamRow(
          match.team2,
          2,
          match.team2.playerNames,
          setStateDialog,
          onSelected,
          excludeTeam: excludeTeam,
        ),
      ],
    );
  }

  Widget _buildTeamRow(
    Team team,
    int teamIndex,
    List<String> players,
    StateSetter setStateDialog,
    Function(int team, int player) onSelected, {
    int? excludeTeam,
  }) {
    if (excludeTeam == teamIndex) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            team.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: team.color,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(players.length, (index) {
            return ElevatedButton(
              onPressed: () => onSelected(teamIndex, index),
              style: ElevatedButton.styleFrom(
                backgroundColor: team.color,
                foregroundColor: Colors.white,
              ),
              child: Text(players[index]),
            );
          }),
        ),
      ],
    );
  }

  String _getPlayerName(Match match, int team, int player) {
    final t = team == 1 ? match.team1 : match.team2;
    return '${t.name} - ${t.playerNames[player]}';
  }

  // 显示已结束局列表
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

          // 检测是否需要弹出下一局开始对话框（当比赛未结束、发球未决定、当前局未完成时）
          if (!match.isCompleted &&
              !match.firstServerDetermined &&
              !match.currentGame.isCompleted &&
              !_dialogShown) {
            _dialogShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showServeAndReceiveDialog();
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
                    // 当前发球/接发显示
                    if (match.firstServerDetermined && !match.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.blue[50],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_tennis, size: 20, color: match.currentServerTeam == 1 ? match.team1.color : match.team2.color),
                            const SizedBox(width: 8),
                            Text(
                              'Serve: ${match.currentServerTeamName} - ${match.currentServerPlayerName}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.sports_score, size: 20, color: match.currentReceiverTeam == 1 ? match.team1.color : match.team2.color),
                            const SizedBox(width: 8),
                            Text(
                              'Receive: ${match.currentReceiverTeamName} - ${match.currentReceiverPlayerName}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    // 局信息和历史按钮
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
                    // 当前局比分
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
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
                                color: match.currentServerTeam == 1 && match.firstServerDetermined
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
                          Container(
                            width: 2,
                            color: Colors.grey[300],
                          ),
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
                                color: match.currentServerTeam == 2 && match.firstServerDetermined
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
                      Column(
                        children: [
                          Text(match.team1.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle),
                                onPressed: tempScore1 > 0 ? () => setStateDialog(() => tempScore1--) : null,
                              ),
                              Text('$tempScore1', style: const TextStyle(fontSize: 24)),
                              IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: () => setStateDialog(() => tempScore1++),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(match.team2.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle),
                                onPressed: tempScore2 > 0 ? () => setStateDialog(() => tempScore2--) : null,
                              ),
                              Text('$tempScore2', style: const TextStyle(fontSize: 24)),
                              IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: () => setStateDialog(() => tempScore2++),
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
                    // 下一局需要重新选择发球接发
                    if (!match.isCompleted) {
                      match.resetFirstServerForNextGame();
                    }
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