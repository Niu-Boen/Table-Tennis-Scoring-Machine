import 'team.dart';

class Game {
  int team1Score;
  int team2Score;
  bool isCompleted;
  Team? winner;
  List<Map<String, dynamic>> pointHistory;

  Game({
    required this.team1Score,
    required this.team2Score,
    this.isCompleted = false,
    this.winner,
    List<Map<String, dynamic>>? pointHistory,
  }) : pointHistory = pointHistory ?? [];

  Map<String, dynamic> toJson() => {
        'team1Score': team1Score,
        'team2Score': team2Score,
        'isCompleted': isCompleted,
        'winner': winner?.toJson(),
        'pointHistory': pointHistory,
      };

  factory Game.fromJson(Map<String, dynamic> json) => Game(
        team1Score: json['team1Score'],
        team2Score: json['team2Score'],
        isCompleted: json['isCompleted'],
        winner: json['winner'] != null ? Team.fromJson(json['winner']) : null,
        pointHistory: List<Map<String, dynamic>>.from(json['pointHistory']),
      );
}
 