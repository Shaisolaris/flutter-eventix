/// A single purchasable tier of tickets for an [Event] (e.g. "General
/// Admission", "VIP"). Tiers are read-only catalog data - see
/// `core/seed/seed_catalog.dart` - so [soldQuantity] reflects a fixed
/// snapshot rather than live inventory that decrements as this device buys
/// tickets (the same simplification Eventix's sibling apps make for their
/// own read-only catalogs).
class TicketTier {
  const TicketTier({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.totalQuantity,
    required this.soldQuantity,
    this.maxPerOrder = 8,
  })  : assert(totalQuantity >= 0, 'totalQuantity must not be negative'),
        assert(soldQuantity >= 0, 'soldQuantity must not be negative'),
        assert(maxPerOrder > 0, 'maxPerOrder must be positive');

  final String id;

  /// Short tier name, e.g. "General Admission", "VIP Lounge".
  final String name;

  /// One-line description of what the tier includes.
  final String description;

  /// Price per ticket, before booking fee or tax.
  final double price;

  /// Total tickets ever made available in this tier.
  final int totalQuantity;

  /// How many of [totalQuantity] have already been sold.
  final int soldQuantity;

  /// The most tickets a single order may request from this tier, separate
  /// from however many remain in inventory.
  final int maxPerOrder;

  @override
  String toString() => 'TicketTier($id, $name, \$$price, $soldQuantity/$totalQuantity sold)';
}
