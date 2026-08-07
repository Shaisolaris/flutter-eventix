import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/event.dart';
import '../../core/models/ticket.dart';
import '../../data/providers.dart';
import 'tickets_widgets.dart';

/// My Tickets: every ticket the person has bought, split into Upcoming and
/// Past based on the event it belongs to.
class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(eventixControllerProvider);
    final events = ref.watch(eventsProvider);
    final Map<String, Event> eventsById = {for (final event in events) event.id: event};

    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: SafeArea(
        child: userDataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load your tickets.\n$error', textAlign: TextAlign.center),
            ),
          ),
          data: (data) {
            if (data.tickets.isEmpty) {
              return const TicketsEmptyState();
            }

            final upcoming = <Ticket>[];
            final past = <Ticket>[];
            for (final ticket in data.tickets) {
              final isPast = eventsById[ticket.eventId]?.isPast() ?? false;
              (isPast ? past : upcoming).add(ticket);
            }

            int compareByEventDate(Ticket a, Ticket b, {required bool ascending}) {
              final dateA = eventsById[a.eventId]?.startsAt;
              final dateB = eventsById[b.eventId]?.startsAt;
              if (dateA == null || dateB == null) return 0;
              return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
            }

            upcoming.sort((a, b) => compareByEventDate(a, b, ascending: true));
            past.sort((a, b) => compareByEventDate(a, b, ascending: false));

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (upcoming.isNotEmpty) ...[
                  const TicketsSectionHeader(title: 'Upcoming'),
                  for (final ticket in upcoming)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: TicketCard(ticket: ticket, event: eventsById[ticket.eventId]),
                    ),
                ],
                if (past.isNotEmpty) ...[
                  const TicketsSectionHeader(title: 'Past'),
                  for (final ticket in past)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: TicketCard(ticket: ticket, event: eventsById[ticket.eventId], isPast: true),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
