import 'package:flutter/material.dart';

import '../../core/constants/date_format.dart';
import '../../core/constants/gradients.dart';
import '../../core/logic/availability.dart';
import '../../core/logic/pricing.dart';
import '../../core/models/event.dart';
import '../../core/models/ticket_tier.dart';
import '../discover/discover_widgets.dart' show CategoryPill, SavedHeartButton;

/// Large hero gradient block at the top of the detail screen, with a back
/// button, saved heart, and category pill overlaid - Eventix's stand-in
/// for a real event photo.
class EventHeroHeader extends StatelessWidget {
  const EventHeroHeader({
    super.key,
    required this.event,
    required this.isSaved,
    required this.onToggleSaved,
    required this.onBack,
  });

  final Event event;
  final bool isSaved;
  final VoidCallback onToggleSaved;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(gradient: gradientFor(event.gradientIndex)),
            child: Center(
              child: Text(event.coverEmoji, style: const TextStyle(fontSize: 96)),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: _CircleIconButton(icon: Icons.arrow_back, onTap: onBack, tooltip: 'Back'),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SavedHeartButton(isSaved: isSaved, onTap: onToggleSaved),
          ),
          Positioned(bottom: 12, left: 16, child: CategoryPill(category: event.category)),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap, required this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

/// Title, venue, and date/time shown just under the hero.
class EventOverview extends StatelessWidget {
  const EventOverview({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(event.title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.place_outlined, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                event.venueLine,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              formatEventDateTime(event.startsAt),
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bulleted list of an event's short highlight facts.
class EventHighlightsList extends StatelessWidget {
  const EventHighlightsList({super.key, required this.highlights});

  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final highlight in highlights)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(highlight, style: textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

/// One ticket tier row: name, description, price, and either a quantity
/// stepper or a sold-out/low-stock badge.
class TicketTierSelector extends StatelessWidget {
  const TicketTierSelector({
    super.key,
    required this.tier,
    required this.quantity,
    required this.onChanged,
  });

  final TicketTier tier;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final soldOut = isSoldOut(tier);
    final lowStock = !soldOut && isLowStock(tier);
    final maxQuantity = maxPurchasableForTier(tier);
    final remaining = remainingForTier(tier);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: quantity > 0 ? Border.all(color: colorScheme.primary, width: 1.5) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tier.name, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        tier.description,
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\$${tier.price.toStringAsFixed(2)}',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (!soldOut)
                  QuantityStepper(quantity: quantity, maxQuantity: maxQuantity, onChanged: onChanged),
              ],
            ),
            if (soldOut || lowStock) ...[
              const SizedBox(height: 10),
              _AvailabilityBadge(
                label: soldOut ? 'Sold out' : 'Only $remaining left',
                isSoldOut: soldOut,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.label, required this.isSoldOut});

  final String label;
  final bool isSoldOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSoldOut ? colorScheme.error : const Color(0xFFB45309);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// Minus/count/plus quantity control, bounded by [maxQuantity].
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.onChanged,
  });

  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
          icon: const Icon(Icons.remove),
          tooltip: 'Fewer',
          visualDensity: VisualDensity.compact,
        ),
        SizedBox(
          width: 28,
          child: Text('$quantity', textAlign: TextAlign.center, style: textTheme.titleMedium),
        ),
        IconButton.filledTonal(
          onPressed: quantity < maxQuantity ? () => onChanged(quantity + 1) : null,
          icon: const Icon(Icons.add),
          tooltip: 'More',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

/// Itemized order summary: one line per selected tier, then subtotal,
/// booking fee, tax, and total. Shown once at least one ticket is selected.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.breakdown, required this.tiers});

  final OrderBreakdown breakdown;
  final List<TicketTier> tiers;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tiersById = {for (final tier in tiers) tier.id: tier};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order summary', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (final line in breakdown.lines)
          _PriceLine(
            label: '${line.quantity} x ${tiersById[line.tierId]?.name ?? 'Ticket'}',
            amount: line.lineTotal,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(color: colorScheme.outlineVariant, height: 1),
        ),
        _PriceLine(label: 'Subtotal', amount: breakdown.subtotal),
        _PriceLine(label: 'Booking fee', amount: breakdown.bookingFee),
        _PriceLine(label: 'Tax', amount: breakdown.tax),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(color: colorScheme.outlineVariant, height: 1),
        ),
        _PriceLine(label: 'Total', amount: breakdown.total, emphasize: true),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.label, required this.amount, this.emphasize = false});

  final String label;
  final double amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final style = emphasize
        ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: emphasize ? style : style?.copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

/// Sticky footer with the running total and the Get tickets call to action.
class GetTicketsBar extends StatelessWidget {
  const GetTicketsBar({
    super.key,
    required this.breakdown,
    required this.onGetTickets,
    required this.isBusy,
  });

  final OrderBreakdown? breakdown;
  final VoidCallback? onGetTickets;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final breakdown = this.breakdown;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: breakdown == null
                    ? Text(
                        'Select tickets to see your total',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${breakdown.total.toStringAsFixed(2)} total',
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${breakdown.ticketCount} ticket${breakdown.ticketCount == 1 ? '' : 's'}',
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: isBusy ? null : onGetTickets,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Get tickets'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
