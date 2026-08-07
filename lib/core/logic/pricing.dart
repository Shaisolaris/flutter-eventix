/// Pure order-total math for an Eventix ticket purchase. Nothing here
/// depends on Flutter, [Event]/[TicketTier], or any other layer of the app -
/// every input is a plain number or the small [TierSelection] value type
/// declared below, so the whole module can be unit tested directly.
///
/// An order's total is built up in a fixed order that mirrors how the
/// Event detail screen displays the breakdown:
///
///   1. `subtotal` - the sum of every selected tier's `unitPrice * quantity`
///   2. `+ bookingFee` - Eventix's booking fee, a percentage of the subtotal
///   3. `+ tax` - a percentage applied to subtotal + booking fee (tax is
///      remitted on the full amount the buyer pays)
///
/// Every currency amount is rounded to the nearest cent at the point it is
/// produced (see [roundToCents]), so the pieces always sum exactly to
/// [OrderBreakdown.total] with no floating-point penny drift.

/// One tier's contribution to an order before pricing is applied: how many
/// of [tierId] were requested, and at what price each.
class TierSelection {
  const TierSelection({
    required this.tierId,
    required this.unitPrice,
    required this.quantity,
  });

  final String tierId;
  final double unitPrice;
  final int quantity;

  @override
  String toString() => 'TierSelection($tierId, unitPrice: $unitPrice, quantity: $quantity)';
}

/// One priced line in an [OrderBreakdown], ready to render as a row.
class OrderLine {
  const OrderLine({
    required this.tierId,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final String tierId;
  final double unitPrice;
  final int quantity;

  /// `unitPrice * quantity`, rounded to the nearest cent.
  final double lineTotal;
}

/// The itemized cost of a ticket order, ready to render line-by-line.
class OrderBreakdown {
  const OrderBreakdown({
    required this.lines,
    required this.ticketCount,
    required this.subtotal,
    required this.bookingFee,
    required this.tax,
    required this.total,
  });

  final List<OrderLine> lines;

  /// Total number of individual tickets across every line (sum of
  /// quantities), used for e.g. "4 tickets" summary text.
  final int ticketCount;

  /// Sum of every line's [OrderLine.lineTotal].
  final double subtotal;
  final double bookingFee;
  final double tax;

  /// `subtotal + bookingFee + tax`.
  final double total;

  @override
  String toString() {
    return 'OrderBreakdown(tickets: $ticketCount, subtotal: $subtotal, bookingFee: $bookingFee, '
        'tax: $tax, total: $total)';
  }
}

/// Rounds a currency amount to the nearest cent (two decimal places).
///
/// Chained floating-point arithmetic (e.g. `43.5 * 0.08`) can land a hair
/// off an exact cent value; rounding at every step - rather than only at
/// the very end - is what guarantees the itemized lines always sum exactly
/// to the total.
double roundToCents(double amount) => (amount * 100).round() / 100;

/// Computes the full price breakdown for an order made up of one or more
/// [selections].
///
/// Selections with a `quantity` of exactly 0 are dropped silently (that's
/// simply a tier the buyer didn't add anything of); everything else is
/// validated. Throws an [ArgumentError] if, after dropping zero-quantity
/// selections, none remain, if any remaining quantity or price is negative,
/// or if either rate is negative.
OrderBreakdown calculateOrderTotal({
  required List<TierSelection> selections,
  required double bookingFeeRate,
  required double taxRate,
}) {
  if (bookingFeeRate < 0 || taxRate < 0) {
    throw ArgumentError('bookingFeeRate and taxRate must not be negative');
  }

  final activeSelections = <TierSelection>[];
  for (final selection in selections) {
    if (selection.quantity < 0) {
      throw ArgumentError.value(selection.quantity, 'quantity', 'must not be negative');
    }
    if (selection.unitPrice < 0) {
      throw ArgumentError.value(selection.unitPrice, 'unitPrice', 'must not be negative');
    }
    if (selection.quantity > 0) {
      activeSelections.add(selection);
    }
  }

  if (activeSelections.isEmpty) {
    throw ArgumentError('at least one ticket must be selected to price an order');
  }

  final lines = <OrderLine>[];
  double subtotal = 0;
  var ticketCount = 0;
  for (final selection in activeSelections) {
    final lineTotal = roundToCents(selection.unitPrice * selection.quantity);
    lines.add(OrderLine(
      tierId: selection.tierId,
      unitPrice: selection.unitPrice,
      quantity: selection.quantity,
      lineTotal: lineTotal,
    ));
    subtotal = roundToCents(subtotal + lineTotal);
    ticketCount += selection.quantity;
  }

  final bookingFee = roundToCents(subtotal * bookingFeeRate);
  final taxableAmount = subtotal + bookingFee;
  final tax = roundToCents(taxableAmount * taxRate);
  final total = roundToCents(subtotal + bookingFee + tax);

  return OrderBreakdown(
    lines: lines,
    ticketCount: ticketCount,
    subtotal: subtotal,
    bookingFee: bookingFee,
    tax: tax,
    total: total,
  );
}
