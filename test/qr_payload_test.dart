import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_eventix/core/logic/qr_payload.dart';

/// Every expected value below was hand-traced against the formulas in
/// qr_payload.dart before being written down:
///
///   seedFromPayload: seed starts at 7; for each code unit c,
///     seed = (seed * 31 + c) % 9973
///
///   buildQrMatrix noise cell (row, col) outside the three finder zones:
///     cell = (seed + row * 13 + col * 17) % 7
///     filled = cell == 0 || cell == 3
///
/// bool _matricesEqual avoids depending on package:collection just to
/// compare two matrices in these tests.
bool _matricesEqual(List<List<bool>> a, List<List<bool>> b) {
  if (a.length != b.length) return false;
  for (var row = 0; row < a.length; row++) {
    if (a[row].length != b[row].length) return false;
    for (var col = 0; col < a[row].length; col++) {
      if (a[row][col] != b[row][col]) return false;
    }
  }
  return true;
}

void main() {
  group('buildTicketPayload', () {
    test('joins ticketId, eventId, tierId, and quantity with a fixed prefix', () {
      final payload = buildTicketPayload(
        ticketId: 'ticket-42',
        eventId: 'event-7',
        tierId: 'tier-vip',
        quantity: 3,
      );
      expect(payload, 'EVENTIX|ticket-42|event-7|tier-vip|3');
    });

    test('is stable for the same inputs (no wall-clock time involved)', () {
      final first = buildTicketPayload(ticketId: 't1', eventId: 'e1', tierId: 'ga', quantity: 1);
      final second = buildTicketPayload(ticketId: 't1', eventId: 'e1', tierId: 'ga', quantity: 1);
      expect(first, second);
    });

    test('differs when any single field differs', () {
      final base = buildTicketPayload(ticketId: 't1', eventId: 'e1', tierId: 'ga', quantity: 1);
      expect(buildTicketPayload(ticketId: 't2', eventId: 'e1', tierId: 'ga', quantity: 1), isNot(base));
      expect(buildTicketPayload(ticketId: 't1', eventId: 'e2', tierId: 'ga', quantity: 1), isNot(base));
      expect(buildTicketPayload(ticketId: 't1', eventId: 'e1', tierId: 'vip', quantity: 1), isNot(base));
      expect(buildTicketPayload(ticketId: 't1', eventId: 'e1', tierId: 'ga', quantity: 2), isNot(base));
    });
  });

  group('seedFromPayload', () {
    test('empty payload leaves the seed at its starting value of 7', () {
      expect(seedFromPayload(''), 7);
    });

    test('a single character: seed = (7 * 31 + 65) % 9973 = 282', () {
      expect(seedFromPayload('A'), 282);
    });

    test('two characters accumulate: seed = (282 * 31 + 66) % 9973 = 8808', () {
      expect(seedFromPayload('AB'), 8808);
    });

    test('is deterministic for the same payload', () {
      expect(seedFromPayload('EVENTIX|t1|e1|ga|2'), seedFromPayload('EVENTIX|t1|e1|ga|2'));
    });
  });

  group('buildQrMatrix - size validation', () {
    test('throws when size is below minQrMatrixSize', () {
      expect(() => buildQrMatrix('payload', size: minQrMatrixSize - 1), throwsArgumentError);
    });

    test('accepts exactly minQrMatrixSize', () {
      final matrix = buildQrMatrix('payload', size: minQrMatrixSize);
      expect(matrix.length, minQrMatrixSize);
      expect(matrix.every((row) => row.length == minQrMatrixSize), isTrue);
    });
  });

  group('buildQrMatrix - determinism', () {
    test('the same payload and size always produce the same matrix', () {
      const payload = 'EVENTIX|ticket-9|event-3|ga|2';
      final first = buildQrMatrix(payload, size: 21);
      final second = buildQrMatrix(payload, size: 21);
      expect(_matricesEqual(first, second), isTrue);
    });

    test('dimensions match the requested size', () {
      final matrix = buildQrMatrix('payload', size: 25);
      expect(matrix.length, 25);
      expect(matrix.every((row) => row.length == 25), isTrue);
    });
  });

  group('buildQrMatrix - finder squares (payload-independent)', () {
    // The three 7x7 finder squares are stamped after the noise fill and
    // never depend on the payload, so these hold for any payload.
    for (final payload in ['x', 'a-different-payload', '', 'EVENTIX|t1|e1|ga|1']) {
      test('are stamped the same way for payload "$payload"', () {
        final matrix = buildQrMatrix(payload, size: 21);

        // Top-left finder: border ring true, just inside the ring false,
        // solid 3x3 core true.
        expect(matrix[0][0], isTrue);
        expect(matrix[6][6], isTrue);
        expect(matrix[1][1], isFalse);
        expect(matrix[3][3], isTrue);

        // Top-right finder starts at column size - 7 = 14.
        expect(matrix[0][14], isTrue);
        expect(matrix[0][20], isTrue);
        expect(matrix[3][17], isTrue);

        // Bottom-left finder starts at row size - 7 = 14.
        expect(matrix[14][0], isTrue);
        expect(matrix[20][0], isTrue);
        expect(matrix[17][3], isTrue);
      });
    }
  });

  group('buildQrMatrix - hand-traced noise cells for payload "A" (seed 282)', () {
    test('cell (2, 7): (282 + 2*13 + 7*17) % 7 = 427 % 7 = 0 -> filled', () {
      final matrix = buildQrMatrix('A', size: 21);
      expect(matrix[2][7], isTrue);
    });

    test('cell (7, 7): (282 + 7*13 + 7*17) % 7 = 492 % 7 = 2 -> not filled', () {
      final matrix = buildQrMatrix('A', size: 21);
      expect(matrix[7][7], isFalse);
    });
  });

  group('buildQrMatrix - a different payload changes the noise', () {
    test('payload "B" (seed 283) differs from payload "A" at cell (2, 7)', () {
      // seedFromPayload('B') = (7*31+66) % 9973 = 283
      // cell = (283 + 2*13 + 7*17) % 7 = 428 % 7 = 1 -> not filled
      final matrixA = buildQrMatrix('A', size: 21);
      final matrixB = buildQrMatrix('B', size: 21);
      expect(matrixA[2][7], isTrue);
      expect(matrixB[2][7], isFalse);
      expect(_matricesEqual(matrixA, matrixB), isFalse);
    });
  });
}
