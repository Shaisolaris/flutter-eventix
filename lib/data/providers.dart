import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/event.dart';
import '../core/models/eventix_settings.dart';
import '../core/models/ticket.dart';
import '../core/seed/seed_catalog.dart';
import 'eventix_repository.dart';

/// Provided a real value in `main()` once [SharedPreferences.getInstance]
/// has resolved; never read before then.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden before use.');
});

/// Which bottom-nav tab is showing on [RootShell]. Exposed as a provider
/// (rather than local widget state) so a pushed screen - e.g. the ticket
/// confirmation screen - can jump straight to the My Tickets tab when it
/// pops back to the root.
final rootTabIndexProvider = StateProvider<int>((ref) => 0);

final eventixRepositoryProvider = Provider<EventixRepository>((ref) {
  return SharedPreferencesEventixRepository(ref.watch(sharedPreferencesProvider));
});

/// Read-only catalog data. Rebuilt once per provider container rather than
/// persisted - see `core/seed/seed_catalog.dart`.
final eventsProvider = Provider<List<Event>>((ref) => buildSeedEvents());

/// Looks up a single event by id, or `null` if it doesn't exist (e.g. a
/// stale saved-event entry). `Provider.family` caches one provider
/// instance per `id`.
final eventByIdProvider = Provider.family<Event?, String>((ref, id) {
  final events = ref.watch(eventsProvider);
  for (final event in events) {
    if (event.id == id) return event;
  }
  return null;
});

/// A person's own data: their tickets, saved events, and settings. Unlike
/// the catalog above, this is loaded from (and written back to) persistent
/// storage.
class EventixUserData {
  const EventixUserData({
    required this.tickets,
    required this.savedEventIds,
    required this.settings,
  });

  final List<Ticket> tickets;
  final Set<String> savedEventIds;
  final EventixSettings settings;

  bool isSaved(String eventId) => savedEventIds.contains(eventId);

  EventixUserData copyWith({
    List<Ticket>? tickets,
    Set<String>? savedEventIds,
    EventixSettings? settings,
  }) {
    return EventixUserData(
      tickets: tickets ?? this.tickets,
      savedEventIds: savedEventIds ?? this.savedEventIds,
      settings: settings ?? this.settings,
    );
  }
}

/// Owns ticket, saved-event, and settings state: loads it on startup
/// (seeding demo content on a genuine first run), and applies every
/// mutation to both in-memory state and persistent storage together so
/// they can never drift apart.
class EventixController extends StateNotifier<AsyncValue<EventixUserData>> {
  EventixController(this._repository, this._events) : super(const AsyncValue.loading()) {
    _initialize();
  }

  final EventixRepository _repository;
  final List<Event> _events;
  final Random _random = Random();

  Future<void> _initialize() async {
    try {
      final seededBefore = await _repository.hasSeededBefore();
      if (!seededBefore) {
        final seededData = await _seedFreshData();
        state = AsyncValue.data(seededData);
        return;
      }

      final tickets = await _repository.loadTickets();
      final savedEventIds = await _repository.loadSavedEventIds();
      final settings = await _repository.loadSettings();
      state = AsyncValue.data(
        EventixUserData(tickets: tickets, savedEventIds: savedEventIds, settings: settings),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<EventixUserData> _seedFreshData() async {
    final seededTickets = buildSeedTickets(_events);
    final seededSavedEventIds = buildSeedSavedEventIds();
    final seededSettings = EventixSettings.defaults();
    await _repository.saveTickets(seededTickets);
    await _repository.saveSavedEventIds(seededSavedEventIds);
    await _repository.saveSettings(seededSettings);
    await _repository.markSeeded();
    return EventixUserData(
      tickets: seededTickets,
      savedEventIds: seededSavedEventIds,
      settings: seededSettings,
    );
  }

  /// Buys tickets for [event]: one [Ticket] per tier with a quantity
  /// greater than zero in [quantitiesByTierId] (tier id -> quantity), all
  /// sharing one generated order code - mirroring how a real ticketing app
  /// issues one scannable pass per admission type per order. Returns the
  /// newly created tickets so the caller can show them on a confirmation
  /// screen.
  ///
  /// Throws a [StateError] if called before Eventix has finished loading,
  /// or an [ArgumentError] if every quantity is zero.
  Future<List<Ticket>> purchaseTickets({
    required Event event,
    required Map<String, int> quantitiesByTierId,
  }) async {
    final current = state.value;
    if (current == null) {
      throw StateError('Cannot purchase before Eventix has finished loading.');
    }

    final orderCode = _generateOrderCode();
    final purchasedAt = DateTime.now();
    final newTickets = <Ticket>[];
    for (final tier in event.tiers) {
      final quantity = quantitiesByTierId[tier.id] ?? 0;
      if (quantity <= 0) continue;
      newTickets.add(
        Ticket(
          id: 'ticket-${purchasedAt.microsecondsSinceEpoch}-${tier.id}',
          eventId: event.id,
          tierId: tier.id,
          tierName: tier.name,
          quantity: quantity,
          unitPriceAtPurchase: tier.price,
          purchasedAt: purchasedAt,
          orderCode: orderCode,
        ),
      );
    }

    if (newTickets.isEmpty) {
      throw ArgumentError('at least one ticket tier must have a quantity greater than zero');
    }

    final updatedTickets = List<Ticket>.from(current.tickets)..addAll(newTickets);
    state = AsyncValue.data(current.copyWith(tickets: updatedTickets));
    await _repository.saveTickets(updatedTickets);
    return newTickets;
  }

  /// Adds [eventId] to the saved list if it isn't already saved, or
  /// removes it if it is.
  Future<void> toggleSavedEvent(String eventId) async {
    final current = state.value;
    if (current == null) return;

    final updatedIds = Set<String>.from(current.savedEventIds);
    if (!updatedIds.remove(eventId)) {
      updatedIds.add(eventId);
    }

    state = AsyncValue.data(current.copyWith(savedEventIds: updatedIds));
    await _repository.saveSavedEventIds(updatedIds);
  }

  Future<void> updateSettings(EventixSettings settings) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(settings: settings));
    await _repository.saveSettings(settings);
  }

  /// Restores tickets, saved events, and settings to the original seeded
  /// demo content.
  Future<void> resetAllData() async {
    await _repository.resetEventixData();
    final seededData = await _seedFreshData();
    state = AsyncValue.data(seededData);
  }

  static const String _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I

  String _generateOrderCode() {
    final code = List<String>.generate(6, (_) => _codeChars[_random.nextInt(_codeChars.length)]).join();
    return 'EVX-$code';
  }
}

final eventixControllerProvider = StateNotifierProvider<EventixController, AsyncValue<EventixUserData>>((ref) {
  return EventixController(ref.watch(eventixRepositoryProvider), ref.watch(eventsProvider));
});
