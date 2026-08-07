import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/date_format.dart';
import '../../core/constants/gradients.dart';
import '../../core/logic/pricing.dart';
import '../../core/models/event.dart';
import '../../core/models/ticket.dart';
import '../../data/providers.dart';
import '../tickets/qr_style_block.dart';

/// Shown right after a successful Get tickets tap: order summary, a
/// preview of each ticket's entry pass, and a way back to Discover or
/// straight to My Tickets.
class TicketConfirmationScreen extends ConsumerWidget {
  const TicketConfirmationScreen({
    super.key,
    required this.event,
    required this.tickets,
  });

  final Event event;
  final List<Ticket> tickets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Recomputed from the tickets themselves (never hand-typed) so the
    // total shown here can never drift from what checkout displayed.
    final selections = [
      for (final ticket in tickets)
        TierSelection(tierId: ticket.tierId, unitPrice: ticket.unitPriceAtPurchase, quantity: ticket.quantity),
    ];
    final breakdown = calculateOrderTotal(
      selections: selections,
      bookingFeeRate: event.bookingFeeRate,
      taxRate: event.taxRate,
    );
    final orderCode = tickets.first.orderCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmed')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.check, size: 44, color: colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "You're going!",
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Your tickets have been added to My Tickets.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(gradient: gradientFor(event.gradientIndex)),
                            child: Center(
                              child: Text(event.coverEmoji, style: const TextStyle(fontSize: 26)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                event.venueLine,
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: colorScheme.outlineVariant),
                    ),
                    _ConfirmationRow(label: 'Order code', value: orderCode),
                    _ConfirmationRow(label: 'Date', value: formatEventDateTime(event.startsAt)),
                    _ConfirmationRow(
                      label: 'Tickets',
                      value: '${breakdown.ticketCount} ticket${breakdown.ticketCount == 1 ? '' : 's'}',
                    ),
                    _ConfirmationRow(label: 'Total paid', value: '\$${breakdown.total.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Your tickets', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            for (final ticket in tickets)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    QrStyleBlock(payload: ticket.qrPayload, size: 72),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ticket.tierName} x${ticket.quantity}',
                            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '\$${ticket.subtotal.toStringAsFixed(2)}',
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.read(rootTabIndexProvider.notifier).state = 1;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('View my tickets'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Back to Discover'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          Text(value, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
