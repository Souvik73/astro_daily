import 'package:equatable/equatable.dart';

enum ChatAuthor { user, assistant }

final class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.author,
    required this.timestamp,
  });

  final String id;
  final String content;
  final ChatAuthor author;
  final DateTime timestamp;

  bool get isUser => author == ChatAuthor.user;

  ChatMessage copyWith({
    String? id,
    String? content,
    ChatAuthor? author,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, content, author, timestamp];
}
