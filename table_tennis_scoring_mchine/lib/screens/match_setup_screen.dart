import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';
import '../models/team.dart';
import 'score_screen.dart';

class MatchSetupScreen extends StatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late int _totalGames;
  late int _pointsPerGame;
  int? _deuceWinScore;
  late bool _isDoubles;
  Team? _selectedTeam1;
  Team? _selectedTeam2;
  final TextEditingController _newTeamController = TextEditingController();
  final TextEditingController _deuceScoreController = TextEditingController();

  // 球员名字控制器（双打用）
  final List<TextEditingController> _team1PlayerControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final List<TextEditingController> _team2PlayerControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MatchProvider>(context, listen: false);
    _totalGames = provider.defaultTotalGames;
    _pointsPerGame = provider.defaultPointsPerGame;
    _deuceWinScore = provider.defaultDeuceWinScore;
    _isDoubles = provider.defaultIsDoubles;

    if (_deuceWinScore != null) {
      _deuceScoreController.text = _deuceWinScore.toString();
    }
  }

  void _showTopSnackbar(String message, {Color backgroundColor = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: backgroundColor.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 10,
          right: 10,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _saveAsDefault() async {
    final provider = Provider.of<MatchProvider>(context, listen: false);
    await provider.saveDefaultSettings(
      totalGames: _totalGames,
      pointsPerGame: _pointsPerGame,
      deuceWinScore: _deuceWinScore,
      isDoubles: _isDoubles,
    );
    if (mounted) {
      _showTopSnackbar('Settings saved as default');
    }
  }

  // 验证并获取球员名字列表
  List<String> _getPlayerNames(List<TextEditingController> controllers) {
    return controllers
        .map((c) => c.text.trim().isEmpty ? 'Player' : c.text.trim())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Match'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAsDefault,
            tooltip: 'Save as default',
          ),
        ],
      ),
      body: Consumer<MatchProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Match Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        // 单打/双打选择
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Singles'),
                                value: false,
                                groupValue: _isDoubles,
                                onChanged: (value) {
                                  setState(() {
                                    _isDoubles = value ?? false;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Doubles'),
                                value: true,
                                groupValue: _isDoubles,
                                onChanged: (value) {
                                  setState(() {
                                    _isDoubles = value ?? false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _totalGames.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Total Games',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _totalGames = int.tryParse(value) ?? 3;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _pointsPerGame.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Points per Game',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _pointsPerGame = int.tryParse(value) ?? 11;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _deuceScoreController,
                          decoration: const InputDecoration(
                            labelText: 'Deuce Win Score (optional)',
                            hintText: 'e.g., 15',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _deuceWinScore = value.isEmpty ? null : int.tryParse(value);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Teams', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        // 队伍选择
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<Team>(
                                value: _selectedTeam1,
                                decoration: const InputDecoration(
                                  labelText: 'Team 1',
                                  border: OutlineInputBorder(),
                                ),
                                items: provider.teams.map((team) {
                                  return DropdownMenuItem(
                                    value: team,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: team.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(team.name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (team) {
                                  setState(() {
                                    _selectedTeam1 = team;
                                    // 重置球员名字输入
                                    if (team != null) {
                                      for (int i = 0; i < _team1PlayerControllers.length; i++) {
                                        _team1PlayerControllers[i].text = '';
                                      }
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<Team>(
                                value: _selectedTeam2,
                                decoration: const InputDecoration(
                                  labelText: 'Team 2',
                                  border: OutlineInputBorder(),
                                ),
                                items: provider.teams.map((team) {
                                  return DropdownMenuItem(
                                    value: team,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: team.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(team.name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (team) {
                                  setState(() {
                                    _selectedTeam2 = team;
                                    for (int i = 0; i < _team2PlayerControllers.length; i++) {
                                      _team2PlayerControllers[i].text = '';
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 球员名字输入（根据单双打显示不同数量）
                        if (_selectedTeam1 != null) ...[
                          const Text('Team 1 Players:'),
                          const SizedBox(height: 8),
                          for (int i = 0; i < (_isDoubles ? 2 : 1); i++) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: TextFormField(
                                controller: _team1PlayerControllers[i],
                                decoration: InputDecoration(
                                  labelText: 'Player ${i + 1} name',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ],
                        if (_selectedTeam2 != null) ...[
                          const SizedBox(height: 16),
                          const Text('Team 2 Players:'),
                          const SizedBox(height: 8),
                          for (int i = 0; i < (_isDoubles ? 2 : 1); i++) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: TextFormField(
                                controller: _team2PlayerControllers[i],
                                decoration: InputDecoration(
                                  labelText: 'Player ${i + 1} name',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 16),
                        const Text('Or add new team:'),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _newTeamController,
                                decoration: const InputDecoration(
                                  hintText: 'Team name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (_newTeamController.text.isNotEmpty) {
                                  provider.addTeam(Team(
                                    id: DateTime.now().toString(),
                                    name: _newTeamController.text,
                                    color: Colors.primaries[provider.teams.length % Colors.primaries.length],
                                    playerNames: _isDoubles ? ['Player1', 'Player2'] : ['Player1'],
                                  ));
                                  _newTeamController.clear();
                                  _showTopSnackbar('Team added successfully');
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedTeam1 == null || _selectedTeam2 == null) {
                      _showTopSnackbar('Please select both teams', backgroundColor: Colors.red);
                      return;
                    }
                    if (_selectedTeam1!.id == _selectedTeam2!.id) {
                      _showTopSnackbar('Please select two different teams', backgroundColor: Colors.red);
                      return;
                    }

                    // 构建球队实例（复制队伍，并设置球员名字）
                    final team1 = Team(
                      id: _selectedTeam1!.id,
                      name: _selectedTeam1!.name,
                      color: _selectedTeam1!.color,
                      playerNames: _getPlayerNames(_team1PlayerControllers),
                    );
                    final team2 = Team(
                      id: _selectedTeam2!.id,
                      name: _selectedTeam2!.name,
                      color: _selectedTeam2!.color,
                      playerNames: _getPlayerNames(_team2PlayerControllers),
                    );

                    // 自动保存为默认设置
                    _saveAsDefault();

                    final match = Match(
                      id: DateTime.now().toString(),
                      startTime: DateTime.now(),
                      team1: team1,
                      team2: team2,
                      isDoubles: _isDoubles,
                      totalGames: _totalGames,
                      pointsPerGame: _pointsPerGame,
                      deuceWinScore: _deuceWinScore,
                    );

                    provider.addMatch(match);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScoreScreen(match: match),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Start Match', style: TextStyle(fontSize: 18)),
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