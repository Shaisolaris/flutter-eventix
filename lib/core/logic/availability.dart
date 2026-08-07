/// Pure seat-availability math for a [TicketTier]. Nothing here depends on
/// Flutter or any provider/repository - every function takes a [TicketTier]
/// (or a list of them) and returns a plain value, so the whole module can be
/// unit tested directly.
import '../models/ticket_tier.dart';

/// How many tickets are still unsold in [tier].
int remainingForTier(TicketTier tier) => tier.totalQuantity - tier.soldQuantity;

/// Whether every ticket in [tier] has already been sold.
bool isSoldOut(TicketTier tier) => remainingForTier(tier) <= 0;

/// Whether [tier] still has tickets, but at or below [threshold] of them -
/// used to show an "Only N left" style warning instead of the plain
/// remaining count.
bool isLowStock(TicketTier tier, {int threshold = 10}) {
  final remaining = remainingForTier(tier);
  return remaining > 0 && remaining <= threshold;
}

/// The largest quantity a single order may request from [tier]: capped by
/// both how many seats remain and the tier's own [TicketTier.maxPerOrder].
/// Zero once [tier] is sold out.
int maxPurchasableForTier(TicketTier tier) {
  final remaining = remainingForTier(tier);
  if (remaining <= 0) return 0;
  return remaining < tier.maxPerOrder ? remaining : tier.maxPerOrder;
}

/// Whether an order for [quantity] tickets from [tier] can be fulfilled.
bool canPurchase(TicketTier tier, int quantity) {
  if (quantity <= 0) return false;
  return quantity <= maxPurchasableForTier(tier);
}

/// Whether every tier on an event is sold out - used to badge the whole
/// event (e.g. on Discover) as sold out rather than listing each tier.
/// An event with no tiers at all is treated as sold out, since there is
/// nothing left to buy.
bool isEventSoldOut(List<TicketTier> tiers) {
  if (tiers.isEmpty) return true;
  return tiers.every(isSoldOut);
}

/// The lowest tier price still available for purchase - used for
/// Discover's "From $X" label. Falls back to the lowest price across every
/// tier (including sold-out ones) once the whole event is sold out, so the
/// price shown never disappears once sales start.
///
/// Throws an [ArgumentError] if [tiers] is empty.
double startingPriceForTiers(List<TicketTier> tiers) {
  if (tiers.isEmpty) {
    throw ArgumentError('an event needs at least one ticket tier to price it');
  }
  final available = tiers.where((tier) => !isSoldOut(tier)).toList();
  final pool = available.isNotEmpty ? available : tiers;
  return pool.map((tier) => tier.price).reduce((a, b) => a < b ? a : b);
}
