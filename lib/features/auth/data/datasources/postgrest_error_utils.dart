import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class ParsedPostgrestError {
  const ParsedPostgrestError({required this.message, this.code});

  final String message;
  final String? code;
}

ParsedPostgrestError parsePostgrestError(supabase.PostgrestException error) {
  final String rawMessage = error.message.trim();
  if (rawMessage.startsWith('{') && rawMessage.endsWith('}')) {
    try {
      final dynamic decoded = jsonDecode(rawMessage);
      if (decoded is Map) {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(decoded);
        return ParsedPostgrestError(
          message: _readString(payload, 'message') ?? rawMessage,
          code: _readString(payload, 'code') ?? error.code,
        );
      }
    } catch (_) {
      // Fall back to the raw message when PostgREST returns plain text.
    }
  }

  return ParsedPostgrestError(message: rawMessage, code: error.code);
}

bool isNoRowsPostgrestError(supabase.PostgrestException error) {
  final ParsedPostgrestError parsed = parsePostgrestError(error);
  return parsed.code == 'PGRST116' ||
      parsed.message.toLowerCase().contains('0 rows');
}

bool isMissingPostgrestTableError(
  supabase.PostgrestException error, {
  required String tableName,
}) {
  final ParsedPostgrestError parsed = parsePostgrestError(error);
  final String message = parsed.message.toLowerCase();
  final String lowerTableName = tableName.toLowerCase();
  final String qualifiedTableName = 'public.$lowerTableName';
  final bool mentionsTable =
      message.contains(lowerTableName) || message.contains(qualifiedTableName);

  return parsed.code == 'PGRST205' ||
      (mentionsTable &&
          (message.contains('could not find the table') ||
              message.contains('does not exist')));
}

String normalizePostgrestDataMessage(
  supabase.PostgrestException error, {
  String? tableName,
}) {
  if (tableName != null &&
      isMissingPostgrestTableError(error, tableName: tableName)) {
    return 'The Supabase table "$tableName" is not configured for this app.';
  }

  final String normalized = parsePostgrestError(error).message.trim();
  if (normalized.isNotEmpty) {
    return normalized;
  }
  if (tableName == null) {
    return 'A data error occurred. Please try again.';
  }
  return 'Unable to access $tableName right now.';
}

String? _readString(Map<String, dynamic> payload, String key) {
  final Object? value = payload[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}
