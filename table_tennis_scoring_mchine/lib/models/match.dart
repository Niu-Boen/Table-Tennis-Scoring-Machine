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
  bool isDoubles;
  int currentGameNumber;
  int totalGames;
  int pointsPerGame;
  int? deuceWinScore;
  List<Game> games;
  List<int> team1GameWins;
  List<int> team2GameWins;
  bool isCompleted;
  Team? matchWinner;
  int currentServerTeam; // 1 or 2
  int currentServerPlayer; // 0 or 1
  int currentReceiverTeam; // 1 or 2
  int currentReceiverPlayer; // 0 or 1
  int consecutiveServes;
  bool isTieBreak;
  bool needsSideChange;
  bool firstServerDetermined;
  bool _gameEndConfirmed;
  final List<int> _gameFirstServers; // 记录每局第一个发球队伍

  // 双打轮转索引（正确顺序：0: A1发B1接, 1: B1发A2接, 2: A2发B2接, 3: B2发A1接）
  int _doublesRotationIndex = 0;

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
    this.isDoubles = false,
    this.totalGames = 3,
    this.pointsPerGame = 11,
    this.deuceWinScore,
    List<Game>? games,
    this.currentGameNumber = 0,
    this.isCompleted = false,
    this.matchWinner,
    this.currentServerTeam = 1,
    this.currentServerPlayer = 0,
    this.currentReceiverTeam = 2,
    this.currentReceiverPlayer = 0,
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

  String get currentServerTeamName => currentServerTeam == 1 ? team1.name : team2.name;
  String get currentServerPlayerName {
    final team = currentServerTeam == 1 ? team1 : team2;
    return team.playerNames[currentServerPlayer];
  }

  String get currentReceiverTeamName => currentReceiverTeam == 1 ? team1.name : team2.name;
  String get currentReceiverPlayerName {
    final team = currentReceiverTeam == 1 ? team1 : team2;
    return team.playerNames[currentReceiverPlayer];
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
      'serverTeam': currentServerTeam,
      'serverPlayer': currentServerPlayer,
      'receiverTeam': currentReceiverTeam,
      'receiverPlayer': currentReceiverPlayer,
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
        _rotateServe();
        consecutiveServes = 0;
      }
    } else {
      _rotateServe();
      consecutiveServes = 0;
    }
  }

  // 双打发球轮转（正确顺序）
  void _rotateServe() {
    if (!isDoubles) {
      // 单打：交换发球队伍
      currentServerTeam = currentServerTeam == 1 ? 2 : 1;
      currentReceiverTeam = currentServerTeam == 1 ? 2 : 1;
      return;
    }

    // 双打轮转索引递增
    _doublesRotationIndex = (_doublesRotationIndex + 1) % 4;
    _applyDoublesRotation();
  }

  void _applyDoublesRotation() {
    // 根据索引设置发球和接发球员
    switch (_doublesRotationIndex) {
      case 0: // A1发球，B1接发
        currentServerTeam = 1;
        currentServerPlayer = 0;
        currentReceiverTeam = 2;
        currentReceiverPlayer = 0;
        break;
      case 1: // B1发球，A2接发
        currentServerTeam = 2;
        currentServerPlayer = 0;
        currentReceiverTeam = 1;
        currentReceiverPlayer = 1;
        break;
      case 2: // A2发球，B2接发
        currentServerTeam = 1;
        currentServerPlayer = 1;
        currentReceiverTeam = 2;
        currentReceiverPlayer = 1;
        break;
      case 3: // B2发球，A1接发
        currentServerTeam = 2;
        currentServerPlayer = 1;
        currentReceiverTeam = 1;
        currentReceiverPlayer = 0;
        break;
    }
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

    // 重置发球状态到当前局开始时的状态
    if (currentGameNumber < _gameFirstServers.length) {
      final firstServer = _gameFirstServers[currentGameNumber];
      if (isDoubles) {
        // 双打：需要根据第一个发球队伍设置轮转索引
        _resetDoublesServe(firstServer);
      } else {
        currentServerTeam = firstServer;
        currentReceiverTeam = firstServer == 1 ? 2 : 1;
      }
    }

    checkGameCompletion();
    notifyListeners();
  }

  // 根据第一个发球队伍重置双打轮转索引
  void _resetDoublesServe(int firstServerTeam) {
    if (firstServerTeam == 1) {
      _doublesRotationIndex = 0; // A1发球
    } else {
      _doublesRotationIndex = 1; // B1发球
    }
    _applyDoublesRotation();
  }

  void confirmGameEnd() {
    if (!currentGame.isCompleted || _gameEndConfirmed) return;

    _gameEndConfirmed = true;

    // 记录本局的第一个发球队伍
    while (_gameFirstServers.length <= currentGameNumber) {
      _gameFirstServers.add(currentServerTeam);
    }

    if (team1GameWins.length > totalGames ~/ 2 ||
        team2GameWins.length > totalGames ~/ 2) {
      isCompleted = true;
      matchWinner = team1GameWins.length > team2GameWins.length ? team1 : team2;
    } else if (currentGameNumber < totalGames - 1) {
      // 进入下一局
      currentGameNumber++;
      games.add(Game(team1Score: 0, team2Score: 0));
      needsSideChange = true;
      isTieBreak = false;
      consecutiveServes = 0;

      // 下一局第一个发球方应为上一局的接发球方
      int nextFirstServerTeam = currentReceiverTeam;
      // 下一局第一个接发方为对方，接发球员由规则决定
      if (isDoubles) {
        // 双打：根据上一局最后一个接发球员确定下一局的初始轮转
        // 上一局最后一个发球队伍是 currentServerTeam，最后一个接发队伍是 currentReceiverTeam
        // 下一局第一个发球方是上一局的接发球方，且该方应轮到其相应的球员发球
        // 简化：我们让用户手动选择第一局的发球接发，后续局则按照规则自动轮转
        // 这里我们根据上一局的最后一个发球队伍来推算下一局的初始索引
        // 如果上一局最后一个发球是 A1（索引0），则下一局应由 B1 发球（索引1）
        // 如果上一局最后一个发球是 B1（索引1），则下一局应由 A2 发球（索引2）
        // 如果上一局最后一个发球是 A2（索引2），则下一局应由 B2 发球（索引3）
        // 如果上一局最后一个发球是 B2（索引3），则下一局应由 A1 发球（索引0）
        _doublesRotationIndex = (_doublesRotationIndex + 1) % 4;
        _applyDoublesRotation();
      } else {
        // 单打：交换发球队伍
        currentServerTeam = nextFirstServerTeam;
        currentReceiverTeam = currentServerTeam == 1 ? 2 : 1;
      }
    }
    notifyListeners();
  }

  void undoLastPoint() {
    if (currentGame.pointHistory.isEmpty) return;

    var lastPoint = currentGame.pointHistory.last;
    currentGame.team1Score = lastPoint['team1Score'];
    currentGame.team2Score = lastPoint['team2Score'];
    currentServerTeam = lastPoint['serverTeam'];
    currentServerPlayer = lastPoint['serverPlayer'];
    currentReceiverTeam = lastPoint['receiverTeam'];
    currentReceiverPlayer = lastPoint['receiverPlayer'];
    consecutiveServes = lastPoint['consecutiveServes'] ?? 0;
    if (isDoubles) {
      _updateDoublesIndexFromState();
    }
    currentGame.pointHistory.removeLast();
    isTieBreak = false;
    currentGame.isCompleted = false;
    _gameEndConfirmed = false;
    checkGameCompletion();
    notifyListeners();
  }

  void _updateDoublesIndexFromState() {
    // 根据当前发球和接发球员推算轮转索引
    if (currentServerTeam == 1 && currentServerPlayer == 0 && currentReceiverTeam == 2 && currentReceiverPlayer == 0) {
      _doublesRotationIndex = 0;
    } else if (currentServerTeam == 2 && currentServerPlayer == 0 && currentReceiverTeam == 1 && currentReceiverPlayer == 1) {
      _doublesRotationIndex = 1;
    } else if (currentServerTeam == 1 && currentServerPlayer == 1 && currentReceiverTeam == 2 && currentReceiverPlayer == 1) {
      _doublesRotationIndex = 2;
    } else if (currentServerTeam == 2 && currentServerPlayer == 1 && currentReceiverTeam == 1 && currentReceiverPlayer == 0) {
      _doublesRotationIndex = 3;
    }
  }

  // 手动设置发球和接发（用于开局选择）
  void setServeAndReceive({
    required int serverTeam,
    required int serverPlayer,
    required int receiverTeam,
    required int receiverPlayer,
  }) {
    if (isCompleted) return;
    currentServerTeam = serverTeam;
    currentServerPlayer = serverPlayer;
    currentReceiverTeam = receiverTeam;
    currentReceiverPlayer = receiverPlayer;
    firstServerDetermined = true;
    if (isDoubles) {
      // 根据选择的发球者设置轮转索引
      if (serverTeam == 1 && serverPlayer == 0 && receiverTeam == 2 && receiverPlayer == 0) {
        _doublesRotationIndex = 0;
      } else if (serverTeam == 2 && serverPlayer == 0 && receiverTeam == 1 && receiverPlayer == 1) {
        _doublesRotationIndex = 1;
      } else if (serverTeam == 1 && serverPlayer == 1 && receiverTeam == 2 && receiverPlayer == 1) {
        _doublesRotationIndex = 2;
      } else if (serverTeam == 2 && serverPlayer == 1 && receiverTeam == 1 && receiverPlayer == 0) {
        _doublesRotationIndex = 3;
      } else {
        // 如果不符合标准轮转，默认设为0并警告
        _doublesRotationIndex = 0;
        _applyDoublesRotation();
      }
    }
    notifyListeners();
  }

  // 重置局开始状态（用于下一局手动选择）
  void resetFirstServerForNextGame() {
    firstServerDetermined = false;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'team1': team1.toJson(),
        'team2': team2.toJson(),
        'isDoubles': isDoubles,
        'currentGameNumber': currentGameNumber,
        'totalGames': totalGames,
        'pointsPerGame': pointsPerGame,
        'deuceWinScore': deuceWinScore,
        'games': games.map((g) => g.toJson()).toList(),
        'team1GameWins': team1GameWins,
        'team2GameWins': team2GameWins,
        'isCompleted': isCompleted,
        'matchWinner': matchWinner?.toJson(),
        'currentServerTeam': currentServerTeam,
        'currentServerPlayer': currentServerPlayer,
        'currentReceiverTeam': currentReceiverTeam,
        'currentReceiverPlayer': currentReceiverPlayer,
        'consecutiveServes': consecutiveServes,
        'isTieBreak': isTieBreak,
        'needsSideChange': needsSideChange,
        'firstServerDetermined': firstServerDetermined,
        'gameEndConfirmed': _gameEndConfirmed,
        'gameFirstServers': _gameFirstServers,
        'doublesRotationIndex': _doublesRotationIndex,
      };

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'],
        startTime: DateTime.parse(json['startTime']),
        team1: Team.fromJson(json['team1']),
        team2: Team.fromJson(json['team2']),
        isDoubles: json['isDoubles'] ?? false,
        currentGameNumber: json['currentGameNumber'],
        totalGames: json['totalGames'],
        pointsPerGame: json['pointsPerGame'],
        deuceWinScore: json['deuceWinScore'],
        games: (json['games'] as List).map((g) => Game.fromJson(g)).toList(),
        team1GameWins: List<int>.from(json['team1GameWins']),
        team2GameWins: List<int>.from(json['team2GameWins']),
        isCompleted: json['isCompleted'],
        matchWinner: json['matchWinner'] != null ? Team.fromJson(json['matchWinner']) : null,
        currentServerTeam: json['currentServerTeam'] ?? 1,
        currentServerPlayer: json['currentServerPlayer'] ?? 0,
        currentReceiverTeam: json['currentReceiverTeam'] ?? 2,
        currentReceiverPlayer: json['currentReceiverPlayer'] ?? 0,
        consecutiveServes: json['consecutiveServes'] ?? 0,
        isTieBreak: json['isTieBreak'] ?? false,
        needsSideChange: json['needsSideChange'] ?? false,
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
    Team(id: '1', name: 'Red', color: Colors.red, playerNames: ['Player1']),
    Team(id: '2', name: 'Purple', color: Colors.purple, playerNames: ['Player1']),
    Team(id: '3', name: 'Pink', color: Colors.pink, playerNames: ['Player1']),
    Team(id: '4', name: 'Blue', color: Colors.blue, playerNames: ['Player1']),
  ];

  int defaultTotalGames = 3;
  int defaultPointsPerGame = 11;
  int? defaultDeuceWinScore;
  bool defaultIsDoubles = false;

  Future<void> loadMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final String? matchesJson = prefs.getString('matches');
    if (matchesJson != null) {
      final List<dynamic> jsonList = jsonDecode(matchesJson);
      matches = jsonList.map((json) => Match.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final String matchesJson = jsonEncode(matches.map((m) => m.toJson()).toList());
    await prefs.setString('matches', matchesJson);
  }

  Future<void> loadDefaultSettings() async {
    final prefs = await SharedPreferences.getInstance();
    defaultTotalGames = prefs.getInt('defaultTotalGames') ?? 3;
    defaultPointsPerGame = prefs.getInt('defaultPointsPerGame') ?? 11;
    defaultDeuceWinScore = prefs.getInt('defaultDeuceWinScore');
    defaultIsDoubles = prefs.getBool('defaultIsDoubles') ?? false;
    notifyListeners();
  }

  Future<void> saveDefaultSettings({
    required int totalGames,
    required int pointsPerGame,
    int? deuceWinScore,
    required bool isDoubles,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('defaultTotalGames', totalGames);
    await prefs.setInt('defaultPointsPerGame', pointsPerGame);
    if (deuceWinScore != null) {
      await prefs.setInt('defaultDeuceWinScore', deuceWinScore);
    } else {
      await prefs.remove('defaultDeuceWinScore');
    }
    await prefs.setBool('defaultIsDoubles', isDoubles);

    defaultTotalGames = totalGames;
    defaultPointsPerGame = pointsPerGame;
    defaultDeuceWinScore = deuceWinScore;
    defaultIsDoubles = isDoubles;
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