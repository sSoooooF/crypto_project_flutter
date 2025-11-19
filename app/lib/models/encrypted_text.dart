import '../core/streebog/streebog.dart';
import 'dart:convert';

class EncryptedText {
  final String? id;
  final String username;
  final String originalText;
  final String encryptedText;
  final String algorithm;
  final DateTime createdAt;

  EncryptedText({
    this.id,
    required this.username,
    required this.originalText,
    required this.encryptedText,
    required this.algorithm,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'originalText': originalText,
    'encryptedText': encryptedText,
    'algorithm': algorithm,
    'createdAt': createdAt.toIso8601String(),
  };

  factory EncryptedText.fromJson(Map<String, dynamic> json) => EncryptedText(
    id: json['id'],
    username: json['username'],
    originalText: json['originalText'],
    encryptedText: json['encryptedText'],
    algorithm: json['algorithm'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
