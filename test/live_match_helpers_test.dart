import 'package:flutter_test/flutter_test.dart';
import 'package:pickletrack/screens/live/live_match_helpers.dart';

void main() {
  group('filteredTeamNames', () {
    test('returns trimmed real names when present', () {
      final result = filteredTeamNames(
        [
          (name: 'Alice', team: 'A'),
          (name: '  Bob  ', team: 'A'),
          (name: 'Cara', team: 'B'),
        ],
        'A',
        matchType: 'doubles',
      );
      expect(result, ['Alice', 'Bob']);
    });

    test('returns the requested team only', () {
      final result = filteredTeamNames(
        [
          (name: 'A1', team: 'A'),
          (name: 'B1', team: 'B'),
        ],
        'A',
        matchType: 'doubles',
      );
      expect(result, ['A1']);
    });

    test('drops empty / whitespace-only names', () {
      final result = filteredTeamNames(
        const [
          (name: '', team: 'A'),
          (name: '   ', team: 'A'),
          (name: 'Dee', team: 'A'),
        ],
        'A',
        matchType: 'doubles',
      );
      expect(result, ['Dee']);
    });

    test('returns singles fallback for empty team', () {
      final result = filteredTeamNames(
        const [],
        'A',
        matchType: 'singles',
      );
      expect(result, ['Player 1']);
    });

    test('returns doubles fallback for empty team', () {
      final result = filteredTeamNames(
        const [],
        'A',
        matchType: 'doubles',
      );
      expect(result, ['Player 1', 'Player 2']);
    });

    test('falls back when all names on a team are blank', () {
      final result = filteredTeamNames(
        const [
          (name: '', team: 'A'),
          (name: '   ', team: 'A'),
        ],
        'A',
        matchType: 'doubles',
      );
      expect(result, ['Player 1', 'Player 2']);
    });
  });
}
