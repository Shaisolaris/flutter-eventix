/// User-configurable app preferences.
///
/// Kept as plain booleans (no Flutter dependency) so this stays trivially
/// JSON-serializable and unit-testable like every other model in `core/`.
/// [showSoldOutEvents] is the one setting with a visible effect elsewhere in
/// the app - turning it off filters sold-out events out of Discover's feed
/// - while [eventReminders] and [newEventAlerts] describe notification
/// behavior Eventix has no backend to actually send, the same way a real
/// client app's notification toggles would be no-ops without a server
/// behind them.
class EventixSettings {
  const EventixSettings({
    required this.eventReminders,
    required this.newEventAlerts,
    required this.showSoldOutEvents,
  });

  /// Whether a reminder would be sent the day before an event this device
  /// holds tickets to.
  final bool eventReminders;

  /// Whether alerts would be sent for newly listed events.
  final bool newEventAlerts;

  /// Whether sold-out events remain visible (grayed, badged) on Discover.
  /// When false, Discover's feed filters them out entirely.
  final bool showSoldOutEvents;

  factory EventixSettings.defaults() {
    return const EventixSettings(
      eventReminders: true,
      newEventAlerts: true,
      showSoldOutEvents: true,
    );
  }

  EventixSettings copyWith({
    bool? eventReminders,
    bool? newEventAlerts,
    bool? showSoldOutEvents,
  }) {
    return EventixSettings(
      eventReminders: eventReminders ?? this.eventReminders,
      newEventAlerts: newEventAlerts ?? this.newEventAlerts,
      showSoldOutEvents: showSoldOutEvents ?? this.showSoldOutEvents,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eventReminders': eventReminders,
      'newEventAlerts': newEventAlerts,
      'showSoldOutEvents': showSoldOutEvents,
    };
  }

  factory EventixSettings.fromJson(Map<String, dynamic> json) {
    return EventixSettings(
      eventReminders: json['eventReminders'] as bool,
      newEventAlerts: json['newEventAlerts'] as bool,
      showSoldOutEvents: json['showSoldOutEvents'] as bool,
    );
  }
}
