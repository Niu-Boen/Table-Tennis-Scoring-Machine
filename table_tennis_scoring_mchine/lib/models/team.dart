import 'package:flutter/material.dart';

class Team {
  final String id;
  String name;
  final Color color;
  List<String> playerNames; // 球员名字列表，单打长度为1，双打长度为2

  Team({
    required this.id,
    required this.name,
    required this.color,
    this.playerNames = const ['Player'],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'playerNames': playerNames,
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'],
        name: json['name'],
        color: Color(json['color']),
        playerNames: List<String>.from(json['playerNames'] ?? ['Player']),
      );
}