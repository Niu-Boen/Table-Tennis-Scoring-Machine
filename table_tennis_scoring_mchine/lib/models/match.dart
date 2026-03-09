import 'package:flutter/material.dart';
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
  List<Game> games;
  List<int> team1GameWins;
  List<int> team2GameWins;
  bool isCompleted;
  Team? matchWinner;
  int currentServer; // 1 for team1, 2 for team2
  int consecutiveServes;
  bool isTieBreak;
  bool needsSideChange;

  Match({
    required this.id,
    required this.startTime,
    required this.team1,
    required this.team2,
    this.totalGames = 3,
    this.pointsPerGame = 11,
    List<Game>? games,
    this.currentGameNumber = 0,
    this.isCompleted = false,
    this.matchWinner,
    this.currentServer = 1,
    this.consecutiveServes = 0,
    this.isTieBreak = false,
    this.needsSideChange = false,
    List<int>? team1GameWins,
    List<int>? team2GameWins,
  })  : games = games ?? [Game(team1Score: 0, team2Score: 0)],
        team1GameWins = team1GameWins ?? [],
        team2GameWins = team2GameWins ?? [];

  Game get currentGame => games[currentGameNumber];

  bool get isGamePoint =>
      (currentGame.team1Score >= pointsPerGame - 1 ||
          currentGame.team2Score >= pointsPerGame - 1) &&
      (currentGame.team1Score - currentGame.team2Score).abs() < 2;

  bool get needsTieBreak =>
      currentGame.team1Score >= pointsPerGame &&
      currentGame.team2Score >= pointsPerGame &&
      (currentGame.team1Score - currentGame.team2Score).abs() < 2;

  bool get needsInterval =>
      currentGameNumber == 2 &&
      (currentGame.team1Score >= pointsPerGame ~/ 2 ||
          currentGame.team2Score >= pointsPerGame ~/ 2);

  void addPoint(int team) {
    if (isCompleted) return;

    Map<String, dynamic> pointRecord = {
      'timestamp': DateTime.now().toIso8601String(),
      'team': team,
      'gameNumber': currentGameNumber,
      'team1Score': currentGame.team1Score,
      'team2Score': currentGame.team2Score,
      'server': currentServer,
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
    if (needsTieBreak) isTieBreak = true;

    if (currentGame.team1Score >= pointsPerGame ||
        currentGame.team2Score >= pointsPerGame) {
      if ((currentGame.team1Score - currentGame.team2Score).abs() >= 2) {
        currentGame.isCompleted = true;
        if (currentGame.team1Score > currentGame.team2Score) {
          currentGame.winner = team1;
          team1GameWins.add(currentGameNumber);
        } else {
          currentGame.winner = team2;
          team2GameWins.add(currentGameNumber);
        }

        if (team1GameWins.length > totalGames ~/ 2 ||
            team2GameWins.length > totalGames ~/ 2) {
          isCompleted = true;
          matchWinner = team1GameWins.length > team2GameWins.length ? team1 : team2;
        } else if (currentGameNumber < totalGames - 1) {
          currentGameNumber++;
          games.add(Game(team1Score: 0, team2Score: 0));
          needsSideChange = true;
          isTieBreak = false;
          consecutiveServes = 0;
          currentServer = currentGameNumber % 2 == 0 ? 1 : 2;
        }
      }
    }
  }

  void undoLastPoint() {
    if (currentGame.pointHistory.isEmpty) return;

    var lastPoint = currentGame.pointHistory.last;
    currentGame.team1Score = lastPoint['team1Score'];
    currentGame.team2Score = lastPoint['team2Score'];
    currentServer = lastPoint['server'];
    currentGame.pointHistory.removeLast();
    isTieBreak = false;
    checkGameCompletion();
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
        'games': games.map((g) => g.toJson()).toList(),
        'team1GameWins': team1GameWins,
        'team2GameWins': team2GameWins,
        'isCompleted': isCompleted,
        'matchWinner': matchWinner?.toJson(),
        'currentServer': currentServer,
        'consecutiveServes': consecutiveServes,
        'isTieBreak': isTieBreak,
        'needsSideChange': needsSideChange,
      };

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'],
        startTime: DateTime.parse(json['startTime']),
        team1: Team.fromJson(json['team1']),
        team2: Team.fromJson(json['team2']),
        currentGameNumber: json['currentGameNumber'],
        totalGames: json['totalGames'],
        pointsPerGame: json['pointsPerGame'],
        games: (json['games'] as List).map((g) => Game.fromJson(g)).toList(),
        team1GameWins: List<int>.from(json['team1GameWins']),
        team2GameWins: List<int>.from(json['team2GameWins']),
        isCompleted: json['isCompleted'],
        matchWinner: json['matchWinner'] != null ? Team.fromJson(json['matchWinner']) : null,
        currentServer: json['currentServer'],
        consecutiveServes: json['consecutiveServes'],
        isTieBreak: json['isTieBreak'],
        needsSideChange: json['needsSideChange'],
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

  void addMatch(Match match) {
    matches.add(match);
    notifyListeners();
  }

  void addTeam(Team team) {
    teams.add(team);
    notifyListeners();
  }

  List<Match> get completedMatches => matches.where((m) => m.isCompleted).toList();
  List<Match> get activeMatches => matches.where((m) => !m.isCompleted).toList();
}