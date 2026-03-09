import 'package:flutter/material.dart';

class Team {
  final String id;
  String name;
  final Color color;

  Team({required this.id, required this.name, required this.color});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(), // 修复 deprecated
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'],
        name: json['name'],
        color: Color(json['color']),
      );
}