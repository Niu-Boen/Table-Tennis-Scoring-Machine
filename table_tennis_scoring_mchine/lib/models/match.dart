import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'team.dart';
import 'game.dart';

class Match extends ChangeNotifier {
  final String id;
  final DateTime startTime;
  Team team1;
  Team team2;
  int currentGameNumber;
  int totalGames;
  int pointsPerGame;
  int? deuceWinScore;
  List<Game> games;
  List<int> team1GameWins;
  List<int> team2GameWins;
  bool isCompleted;
  Team? matchWinner;
  int currentServer;
  int consecutiveServes;
  bool isTieBreak;
  bool needsSideChange;
  bool firstServerDetermined;
  bool _gameEndConfirmed;
  final List<int> _gameFirstServers;

  bool get gameEndConfirmed => _gameEndConfirmed;
  set gameEndConfirmed(bool value) {
    _gameEndConfirmed = value;
    notifyListeners();
  }

  Match({
    required this.id,
    required this.startTime,
    required this.team1,
    required this.team2,
    this.totalGames = 3,
    this.pointsPerGame = 11,
    this.deuceWinScore,
    List<Game>? games,
    this.currentGameNumber = 0,
    this.isCompleted = false,
    this.matchWinner,
    this.currentServer = 1,
    this.consecutiveServes = 0,
    this.isTieBreak = false,
    this.needsSideChange = false,
    this.firstServerDetermined = false,
    bool? gameEndConfirmed,
    List<int>? team1GameWins,
    List<int>? team2GameWins,
    List<int>? gameFirstServers,
  })  : games = games ?? [Game(team1Score: 0, team2Score: 0)],
        team1GameWins = team1GameWins ?? [],
        team2GameWins = team2GameWins ?? [],
        _gameEndConfirmed = gameEndConfirmed ?? false,
        _gameFirstServers = gameFirstServers ?? [];

  Game get currentGame => games[currentGameNumber];
  
  Game? get previousGame {
    if (currentGameNumber > 0) {
      return games[currentGameNumber - 1];
    }
    return null;
  }

  bool get isGamePoint =>
      (currentGame.team1Score >= pointsPerGame - 1 ||
          currentGame.team2Score >= pointsPerGame - 1) &&
      (currentGame.team1Score - currentGame.team2Score).abs() < 2;

  bool get needsTieBreak =>
      currentGame.team1Score >= pointsPerGame &&
      currentGame.team2Score >= pointsPerGame &&
      (currentGame.team1Score - currentGame.team2Score).abs() < 2;

  bool get needsInterval =>
      currentGameNumber == totalGames - 1 &&
      (currentGame.team1Score >= pointsPerGame ~/ 2 ||
          currentGame.team2Score >= pointsPerGame ~/ 2);

  bool get isGameEndedPending => currentGame.isCompleted && !_gameEndConfirmed;

  void addPoint(int team) {
    if (isCompleted || currentGame.isCompleted) return;

    Map<String, dynamic> pointRecord = {
      'timestamp': DateTime.now().toIso8601String(),
      'team': team,
      'gameNumber': currentGameNumber,
      'team1Score': currentGame.team1Score,
      'team2Score': currentGame.team2Score,
      'server': currentServer,
      'consecutiveServes': consecutiveServes,
    };

    if (team == 1) {
      currentGame.team1Score++;
      pointRecord['newScore1'] = currentGame.team1Score;
      pointRecord['newScore2'] = currentGame.team2Score;
    } else {
      currentGame.team2Score++;
      pointRecord['newScore1'] = currentGame.team1Score;
      pointRecord['newScore2'] = currentGame.team2Score;
    }

    currentGame.pointHistory.add(pointRecord);
    updateServing(team);
    checkGameCompletion();
    notifyListeners();
  }

  void updateServing(int scoringTeam) {
    consecutiveServes++;
    if (!isTieBreak) {
      if (consecutiveServes >= 2) {
        switchServer();
        consecutiveServes = 0;
      }
    } else {
      switchServer();
      consecutiveServes = 0;
    }
  }

  void switchServer() {
    currentServer = currentServer == 1 ? 2 : 1;
  }

  void checkGameCompletion() {
    if (currentGame.isCompleted) return;

    if (needsTieBreak) {
      isTieBreak = true;
    }

    bool gameWon = false;
    if (isTieBreak && deuceWinScore != null) {
      int s1 = currentGame.team1Score;
      int s2 = currentGame.team2Score;
      if ((s1 >= deuceWinScore! && s1 > s2) || (s2 >= deuceWinScore! && s2 > s1)) {
        gameWon = true;
      } else if ((s1 - s2).abs() >= 2) {
        gameWon = true;
      }
    } else {
      if (currentGame.team1Score >= pointsPerGame ||
          currentGame.team2Score >= pointsPerGame) {
        if ((currentGame.team1Score - currentGame.team2Score).abs() >= 2) {
          gameWon = true;
        }
      }
    }

    if (gameWon) {
      currentGame.isCompleted = true;
      _gameEndConfirmed = false;
      if (currentGame.team1Score > currentGame.team2Score) {
        currentGame.winner = team1;
        team1GameWins.add(currentGameNumber);
      } else {
        currentGame.winner = team2;
        team2GameWins.add(currentGameNumber);
      }
    }
  }

  void correctGameScore(int newScore1, int newScore2) {
    if (!currentGame.isCompleted || _gameEndConfirmed) return;

    if (currentGame.winner != null) {
      if (currentGame.winner == team1) {
        team1GameWins.remove(currentGameNumber);
      } else {
        team2GameWins.remove(currentGameNumber);
      }
    }

    currentGame.isCompleted = false;
    currentGame.winner = null;
    currentGame.team1Score = newScore1;
    currentGame.team2Score = newScore2;
    
    if (currentGameNumber < _gameFirstServers.length) {
      currentServer = _gameFirstServers[currentGameNumber];
      consecutiveServes = 0;
    }
    
    checkGameCompletion();
    notifyListeners();
  }

  void confirmGameEnd() {
    if (!currentGame.isCompleted || _gameEndConfirmed) return;

    _gameEndConfirmed = true;

    if (team1GameWins.length > totalGames ~/ 2 ||
        team2GameWins.length > totalGames ~/ 2) {
      isCompleted = true;
      matchWinner = team1GameWins.length > team2GameWins.length ? team1 : team2;
    } else if (currentGameNumber < totalGames - 1) {
      while (_gameFirstServers.length <= currentGameNumber) {
        _gameFirstServers.add(currentServer);
      }
      
      currentGameNumber++;
      games.add(Game(team1Score: 0, team2Score: 0));
      needsSideChange = true;
      isTieBreak = false;
      consecutiveServes = 0;
      
      if (currentGameNumber > 0) {
        int lastGameFirstServer = _gameFirstServers[currentGameNumber - 1];
        currentServer = lastGameFirstServer == 1 ? 2 : 1;
      }
    }
    notifyListeners();
  }

  void undoLastPoint() {
    if (currentGame.pointHistory.isEmpty) return;

    var lastPoint = currentGame.pointHistory.last;
    currentGame.team1Score = lastPoint['team1Score'];
    currentGame.team2Score = lastPoint['team2Score'];
    currentServer = lastPoint['server'];
    consecutiveServes = lastPoint['consecutiveServes'] ?? 0;
    currentGame.pointHistory.removeLast();
    isTieBreak = false;
    currentGame.isCompleted = false;
    _gameEndConfirmed = false;
    checkGameCompletion();
    notifyListeners();
  }

  void setFirstServer(int server) {
    currentServer = server;
    firstServerDetermined = true;
    _gameFirstServers.add(server);
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'team1': team1.toJson(),
        'team2': team2.toJson(),
        'currentGameNumber': currentGameNumber,
        'totalGames': totalGames,
        'pointsPerGame': pointsPerGame,
        'deuceWinScore': deuceWinScore,
        'games': games.map((g) => g.toJson()).toList(),
        'team1GameWins': team1GameWins,
        'team2GameWins': team2GameWins,
        'isCompleted': isCompleted,
        'matchWinner': matchWinner?.toJson(),
        'currentServer': currentServer,
        'consecutiveServes': consecutiveServes,
        'isTieBreak': isTieBreak,
        'needsSideChange': needsSideChange,
        'firstServerDetermined': firstServerDetermined,
        'gameEndConfirmed': _gameEndConfirmed,
        'gameFirstServers': _gameFirstServers,
      };

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'],
        startTime: DateTime.parse(json['startTime']),
        team1: Team.fromJson(json['team1']),
        team2: Team.fromJson(json['team2']),
        currentGameNumber: json['currentGameNumber'],
        totalGames: json['totalGames'],
        pointsPerGame: json['pointsPerGame'],
        deuceWinScore: json['deuceWinScore'],
        games: (json['games'] as List).map((g) => Game.fromJson(g)).toList(),
        team1GameWins: List<int>.from(json['team1GameWins']),
        team2GameWins: List<int>.from(json['team2GameWins']),
        isCompleted: json['isCompleted'],
        matchWinner: json['matchWinner'] != null ? Team.fromJson(json['matchWinner']) : null,
        currentServer: json['currentServer'],
        consecutiveServes: json['consecutiveServes'],
        isTieBreak: json['isTieBreak'],
        needsSideChange: json['needsSideChange'],
        firstServerDetermined: json['firstServerDetermined'] ?? false,
        gameEndConfirmed: json['gameEndConfirmed'] ?? false,
        gameFirstServers: json['gameFirstServers'] != null 
            ? List<int>.from(json['gameFirstServers']) 
            : [],
      );
}

class MatchProvider extends ChangeNotifier {
  List<Match> matches = [];
  List<Team> teams = [
    Team(id: '1', name: 'Red', color: Colors.red),
    Team(id: '2', name: 'Purple', color: Colors.purple),
    Team(id: '3', name: 'Pink', color: Colors.pink),
    Team(id: '4', name: 'Blue', color: Colors.blue),
  ];
  
  // 默认设置
  int defaultTotalGames = 3;
  int defaultPointsPerGame = 11;
  int? defaultDeuceWinScore;

  // 加载比赛数据
  Future<void> loadMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final String? matchesJson = prefs.getString('matches');
    if (matchesJson != null) {
      final List<dynamic> jsonList = jsonDecode(matchesJson);
      matches = jsonList.map((json) => Match.fromJson(json)).toList();
      notifyListeners();
    }
  }

  // 保存比赛数据
  Future<void> _saveMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final String matchesJson = jsonEncode(matches.map((m) => m.toJson()).toList());
    await prefs.setString('matches', matchesJson);
  }

  // 加载默认设置
  Future<void> loadDefaultSettings() async {
    final prefs = await SharedPreferences.getInstance();
    defaultTotalGames = prefs.getInt('defaultTotalGames') ?? 3;
    defaultPointsPerGame = prefs.getInt('defaultPointsPerGame') ?? 11;
    defaultDeuceWinScore = prefs.getInt('defaultDeuceWinScore');
    notifyListeners();
  }

  // 保存默认设置
  Future<void> saveDefaultSettings({
    required int totalGames,
    required int pointsPerGame,
    int? deuceWinScore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('defaultTotalGames', totalGames);
    await prefs.setInt('defaultPointsPerGame', pointsPerGame);
    if (deuceWinScore != null) {
      await prefs.setInt('defaultDeuceWinScore', deuceWinScore);
    } else {
      await prefs.remove('defaultDeuceWinScore');
    }
    
    defaultTotalGames = totalGames;
    defaultPointsPerGame = pointsPerGame;
    defaultDeuceWinScore = deuceWinScore;
    notifyListeners();
  }

  void addMatch(Match match) {
    matches.add(match);
    _saveMatches();
    notifyListeners();
  }

  void addTeam(Team team) {
    teams.add(team);
    notifyListeners();
  }

  void deleteMatch(String matchId) {
    matches.removeWhere((match) => match.id == matchId);
    _saveMatches();
    notifyListeners();
  }

  List<Match> get completedMatches => matches.where((m) => m.isCompleted).toList();
  List<Match> get activeMatches => matches.where((m) => !m.isCompleted).toList();
}