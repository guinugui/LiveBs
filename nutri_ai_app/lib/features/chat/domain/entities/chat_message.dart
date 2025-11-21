import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String userId;
  final String message;
  final String role; // 'user' or 'assistant'
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.message,
    required this.role,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, message, role, createdAt];
}
