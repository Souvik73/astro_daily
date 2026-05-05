import 'package:equatable/equatable.dart';

enum ChatAuthor { user, assistant }

final class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.author,
    required this.timestamp,
    this.suggestions = const <String>[],
  });

  final String id;
  final String content;
  final ChatAuthor author;
  final DateTime timestamp;

  /// Contextual follow-up questions generated alongside this message.
  /// Only non-empty on assistant messages; always empty on user messages.
  final List<String> suggestions;

  bool get isUser => author == ChatAuthor.user;

  ChatMessage copyWith({
    String? id,
    String? content,
    ChatAuthor? author,
    DateTime? timestamp,
    List<String>? suggestions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      timestamp: timestamp ?? this.timestamp,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, content, author, timestamp, suggestions];
}
