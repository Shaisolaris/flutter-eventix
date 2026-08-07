import '../logic/availability.dart';
import 'ticket_tier.dart';

/// The four categories Eventix organizes events into. Matches the category
/// chips shown on Discover exactly - there is no "other" bucket.
enum EventCategory { music, tech, sports, arts }

extension EventCategoryLabel on EventCategory {
  /// Human-readable label used on category chips and event cards.
  String get label => switch (this) {
        EventCategory.music => 'Music',
        EventCategory.tech => 'Tech',
        EventCategory.sports => 'Sports',
        EventCategory.arts => 'Arts',
      };
}

/// A single event a person can browse and buy tickets to.
///
/// Events (and their ticket tiers) are read-only catalog data - see
/// `core/seed/seed_catalog.dart` - rebuilt fresh on every launch rather than
/// persisted; only a person's own tickets and saved events are. Cover art is
/// represented as a gradient tile with an emoji rather than a real photo,
/// since this is a self-contained demo with no network or asset pipeline.
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.category,
    required this.venueName,
    required this.city,
    required this.startsAt,
    required this.description,
    required this.highlights,
    required this.coverEmoji,
    required this.gradientIndex,
    required this.tiers,
    required this.bookingFeeRate,
    required this.taxRate,
  }) : assert(tiers.length > 0, 'an event needs at least one ticket tier');

  /// Locally-generated unique identifier.
  final String id;

  /// Short marketing title, e.g. "Neon Skyline Festival".
  final String title;

  final EventCategory category;
  final String venueName;
  final String city;

  /// When the event starts. Eventix events are single-date (no multi-day
  /// range) - a festival that runs across a weekend is still anchored to
  /// one start time, the same way a real listing would headline it.
  final DateTime startsAt;

  final String description;

  /// Short bullet points shown under the description, e.g. "Doors at 6pm"
  /// or "All ages welcome".
  final List<String> highlights;

  /// Emoji shown on the gradient cover block.
  final String coverEmoji;

  /// Index into the shared gradient palette (`core/constants/gradients.dart`)
  /// used to render this event's cover.
  final int gradientIndex;

  /// The tiers of tickets available for this event, e.g. General Admission,
  /// VIP. Always has at least one entry.
  final List<TicketTier> tiers;

  /// Eventix's booking fee, as a fraction of the order subtotal (e.g. 0.08
  /// = 8%).
  final double bookingFeeRate;

  /// Sales tax rate, as a fraction of subtotal + booking fee (e.g. 0.0825 =
  /// 8.25%). Some cities/states genuinely charge 0.
  final double taxRate;

  /// Compact "venue, city" summary used across the UI.
  String get venueLine => '$venueName, $city';

  /// The lowest available ticket price, for Discover's "From $X" label.
  double get startingPrice => startingPriceForTiers(tiers);

  /// Whether every tier is sold out.
  bool get isSoldOut => isEventSoldOut(tiers);

  /// Whether [startsAt] has already happened, compared against [now]
  /// (defaults to the current moment). Past events are kept out of
  /// Discover's feed but stay resolvable by id so an old ticket can still
  /// show its event's details.
  bool isPast({DateTime? now}) => startsAt.isBefore(now ?? DateTime.now());

  /// The mirror image of [isPast]: still ahead of (or starting at) [now].
  bool isUpcoming({DateTime? now}) => !isPast(now: now);

  @override
  String toString() => 'Event($id, $title, $venueLine, from \$$startingPrice)';
}
