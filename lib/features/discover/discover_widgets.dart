import 'package:flutter/material.dart';

import '../../core/constants/date_format.dart';
import '../../core/constants/gradients.dart';
import '../../core/models/event.dart';

/// Icon lookup for each category, used on chips and card pills.
IconData categoryIcon(EventCategory category) => switch (category) {
      EventCategory.music => Icons.music_note,
      EventCategory.tech => Icons.memory,
      EventCategory.sports => Icons.sports_basketball,
      EventCategory.arts => Icons.palette,
    };

/// One selectable pill in Discover's category row ("All" or a
/// [EventCategory]). Picks up its selected/unselected colors from the
/// app-wide `chipTheme`.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      avatar: icon == null ? null : Icon(icon, size: 16),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

/// Small pill naming an event's category, drawn over its gradient cover -
/// colors are fixed (not theme-derived) since it always sits on top of a
/// colored block, not a themed surface.
class CategoryPill extends StatelessWidget {
  const CategoryPill({super.key, required this.category});

  final EventCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(categoryIcon(category), size: 13, color: Colors.black87),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

/// Heart toggle drawn over a gradient block, used on Discover cards and the
/// Event detail hero.
class SavedHeartButton extends StatelessWidget {
  const SavedHeartButton({super.key, required this.isSaved, required this.onTap});

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            isSaved ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: isSaved ? const Color(0xFFF472B6) : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// One card in Discover's event feed: a gradient cover block with an
/// emoji, category pill, and saved heart, then title/venue/date/price
/// underneath.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSaved,
  });

  final Event event;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final soldOut = event.isSoldOut;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: gradientFor(event.gradientIndex)),
                      child: Center(
                        child: Text(event.coverEmoji, style: const TextStyle(fontSize: 56)),
                      ),
                    ),
                  ),
                  Positioned(top: 10, left: 10, child: CategoryPill(category: event.category)),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: SavedHeartButton(isSaved: isSaved, onTap: onToggleSaved),
                  ),
                  if (soldOut)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'SOLD OUT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: colorScheme.onError,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venueLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        formatEventDateTime(event.startsAt),
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    soldOut ? 'Sold out' : 'From \$${event.startingPrice.toStringAsFixed(0)}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: soldOut ? colorScheme.error : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when no event matches the current search/category filter.
class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text('No events found', style: textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Try a different search or category.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
