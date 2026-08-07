import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logic/pricing.dart';
import '../../core/models/event.dart';
import '../../core/models/ticket_tier.dart';
import '../../data/providers.dart';
import 'detail_widgets.dart';
import 'ticket_confirmation_screen.dart';

/// Event detail: hero, description, ticket tiers with quantity steppers, a
/// live order total, and Get tickets.
class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final Map<String, int> _quantities = <String, int>{};
  bool _isPurchasing = false;

  int _quantityFor(String tierId) => _quantities[tierId] ?? 0;

  void _setQuantity(TicketTier tier, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _quantities.remove(tier.id);
      } else {
        _quantities[tier.id] = quantity;
      }
    });
  }

  Future<void> _getTickets(Event event) async {
    if (_quantities.isEmpty || _isPurchasing) return;

    setState(() => _isPurchasing = true);
    try {
      final tickets = await ref.read(eventixControllerProvider.notifier).purchaseTickets(
            event: event,
            quantitiesByTierId: _quantities,
          );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TicketConfirmationScreen(event: event, tickets: tickets),
        ),
      );
      if (!mounted) return;
      setState(() => _quantities.clear());
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventByIdProvider(widget.eventId));

    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This event is no longer available.')),
      );
    }

    final userDataAsync = ref.watch(eventixControllerProvider);
    final isSaved = userDataAsync.value?.isSaved(event.id) ?? false;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final selections = <TierSelection>[
      for (final tier in event.tiers)
        if (_quantityFor(tier.id) > 0)
          TierSelection(tierId: tier.id, unitPrice: tier.price, quantity: _quantityFor(tier.id)),
    ];
    final breakdown = selections.isEmpty
        ? null
        : calculateOrderTotal(
            selections: selections,
            bookingFeeRate: event.bookingFeeRate,
            taxRate: event.taxRate,
          );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            EventHeroHeader(
              event: event,
              isSaved: isSaved,
              onToggleSaved: () => ref.read(eventixControllerProvider.notifier).toggleSavedEvent(event.id),
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EventOverview(event: event),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('About this event', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text(event.description, style: textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  EventHighlightsList(highlights: event.highlights),
                  const SizedBox(height: 20),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  const SizedBox(height: 20),
                  Text('Tickets', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  for (final tier in event.tiers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TicketTierSelector(
                        tier: tier,
                        quantity: _quantityFor(tier.id),
                        onChanged: (quantity) => _setQuantity(tier, quantity),
                      ),
                    ),
                  if (breakdown != null) ...[
                    const SizedBox(height: 8),
                    Divider(height: 1, color: colorScheme.outlineVariant),
                    const SizedBox(height: 20),
                    OrderSummaryCard(breakdown: breakdown, tiers: event.tiers),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GetTicketsBar(
        breakdown: breakdown,
        isBusy: _isPurchasing,
        onGetTickets: selections.isEmpty ? null : () => _getTickets(event),
      ),
    );
  }
}
