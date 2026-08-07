import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/eventix_settings.dart';
import '../core/models/ticket.dart';

/// Persistence contract for everything Eventix stores locally: a person's
/// tickets, their saved events, and their settings.
///
/// Kept as an abstraction - rather than calling `shared_preferences`
/// directly from widgets or controllers - so the state layer can be unit
/// tested against a real (but in-memory-backed) implementation, and so the
/// storage backend could be swapped later without touching feature code.
/// The event catalog is not part of this contract: it is read-only
/// reference data rebuilt from `core/seed/seed_catalog.dart` on every
/// launch.
abstract class EventixRepository {
  Future<List<Ticket>> loadTickets();
  Future<void> saveTickets(List<Ticket> tickets);

  Future<Set<String>> loadSavedEventIds();
  Future<void> saveSavedEventIds(Set<String> eventIds);

  Future<EventixSettings> loadSettings();
  Future<void> saveSettings(EventixSettings settings);

  /// Whether the demo tickets/saved events/settings have already been
  /// generated once before. Used to tell "first launch ever" apart from "a
  /// person cleared their tickets," which should stay empty rather than
  /// being re-seeded.
  Future<bool> hasSeededBefore();
  Future<void> markSeeded();

  /// Clears every key this repository owns, so the next read starts from a
  /// genuinely empty state. Used by "Reset demo data" on Profile.
  Future<void> resetEventixData();
}

/// [EventixRepository] implementation backed by [SharedPreferences]. Every
/// value is stored as a JSON-encoded string (or, for the saved-event id
/// set, [SharedPreferences]'s native string-list support).
class SharedPreferencesEventixRepository implements EventixRepository {
  SharedPreferencesEventixRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String ticketsKey = 'eventix.tickets.v1';
  static const String savedEventIdsKey = 'eventix.saved_events.v1';
  static const String settingsKey = 'eventix.settings.v1';
  static const String seededKey = 'eventix.seeded.v1';

  @override
  Future<List<Ticket>> loadTickets() async {
    final raw = _prefs.getString(ticketsKey);
    if (raw == null || raw.isEmpty) return <Ticket>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((dynamic item) => Ticket.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveTickets(List<Ticket> tickets) async {
    final raw = jsonEncode(tickets.map((ticket) => ticket.toJson()).toList());
    await _prefs.setString(ticketsKey, raw);
  }

  @override
  Future<Set<String>> loadSavedEventIds() async {
    final stored = _prefs.getStringList(savedEventIdsKey);
    if (stored == null) return <String>{};
    return stored.toSet();
  }

  @override
  Future<void> saveSavedEventIds(Set<String> eventIds) async {
    await _prefs.setStringList(savedEventIdsKey, eventIds.toList());
  }

  @override
  Future<EventixSettings> loadSettings() async {
    final raw = _prefs.getString(settingsKey);
    if (raw == null || raw.isEmpty) return EventixSettings.defaults();
    return EventixSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveSettings(EventixSettings settings) async {
    await _prefs.setString(settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  Future<bool> hasSeededBefore() async {
    return _prefs.getBool(seededKey) ?? false;
  }

  @override
  Future<void> markSeeded() async {
    await _prefs.setBool(seededKey, true);
  }

  @override
  Future<void> resetEventixData() async {
    await _prefs.remove(ticketsKey);
    await _prefs.remove(savedEventIdsKey);
    await _prefs.remove(settingsKey);
    await _prefs.remove(seededKey);
  }
}
