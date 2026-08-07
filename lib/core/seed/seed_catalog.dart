import '../models/event.dart';
import '../models/ticket.dart';
import '../models/ticket_tier.dart';

/// Eventix's deterministic demo catalog: 8 events spread across all four
/// categories, plus the 2 tickets and 2 saved events shown the first time
/// the app runs.
///
/// Events (and their ticket tiers) are treated as read-only reference data
/// - rebuilt from these functions on every launch rather than persisted.
/// A person's own tickets and saved events genuinely are their data: seeded
/// once on first run, then persisted and mutated from there (see
/// `data/eventix_repository.dart`).
///
/// Event start times are expressed as offsets from [now] (defaulting to
/// the current moment) rather than fixed calendar dates, so Discover always
/// has believable upcoming events no matter when the app is run - while
/// staying fully deterministic for any given [now]. One event (Sunset Jazz
/// Sessions) is deliberately given a *negative* offset so it has already
/// happened - Discover filters it out of the feed, but it still resolves
/// by id for the past ticket seeded against it.

const String eventNeonSkylineId = 'event-neon-skyline';
const String eventSunsetJazzId = 'event-sunset-jazz';
const String eventIgniteSummitId = 'event-ignite-summit';
const String eventAiRoboticsExpoId = 'event-ai-robotics-expo';
const String eventCoastalSurfClassicId = 'event-coastal-surf-classic';
const String eventDowntownHoopsShowcaseId = 'event-downtown-hoops-showcase';
const String eventModernCanvasExhibitionId = 'event-modern-canvas-exhibition';
const String eventNeoNoirFilmFestivalId = 'event-neo-noir-film-festival';

DateTime _dateOnly(DateTime dateTime) => DateTime(dateTime.year, dateTime.month, dateTime.day);

/// [today] plus [dayOffset] days, at the given [hour]:[minute].
DateTime _at(DateTime today, int dayOffset, int hour, int minute) {
  final day = today.add(Duration(days: dayOffset));
  return DateTime(day.year, day.month, day.day, hour, minute);
}

/// Builds the 8-event catalog.
List<Event> buildSeedEvents({DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());

  return [
    Event(
      id: eventNeonSkylineId,
      title: 'Neon Skyline Festival',
      category: EventCategory.music,
      venueName: 'Skyline Amphitheater',
      city: 'Austin, TX',
      startsAt: _at(today, 26, 19, 0),
      description: "Eventix's flagship outdoor festival returns to the Skyline "
          'Amphitheater for a night of headlining electronic and indie acts '
          'across two stages, with local food trucks lining the lawn until close.',
      highlights: const [
        'Gates open at 4:00 PM',
        'Two outdoor stages, no re-entry after 11:00 PM',
        '16+ event, valid photo ID required',
      ],
      coverEmoji: '🎧',
      gradientIndex: 0,
      tiers: [
        const TicketTier(
          id: '$eventNeonSkylineId-ga',
          name: 'General Admission Lawn',
          description: 'Open lawn seating, first come first served',
          price: 59.0,
          totalQuantity: 2000,
          soldQuantity: 1450,
          maxPerOrder: 8,
        ),
        const TicketTier(
          id: '$eventNeonSkylineId-pit',
          name: 'Reserved Pit',
          description: 'Standing room closest to the main stage',
          price: 129.0,
          totalQuantity: 400,
          soldQuantity: 391,
          maxPerOrder: 6,
        ),
        const TicketTier(
          id: '$eventNeonSkylineId-vip',
          name: 'VIP Skyline Pass',
          description: 'Elevated viewing deck, private bar, and a festival tote',
          price: 249.0,
          totalQuantity: 120,
          soldQuantity: 120,
          maxPerOrder: 4,
        ),
      ],
      bookingFeeRate: 0.12,
      taxRate: 0.0825,
    ),
    Event(
      id: eventSunsetJazzId,
      title: 'Sunset Jazz Sessions',
      category: EventCategory.music,
      venueName: 'Bluewater Jazz Club',
      city: 'New Orleans, LA',
      startsAt: _at(today, -22, 20, 0),
      description: "An intimate late set from the Bluewater Jazz Club's house "
          'quartet, joined by a rotating lineup of guest horn players for one '
          'set only.',
      highlights: const [
        'Doors at 7:30 PM',
        'Full dinner menu available before the set',
        '21+ venue',
      ],
      coverEmoji: '🎷',
      gradientIndex: 7,
      tiers: [
        const TicketTier(
          id: '$eventSunsetJazzId-bar',
          name: 'Bar Seating',
          description: 'First come, first served seats at the bar',
          price: 35.0,
          totalQuantity: 60,
          soldQuantity: 60,
          maxPerOrder: 4,
        ),
        const TicketTier(
          id: '$eventSunsetJazzId-table',
          name: 'Table for Two',
          description: 'A reserved two-top near the stage',
          price: 95.0,
          totalQuantity: 20,
          soldQuantity: 20,
          maxPerOrder: 2,
        ),
      ],
      bookingFeeRate: 0.10,
      taxRate: 0.05,
    ),
    Event(
      id: eventIgniteSummitId,
      title: 'Ignite Dev Summit',
      category: EventCategory.tech,
      venueName: 'Meridian Convention Center',
      city: 'Seattle, WA',
      startsAt: _at(today, 34, 9, 0),
      description: 'Three days of talks, hands-on workshops, and '
          'hallway-track networking for engineers building at scale, '
          "headlined by a keynote from a Meridian Labs infrastructure lead.",
      highlights: const [
        'Badge pickup opens 7:00 AM daily',
        'Workshops require a laptop',
        'Recorded sessions posted after the summit',
      ],
      coverEmoji: '💻',
      gradientIndex: 2,
      tiers: [
        const TicketTier(
          id: '$eventIgniteSummitId-standard',
          name: 'Standard Pass',
          description: 'Full access to keynotes and breakout talks',
          price: 349.0,
          totalQuantity: 1200,
          soldQuantity: 860,
          maxPerOrder: 8,
        ),
        const TicketTier(
          id: '$eventIgniteSummitId-workshop',
          name: 'Workshop Pass',
          description: 'Standard Pass plus every hands-on workshop',
          price: 549.0,
          totalQuantity: 300,
          soldQuantity: 291,
          maxPerOrder: 4,
        ),
        const TicketTier(
          id: '$eventIgniteSummitId-allaccess',
          name: 'All-Access Pass',
          description: 'Workshop Pass plus the speaker dinner and session archive',
          price: 899.0,
          totalQuantity: 80,
          soldQuantity: 80,
          maxPerOrder: 2,
        ),
      ],
      bookingFeeRate: 0.08,
      taxRate: 0.101,
    ),
    Event(
      id: eventAiRoboticsExpoId,
      title: 'AI & Robotics Expo',
      category: EventCategory.tech,
      venueName: 'Union Exposition Hall',
      city: 'San Jose, CA',
      startsAt: _at(today, 61, 10, 0),
      description: 'A hands-on showroom of robotics startups and research '
          'labs demoing autonomous hardware, capped by an evening keynote on '
          'applied machine learning.',
      highlights: const [
        'Live robotics demos every hour',
        'Career fair on the expo floor',
        'Free shuttle from downtown San Jose',
      ],
      coverEmoji: '🤖',
      gradientIndex: 3,
      tiers: [
        const TicketTier(
          id: '$eventAiRoboticsExpoId-floor',
          name: 'Expo Floor Pass',
          description: 'Full-day access to the show floor and live demos',
          price: 89.0,
          totalQuantity: 3000,
          soldQuantity: 1120,
          maxPerOrder: 8,
        ),
        const TicketTier(
          id: '$eventAiRoboticsExpoId-innovator',
          name: 'Innovator Pass',
          description: 'Expo Floor Pass plus the evening keynote and reception',
          price: 219.0,
          totalQuantity: 500,
          soldQuantity: 245,
          maxPerOrder: 6,
        ),
      ],
      bookingFeeRate: 0.09,
      taxRate: 0.09375,
    ),
    Event(
      id: eventCoastalSurfClassicId,
      title: 'Coastal Surf Classic',
      category: EventCategory.sports,
      venueName: 'Pier Point Beach',
      city: 'San Diego, CA',
      startsAt: _at(today, 12, 7, 0),
      description: "Pro and amateur heats run back to back along Pier Point "
          "Beach for the Classic's twelfth year, with a beachside vendor "
          'village open all weekend.',
      highlights: const [
        'Heats begin at 7:00 AM with the tide',
        'Beach chairs and canopies allowed past the flags',
        'Free entry for kids under 6',
      ],
      coverEmoji: '🏄',
      gradientIndex: 5,
      tiers: [
        const TicketTier(
          id: '$eventCoastalSurfClassicId-general',
          name: 'General Beach Access',
          description: 'Beach entry and standing viewing along the flagged course',
          price: 25.0,
          totalQuantity: 5000,
          soldQuantity: 2300,
          maxPerOrder: 10,
        ),
        const TicketTier(
          id: '$eventCoastalSurfClassicId-grandstand',
          name: 'Grandstand Seating',
          description: 'A reserved bleacher seat facing the main break',
          price: 75.0,
          totalQuantity: 600,
          soldQuantity: 591,
          maxPerOrder: 6,
        ),
      ],
      bookingFeeRate: 0.07,
      taxRate: 0.0775,
    ),
    Event(
      id: eventDowntownHoopsShowcaseId,
      title: 'Downtown Hoops Showcase',
      category: EventCategory.sports,
      venueName: 'Ironside Arena',
      city: 'Chicago, IL',
      startsAt: _at(today, 45, 18, 30),
      description: 'Four regional college teams face off in a single-night '
          'showcase at Ironside Arena, capped by a halftime dunk contest.',
      highlights: const [
        'Doors open 90 minutes before tip-off',
        'Team gear giveaways at the gates',
        'Ironside Arena is cashless entry only',
      ],
      coverEmoji: '🏀',
      gradientIndex: 1,
      tiers: [
        const TicketTier(
          id: '$eventDowntownHoopsShowcaseId-upper',
          name: 'Upper Bowl',
          description: 'Upper-level seating, any section',
          price: 45.0,
          totalQuantity: 4000,
          soldQuantity: 4000,
          maxPerOrder: 8,
        ),
        const TicketTier(
          id: '$eventDowntownHoopsShowcaseId-lower',
          name: 'Lower Bowl',
          description: 'Lower-level reserved seating',
          price: 110.0,
          totalQuantity: 1200,
          soldQuantity: 1200,
          maxPerOrder: 6,
        ),
        const TicketTier(
          id: '$eventDowntownHoopsShowcaseId-courtside',
          name: 'Courtside',
          description: 'Courtside seat with pregame warm-up access',
          price: 650.0,
          totalQuantity: 40,
          soldQuantity: 40,
          maxPerOrder: 2,
        ),
      ],
      bookingFeeRate: 0.10,
      taxRate: 0.1025,
    ),
    Event(
      id: eventModernCanvasExhibitionId,
      title: 'Modern Canvas Exhibition',
      category: EventCategory.arts,
      venueName: 'Halcyon Gallery',
      city: 'Portland, OR',
      startsAt: _at(today, 8, 18, 0),
      description: "Halcyon Gallery's season opener surveys a dozen emerging "
          'painters working in bold color fields, with the artists on hand '
          'for opening night.',
      highlights: const [
        'Opening night includes a reception with the artists',
        'Gallery talks run every Saturday at noon',
        'Free entry for gallery members',
      ],
      coverEmoji: '🎨',
      gradientIndex: 6,
      tiers: [
        const TicketTier(
          id: '$eventModernCanvasExhibitionId-general',
          name: 'General Entry',
          description: 'Self-guided entry any day of the run',
          price: 22.0,
          totalQuantity: 800,
          soldQuantity: 410,
          maxPerOrder: 8,
        ),
        const TicketTier(
          id: '$eventModernCanvasExhibitionId-opening',
          name: 'Opening Night + Reception',
          description: 'Opening night entry plus the artist reception',
          price: 68.0,
          totalQuantity: 150,
          soldQuantity: 143,
          maxPerOrder: 4,
        ),
      ],
      bookingFeeRate: 0.06,
      taxRate: 0.0,
    ),
    Event(
      id: eventNeoNoirFilmFestivalId,
      title: 'Neo Noir Film Festival',
      category: EventCategory.arts,
      venueName: 'Cascade Theatre',
      city: 'Denver, CO',
      startsAt: _at(today, 52, 19, 30),
      description: 'A week of restored prints and new independent features at '
          "the Cascade Theatre, closing with a director Q&A after opening "
          "weekend's breakout film.",
      highlights: const [
        'Festival Pass includes every screening',
        'Q&A seating is first come, first served',
        'Concessions support the Cascade Theatre restoration fund',
      ],
      coverEmoji: '🎬',
      gradientIndex: 4,
      tiers: [
        const TicketTier(
          id: '$eventNeoNoirFilmFestivalId-single',
          name: 'Single Screening',
          description: 'Entry to one screening of your choice',
          price: 16.0,
          totalQuantity: 1000,
          soldQuantity: 512,
          maxPerOrder: 8,
        ),
        const TicketTier(
          id: '$eventNeoNoirFilmFestivalId-pass',
          name: 'Festival Pass',
          description: 'Entry to every screening plus the closing Q&A',
          price: 85.0,
          totalQuantity: 250,
          soldQuantity: 244,
          maxPerOrder: 4,
        ),
      ],
      bookingFeeRate: 0.05,
      taxRate: 0.0481,
    ),
  ];
}

/// Builds the 2 tickets shown on My Tickets the very first time the app
/// runs: one for an upcoming event, one for an event that has already
/// happened - so both sections of the screen have something to show
/// immediately. Tier price and name are read from [events] rather than
/// hand-typed, so a seeded ticket's receipt can never drift out of sync
/// with the catalog it was "purchased" from.
List<Ticket> buildSeedTickets(List<Event> events, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final eventsById = {for (final event in events) event.id: event};

  TicketTier tierById(Event event, String tierId) {
    return event.tiers.firstWhere((tier) => tier.id == tierId);
  }

  final skyline = eventsById[eventNeonSkylineId]!;
  final skylinePit = tierById(skyline, '$eventNeonSkylineId-pit');

  final jazz = eventsById[eventSunsetJazzId]!;
  final jazzTable = tierById(jazz, '$eventSunsetJazzId-table');

  return [
    Ticket(
      id: 'ticket-seed-upcoming-skyline',
      eventId: skyline.id,
      tierId: skylinePit.id,
      tierName: skylinePit.name,
      quantity: 2,
      unitPriceAtPurchase: skylinePit.price,
      purchasedAt: current.subtract(const Duration(days: 9)),
      orderCode: 'EVX-7QPM2K',
    ),
    Ticket(
      id: 'ticket-seed-past-jazz',
      eventId: jazz.id,
      tierId: jazzTable.id,
      tierName: jazzTable.name,
      quantity: 1,
      unitPriceAtPurchase: jazzTable.price,
      purchasedAt: current.subtract(const Duration(days: 30)),
      orderCode: 'EVX-3LWK9B',
    ),
  ];
}

/// Event ids saved to the profile the first time the app runs.
Set<String> buildSeedSavedEventIds() {
  return const <String>{eventAiRoboticsExpoId, eventCoastalSurfClassicId};
}
