import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/event.dart';
import '../../data/providers.dart';
import '../detail/detail_screen.dart';
import 'discover_widgets.dart';

/// Discover: a searchable, category-filterable feed of every upcoming
/// event in the catalog.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// `null` means the "All" chip is selected.
  EventCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
  }

  List<Event> _applyFilters(List<Event> events, bool showSoldOut) {
    var results = events.where((event) => event.isUpcoming()).toList();

    final category = _selectedCategory;
    if (category != null) {
      results = results.where((event) => event.category == category).toList();
    }

    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      results = results.where((event) {
        return event.title.toLowerCase().contains(query) ||
            event.venueName.toLowerCase().contains(query) ||
            event.city.toLowerCase().contains(query);
      }).toList();
    }

    if (!showSoldOut) {
      results = results.where((event) => !event.isSoldOut).toList();
    }

    results.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final events = ref.watch(eventsProvider);
    final userDataAsync = ref.watch(eventixControllerProvider);
    final savedEventIds = userDataAsync.value?.savedEventIds ?? const <String>{};
    final showSoldOut = userDataAsync.value?.settings.showSoldOutEvents ?? true;

    final results = _applyFilters(events, showSoldOut);

    return Scaffold(
      appBar: AppBar(title: const Text('Eventix')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search events, venues, cities',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: [
                  CategoryChip(
                    label: 'All',
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  for (final category in EventCategory.values) ...[
                    CategoryChip(
                      label: category.label,
                      icon: categoryIcon(category),
                      selected: _selectedCategory == category,
                      onTap: () => setState(() => _selectedCategory = category),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  results.length == 1 ? '1 event' : '${results.length} events',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? const DiscoverEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final event = results[index];
                        return EventCard(
                          event: event,
                          isSaved: savedEventIds.contains(event.id),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => EventDetailScreen(eventId: event.id),
                            ),
                          ),
                          onToggleSaved: () =>
                              ref.read(eventixControllerProvider.notifier).toggleSavedEvent(event.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
