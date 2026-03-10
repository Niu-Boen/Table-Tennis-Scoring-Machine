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
  Team? _selectedTeam1;
  Team? _selectedTeam2;
  final TextEditingController _newTeamController = TextEditingController();
  final TextEditingController _deuceScoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 从Provider加载默认设置
    final provider = Provider.of<MatchProvider>(context, listen: false);
    _totalGames = provider.defaultTotalGames;
    _pointsPerGame = provider.defaultPointsPerGame;
    _deuceWinScore = provider.defaultDeuceWinScore;
    
    // 设置加时赛分数控制器
    if (_deuceWinScore != null) {
      _deuceScoreController.text = _deuceWinScore.toString();
    }
  }

  // 保存当前设置为默认值
  Future<void> _saveAsDefault() async {
    final provider = Provider.of<MatchProvider>(context, listen: false);
    await provider.saveDefaultSettings(
      totalGames: _totalGames,
      pointsPerGame: _pointsPerGame,
      deuceWinScore: _deuceWinScore,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved as default')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Match'),
        actions: [
          // 保存为默认设置按钮
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
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<Team>(
                                initialValue: _selectedTeam1,
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
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<Team>(
                                initialValue: _selectedTeam2,
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
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
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
                                  ));
                                  _newTeamController.clear();
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
                    if (_selectedTeam1 != null && _selectedTeam2 != null) {
                      if (_selectedTeam1!.id != _selectedTeam2!.id) {
                        // 自动保存为默认设置
                        _saveAsDefault();
                        
                        final match = Match(
                          id: DateTime.now().toString(),
                          startTime: DateTime.now(),
                          team1: _selectedTeam1!,
                          team2: _selectedTeam2!,
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
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select two different teams')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select both teams')),
                      );
                    }
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