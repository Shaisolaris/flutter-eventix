# Eventix

Browse events by category, watch the order total add up as you pick ticket tiers, and check out to a ticket with its own QR-style pass — Eventix is an event discovery and ticketing app built to feel like the real thing, from live seat availability down to a price breakdown that never silently drifts from what the math actually says.

**Live web preview:** https://shaisolaris.github.io/flutter-eventix/

## Why Eventix

Ticketing apps live or die on trust in two numbers: does the total actually equal every ticket tier you picked plus the fees you were shown, and does "3 left" actually mean you can't check out with a 4th. Eventix takes both seriously. Every dollar amount on screen comes from one pricing function, tested against hand-traced values down to the cent. Every quantity stepper is bounded by the same availability function that decides whether a tier shows "Only 6 left" or "Sold out." Nothing about the numbers is decorative, and nothing on a ticket - including its QR-style pass - is random: the same purchase always renders the same pass, because it's derived from the ticket's own data rather than a picture.

## Screens

**Discover** — a searchable feed of every upcoming event, filterable by category (Music, Tech, Sports, Arts) with a quick-filter chip row. Each card is a gradient cover block with an emoji, a category pill, a save-for-later heart, title, venue and city, date and time, and a "From $X" price pulled from whichever ticket tier is actually still available - or a **Sold out** badge once every tier for that event is gone.

**Event detail** — a gradient hero, the full description and a highlights list, then every ticket tier with its own price, a live "Only N left" or "Sold out" badge, and a quantity stepper capped by real remaining inventory. Selecting any ticket reveals a live, itemized order summary - each tier's line total, subtotal, booking fee, tax, and grand total - that recalculates on every tap. Get tickets hands off to a confirmation screen with an order code and a preview of each ticket's entry pass.

**My Tickets** — every ticket bought so far, split into Upcoming and Past based on its event's date. Each ticket card shows the event, tier and quantity, order code, and - past a dashed tear line - a rendered QR-style entry pass: a genuine module grid drawn by a `CustomPainter`, deterministically generated from that ticket's own payload string, with the same three corner finder squares a real QR code uses. Past tickets render dimmed.

**Profile** — every event saved from its heart button, with a one-tap way to unsave, plus a handful of real settings: event reminders and new-event alerts (notification preferences, same as any client app without a push backend behind it), and a "Show sold-out events" toggle that actually filters Discover's feed when turned off. Reset demo data restores everything to Eventix's original seeded content.

Navigation is a bottom bar across Discover / My Tickets / Profile; Event detail and the confirmation screen are pushed on top of it.

## Architecture

```
lib/
  core/
    models/       Event, TicketTier, Ticket, EventixSettings - plain data classes
    logic/        pricing.dart, availability.dart, qr_payload.dart - pure functions,
                   no Flutter imports
    constants/     gradient palette, lightweight date/time formatting
    seed/         deterministic demo catalog: 8 events, 2 seeded tickets, 2 saved events
  data/
    eventix_repository.dart   storage abstraction (interface + shared_preferences impl)
    providers.dart            Riverpod providers and controllers on top of the repository
  features/
    discover/ detail/ tickets/ profile/   one screen + one widgets file per feature
    root/                                 bottom-navigation shell
```

**The repository pattern.** `EventixRepository` is an abstract class with one concrete implementation, `SharedPreferencesEventixRepository`. Screens and controllers only ever talk to the abstraction. The event catalog is *not* part of this contract - it's read-only reference data rebuilt from `core/seed/seed_catalog.dart` on every launch - while a person's tickets, saved events, and settings genuinely are their data, seeded once on first run and persisted from then on.

**A pure logic layer.** `pricing.dart`, `availability.dart`, and `qr_payload.dart` are plain functions that take data in and return data out - no `BuildContext`, no providers, no Flutter SDK at all. That separation is what makes it possible to hand-verify every order total, every "sold out" flag, and every QR-style module grid against the underlying formula and trust the result, rather than trusting a screenshot. The widgets that use them stay thin: read state, call a pure function, render what comes back. Even the confirmation screen recomputes its total from the tickets it was just handed rather than trusting a passed-in number, so it can never drift from what checkout showed.

**Why Riverpod.** Eventix's own data - tickets, saved events, and settings - needs to be read from every screen, mutated from several of them, survive navigation between them, and load asynchronously from disk on startup. `StateNotifierProvider` + `AsyncValue` map onto that directly: `AsyncValue.loading()/.data()/.error()` mirrors "reading from shared_preferences," and the controller exposes intention-revealing methods (`purchaseTickets`, `toggleSavedEvent`, `updateSettings`) instead of a generic setter. The catalog itself is exposed through a plain `Provider`, since it never changes at runtime.

## Testing

```
test/
  pricing_test.dart      multi-tier order totals with booking fee % and tax, a
                          zero-quantity tier silently dropped from the breakdown,
                          zero-rate edge cases, and every ArgumentError path
  availability_test.dart  remaining/sold-out/low-stock math, the max-purchasable
                          quantity under both the remaining-seats cap and the
                          per-order cap, and the "from" price falling back to the
                          cheapest tier once an entire event is sold out
  qr_payload_test.dart    the ticket payload string format, the seed derived from
                          it traced by hand character-by-character, individual
                          noise-cell values computed by hand from that seed, and
                          the three finder squares' fixed positions
```

Every expected value in these three files was hand-traced against the formula in the corresponding `core/logic` file before being written down - fixtures were deliberately chosen so no rounding step lands on an ambiguous half-cent boundary, and the QR-style matrix tests trace the exact seed and modulo arithmetic for specific payloads rather than only asserting general shape. That's the payoff of keeping the logic layer pure: the suite can be this exhaustive without a widget or a `BuildContext` anywhere in it.

Run the suite with:

```
flutter test
```

## Run it

```
flutter pub get
flutter run
```

To build the web version the same way CI does:

```
flutter build web --base-href /flutter-eventix/
```

## Tech

- Flutter 3.24+, null-safe Dart, Material 3 (light + dark, seeded from `#7C3AED`)
- State management: `flutter_riverpod`
- Persistence: `shared_preferences`, storing tickets, saved events, and settings as JSON
- CI: GitHub Actions runs `flutter analyze` and `flutter test` on every push, then builds and deploys the web app to GitHub Pages

## License

MIT © 2026 Shai A — see [LICENSE](LICENSE).

Built by [Shai](https://github.com/shaisolaris).
