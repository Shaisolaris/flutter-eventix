/// Pure, deterministic "ticket pass" encoding. Nothing here depends on
/// Flutter or any model - every function takes plain values and returns a
/// plain value, so the whole module can be unit tested directly.
///
/// Eventix ships no barcode/QR package (no network access at build time to
/// fetch one, and no need for a demo app to scan real codes). Instead, each
/// ticket renders a stylized, QR-*like* block: three fixed finder squares in
/// the corners (matching where a real QR code puts them) surrounding a grid
/// of modules derived entirely from the ticket's payload string. The same
/// payload always produces the same block, and two different tickets
/// (almost always) render visibly different ones - which is all a demo
/// ticket needs to look convincing at a glance. It is not a scannable code.

/// Builds the deterministic string "encoded" by a ticket's QR-style block.
///
/// Built from stable identifiers only (never wall-clock time), so seeding
/// the same demo data always reproduces byte-identical payloads.
String buildTicketPayload({
  required String ticketId,
  required String eventId,
  required String tierId,
  required int quantity,
}) {
  return 'EVENTIX|$ticketId|$eventId|$tierId|$quantity';
}

/// Deterministic pseudo-random seed derived from [payload]: the same
/// payload always yields the same seed, and every step is plain integer
/// arithmetic simple enough to trace by hand for a short payload.
int seedFromPayload(String payload) {
  var seed = 7;
  for (final codeUnit in payload.codeUnits) {
    seed = (seed * 31 + codeUnit) % 9973; // 9973 is prime.
  }
  return seed;
}

/// The minimum matrix size [buildQrMatrix] accepts: small enough to render
/// clearly on a ticket card, large enough that the three 7x7 finder squares
/// (one per corner, bottom-right left open, exactly as on a real QR code)
/// never overlap.
const int minQrMatrixSize = 15;

/// Builds a deterministic `size x size` boolean matrix ("dark modules") for
/// [payload]. `true` means the module is drawn as a filled (dark) cell.
///
/// Throws an [ArgumentError] if [size] is below [minQrMatrixSize].
List<List<bool>> buildQrMatrix(String payload, {int size = 21}) {
  if (size < minQrMatrixSize) {
    throw ArgumentError.value(
      size,
      'size',
      'must be at least $minQrMatrixSize so the three finder squares do not overlap',
    );
  }

  final seed = seedFromPayload(payload);
  final matrix = List.generate(size, (_) => List<bool>.filled(size, false));

  for (var row = 0; row < size; row++) {
    for (var col = 0; col < size; col++) {
      if (_inFinderZone(row, col, size)) continue;
      final cell = (seed + row * 13 + col * 17) % 7;
      matrix[row][col] = cell == 0 || cell == 3;
    }
  }

  _stampFinderSquares(matrix, size);
  return matrix;
}

/// Whether (row, col) falls inside one of the three 7x7 finder-square zones
/// (top-left, top-right, bottom-left) that [_stampFinderSquares] overwrites.
bool _inFinderZone(int row, int col, int size) {
  final inTopRow = row < 7;
  final inBottomRow = row >= size - 7;
  final inLeftCol = col < 7;
  final inRightCol = col >= size - 7;
  return (inTopRow && inLeftCol) || (inTopRow && inRightCol) || (inBottomRow && inLeftCol);
}

/// Stamps the three fixed 7x7 finder squares - a solid border ring with a
/// solid 3x3 core, the same silhouette a real QR code uses - into the
/// top-left, top-right, and bottom-left corners of [matrix].
void _stampFinderSquares(List<List<bool>> matrix, int size) {
  void stamp(int rowOffset, int colOffset) {
    for (var row = 0; row < 7; row++) {
      for (var col = 0; col < 7; col++) {
        final isBorder = row == 0 || row == 6 || col == 0 || col == 6;
        final isCore = row >= 2 && row <= 4 && col >= 2 && col <= 4;
        matrix[rowOffset + row][colOffset + col] = isBorder || isCore;
      }
    }
  }

  stamp(0, 0);
  stamp(0, size - 7);
  stamp(size - 7, 0);
}
