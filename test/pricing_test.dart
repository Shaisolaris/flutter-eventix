import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_eventix/core/logic/pricing.dart';

/// Every expected value below was hand-traced against the formula in
/// pricing.dart before being written down:
///
///   lineTotal   = round(unitPrice * quantity)      // one line per tier
///   subtotal    = round(sum of every lineTotal)
///   bookingFee  = round(subtotal * bookingFeeRate)
///   taxable     = subtotal + bookingFee
///   tax         = round(taxable * taxRate)
///   total       = round(subtotal + bookingFee + tax)
///
/// Every fixture below was deliberately chosen so no intermediate rounding
/// step lands on an exact half-cent (x.xx5) boundary, which keeps the
/// expected values unambiguous regardless of tiny binary floating-point
/// representation error.
void main() {
  group('calculateOrderTotal - single tier', () {
    test('one tier, multiple tickets', () {
      // lineTotal = 59 * 3 = 177.00
      // subtotal  = 177.00
      // bookingFee = 177 * 0.12 = 21.24
      // taxable   = 177 + 21.24 = 198.24
      // tax       = 198.24 * 0.0825 = 16.3548 -> 16.35
      // total     = 177 + 21.24 + 16.35 = 214.59
      final breakdown = calculateOrderTotal(
        selections: const [TierSelection(tierId: 'ga', unitPrice: 59.0, quantity: 3)],
        bookingFeeRate: 0.12,
        taxRate: 0.0825,
      );

      expect(breakdown.lines, hasLength(1));
      expect(breakdown.lines.single.tierId, 'ga');
      expect(breakdown.lines.single.unitPrice, 59.0);
      expect(breakdown.lines.single.quantity, 3);
      expect(breakdown.lines.single.lineTotal, 177.0);
      expect(breakdown.ticketCount, 3);
      expect(breakdown.subtotal, 177.0);
      expect(breakdown.bookingFee, 21.24);
      expect(breakdown.tax, 16.35);
      expect(breakdown.total, 214.59);
    });
  });

  group('calculateOrderTotal - multiple tiers (mirrors a festival-style order)', () {
    test('General Admission x2 plus Reserved Pit x1', () {
      // line1 = 59 * 2 = 118.00; line2 = 129 * 1 = 129.00
      // subtotal = 118 + 129 = 247.00
      // bookingFee = 247 * 0.12 = 29.64
      // taxable = 247 + 29.64 = 276.64
      // tax = 276.64 * 0.0825 = 22.8228 -> 22.82
      // total = 247 + 29.64 + 22.82 = 299.46
      final breakdown = calculateOrderTotal(
        selections: const [
          TierSelection(tierId: 'ga', unitPrice: 59.0, quantity: 2),
          TierSelection(tierId: 'pit', unitPrice: 129.0, quantity: 1),
        ],
        bookingFeeRate: 0.12,
        taxRate: 0.0825,
      );

      expect(breakdown.lines, hasLength(2));
      expect(breakdown.ticketCount, 3);
      expect(breakdown.subtotal, 247.0);
      expect(breakdown.bookingFee, 29.64);
      expect(breakdown.tax, 22.82);
      expect(breakdown.total, 299.46);
    });

    test('two higher-priced tiers with a different fee and tax rate', () {
      // subtotal = 349 + 549 = 898.00
      // bookingFee = 898 * 0.08 = 71.84
      // taxable = 898 + 71.84 = 969.84
      // tax = 969.84 * 0.101 = 97.95384 -> 97.95
      // total = 898 + 71.84 + 97.95 = 1067.79
      final breakdown = calculateOrderTotal(
        selections: const [
          TierSelection(tierId: 'standard', unitPrice: 349.0, quantity: 1),
          TierSelection(tierId: 'workshop', unitPrice: 549.0, quantity: 1),
        ],
        bookingFeeRate: 0.08,
        taxRate: 0.101,
      );

      expect(breakdown.subtotal, 898.0);
      expect(breakdown.bookingFee, 71.84);
      expect(breakdown.tax, 97.95);
      expect(breakdown.total, 1067.79);
    });
  });

  group('calculateOrderTotal - zero-rate edge cases', () {
    test('zero tax rate leaves tax at zero but still applies the booking fee', () {
      // subtotal = 22 * 4 = 88.00
      // bookingFee = 88 * 0.06 = 5.28
      // tax = 0
      // total = 88 + 5.28 = 93.28
      final breakdown = calculateOrderTotal(
        selections: const [TierSelection(tierId: 'general', unitPrice: 22.0, quantity: 4)],
        bookingFeeRate: 0.06,
        taxRate: 0.0,
      );

      expect(breakdown.subtotal, 88.0);
      expect(breakdown.bookingFee, 5.28);
      expect(breakdown.tax, 0.0);
      expect(breakdown.total, 93.28);
    });

    test('zero fee and zero tax leaves total equal to subtotal', () {
      final breakdown = calculateOrderTotal(
        selections: const [TierSelection(tierId: 'x', unitPrice: 50.0, quantity: 2)],
        bookingFeeRate: 0.0,
        taxRate: 0.0,
      );

      expect(breakdown.subtotal, 100.0);
      expect(breakdown.bookingFee, 0.0);
      expect(breakdown.tax, 0.0);
      expect(breakdown.total, 100.0);
    });
  });

  group('calculateOrderTotal - zero-quantity selections', () {
    test('a zero-quantity tier is silently dropped from the breakdown', () {
      // Tier 'a' contributes nothing; only 'b' is priced.
      // subtotal = 80.00; bookingFee = 80 * 0.10 = 8.00
      // taxable = 88.00; tax = 88 * 0.05 = 4.40
      // total = 80 + 8 + 4.4 = 92.40
      final breakdown = calculateOrderTotal(
        selections: const [
          TierSelection(tierId: 'a', unitPrice: 40.0, quantity: 0),
          TierSelection(tierId: 'b', unitPrice: 80.0, quantity: 1),
        ],
        bookingFeeRate: 0.10,
        taxRate: 0.05,
      );

      expect(breakdown.lines, hasLength(1));
      expect(breakdown.lines.single.tierId, 'b');
      expect(breakdown.ticketCount, 1);
      expect(breakdown.subtotal, 80.0);
      expect(breakdown.bookingFee, 8.0);
      expect(breakdown.tax, 4.4);
      expect(breakdown.total, 92.4);
    });

    test('throws when every selection has zero quantity', () {
      expect(
        () => calculateOrderTotal(
          selections: const [TierSelection(tierId: 'a', unitPrice: 10.0, quantity: 0)],
          bookingFeeRate: 0.1,
          taxRate: 0.05,
        ),
        throwsArgumentError,
      );
    });

    test('throws when the selection list is empty', () {
      expect(
        () => calculateOrderTotal(selections: const [], bookingFeeRate: 0.1, taxRate: 0.05),
        throwsArgumentError,
      );
    });
  });

  group('calculateOrderTotal - invalid input', () {
    test('throws for a negative booking fee rate', () {
      expect(
        () => calculateOrderTotal(
          selections: const [TierSelection(tierId: 'a', unitPrice: 10.0, quantity: 1)],
          bookingFeeRate: -0.01,
          taxRate: 0.05,
        ),
        throwsArgumentError,
      );
    });

    test('throws for a negative tax rate', () {
      expect(
        () => calculateOrderTotal(
          selections: const [TierSelection(tierId: 'a', unitPrice: 10.0, quantity: 1)],
          bookingFeeRate: 0.1,
          taxRate: -0.05,
        ),
        throwsArgumentError,
      );
    });

    test('throws for a negative quantity', () {
      expect(
        () => calculateOrderTotal(
          selections: const [TierSelection(tierId: 'a', unitPrice: 10.0, quantity: -1)],
          bookingFeeRate: 0.1,
          taxRate: 0.05,
        ),
        throwsArgumentError,
      );
    });

    test('throws for a negative unit price', () {
      expect(
        () => calculateOrderTotal(
          selections: const [TierSelection(tierId: 'a', unitPrice: -5.0, quantity: 1)],
          bookingFeeRate: 0.1,
          taxRate: 0.05,
        ),
        throwsArgumentError,
      );
    });
  });

  group('roundToCents', () {
    test('rounds down when the third decimal is below 5', () {
      expect(roundToCents(19.994), 19.99);
    });

    test('rounds up when the third decimal is 5 or above', () {
      expect(roundToCents(19.996), 20.0);
    });

    test('leaves an already-exact cent value unchanged', () {
      expect(roundToCents(10.0), 10.0);
    });
  });
}
