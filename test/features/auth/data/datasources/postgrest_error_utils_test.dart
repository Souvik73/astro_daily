import 'package:astro_daily/features/auth/data/datasources/postgrest_error_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('Postgrest error utils', () {
    test('parses structured PostgREST payloads from the message body', () {
      const supabase.PostgrestException error = supabase.PostgrestException(
        message:
            """{"code":"PGRST205","details":null,"hint":null,"message":"Could not find the table 'public.profiles' in the schema cache"}""",
        code: '404',
      );

      final ParsedPostgrestError parsed = parsePostgrestError(error);

      expect(parsed.code, 'PGRST205');
      expect(
        parsed.message,
        "Could not find the table 'public.profiles' in the schema cache",
      );
    });

    test('detects missing table errors from schema cache responses', () {
      const supabase.PostgrestException error = supabase.PostgrestException(
        message:
            """{"code":"PGRST205","details":null,"hint":null,"message":"Could not find the table 'public.profiles' in the schema cache"}""",
        code: '404',
      );

      expect(
        isMissingPostgrestTableError(error, tableName: 'profiles'),
        isTrue,
      );
      expect(
        normalizePostgrestDataMessage(error, tableName: 'profiles'),
        'The Supabase table "profiles" is not configured for this app.',
      );
    });

    test('detects no-rows errors', () {
      const supabase.PostgrestException error = supabase.PostgrestException(
        message: 'JSON object requested, multiple (or no) rows returned',
        code: 'PGRST116',
      );

      expect(isNoRowsPostgrestError(error), isTrue);
    });
  });
}
