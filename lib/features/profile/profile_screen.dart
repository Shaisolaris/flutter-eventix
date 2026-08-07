import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/event.dart';
import '../../data/providers.dart';
import '../detail/detail_screen.dart';
import 'profile_widgets.dart';

/// Profile: saved events and a handful of simple settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(eventixControllerProvider);
    final events = ref.watch(eventsProvider);
    final eventsById = {for (final event in events) event.id: event};

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: userDataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load your profile.\n$error', textAlign: TextAlign.center),
            ),
          ),
          data: (data) {
            final notifier = ref.read(eventixControllerProvider.notifier);
            final savedEvents = <Event>[
              for (final id in data.savedEventIds)
                if (eventsById[id] != null) eventsById[id]!,
            ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const ProfileHeader(),
                const SizedBox(height: 28),
                SectionLabel('Saved events (${savedEvents.length})'),
                if (savedEvents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Tap the heart on an event to save it for later.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  for (final event in savedEvents)
                    SavedEventTile(
                      event: event,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => EventDetailScreen(eventId: event.id)),
                      ),
                      onRemove: () => notifier.toggleSavedEvent(event.id),
                    ),
                const SizedBox(height: 18),
                const SectionLabel('Notifications'),
                SettingsToggleTile(
                  icon: Icons.notifications_none,
                  title: 'Event reminders',
                  subtitle: 'Get notified the day before an event you have tickets to',
                  value: data.settings.eventReminders,
                  onChanged: (value) =>
                      notifier.updateSettings(data.settings.copyWith(eventReminders: value)),
                ),
                SettingsToggleTile(
                  icon: Icons.campaign_outlined,
                  title: 'New event alerts',
                  subtitle: 'Hear about new events in your saved categories',
                  value: data.settings.newEventAlerts,
                  onChanged: (value) =>
                      notifier.updateSettings(data.settings.copyWith(newEventAlerts: value)),
                ),
                const SizedBox(height: 18),
                const SectionLabel('Discover'),
                SettingsToggleTile(
                  icon: Icons.visibility_outlined,
                  title: 'Show sold-out events',
                  subtitle: 'Keep sold-out events in the Discover feed instead of hiding them',
                  value: data.settings.showSoldOutEvents,
                  onChanged: (value) =>
                      notifier.updateSettings(data.settings.copyWith(showSoldOutEvents: value)),
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _confirmResetData(context, ref),
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset demo data'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmResetData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text(
          'Your tickets, saved events, and settings will be restored to the original Eventix demo content. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(eventixControllerProvider.notifier).resetAllData();
  }
}
