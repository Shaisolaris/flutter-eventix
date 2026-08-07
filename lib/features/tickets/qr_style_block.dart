import 'package:flutter/material.dart';

import '../../core/logic/qr_payload.dart';

/// Renders the deterministic QR-*style* module grid for [payload] (see
/// `core/logic/qr_payload.dart`): a white card with a black module pattern
/// drawn by [CustomPaint]. Purely decorative - it is not a scannable code,
/// just a believable stand-in for one that is fully reproducible from the
/// ticket's own data.
class QrStyleBlock extends StatelessWidget {
  const QrStyleBlock({
    super.key,
    required this.payload,
    this.size = 132,
    this.moduleCount = 21,
  });

  final String payload;

  /// Outer side length of the card, in logical pixels.
  final double size;

  /// Number of modules per side. Must be at least [minQrMatrixSize].
  final int moduleCount;

  @override
  Widget build(BuildContext context) {
    final matrix = buildQrMatrix(payload, size: moduleCount);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        size: Size(size - 20, size - 20),
        painter: _QrMatrixPainter(matrix: matrix),
      ),
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  _QrMatrixPainter({required this.matrix});

  final List<List<bool>> matrix;

  @override
  void paint(Canvas canvas, Size size) {
    if (matrix.isEmpty) return;
    final rows = matrix.length;
    final cols = matrix.first.length;
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if (!matrix[row][col]) continue;
        canvas.drawRect(
          Rect.fromLTWH(col * cellWidth, row * cellHeight, cellWidth, cellHeight),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) {
    return oldDelegate.matrix != matrix;
  }
}
