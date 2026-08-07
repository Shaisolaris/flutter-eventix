import 'package:flutter/material.dart';

/// Shared gradient palette used to render event cover art (Eventix has no
/// real photography - every cover is a colored gradient tile with an emoji
/// on top). Keeping the palette in one place means every screen that
/// renders an event (Discover, Event detail, My Tickets, Profile) stays
/// visually consistent for the same [Event.gradientIndex].
const List<List<Color>> _gradientPalette = <List<Color>>[
  [Color(0xFFA78BFA), Color(0xFF6D28D9)], // violet - brand
  [Color(0xFFFB7185), Color(0xFFBE123C)], // rose
  [Color(0xFF38BDF8), Color(0xFF0369A1)], // ocean blue
  [Color(0xFF34D399), Color(0xFF047857)], // emerald
  [Color(0xFFFBBF24), Color(0xFFB45309)], // amber
  [Color(0xFF2DD4BF), Color(0xFF0F766E)], // teal
  [Color(0xFFF472B6), Color(0xFFBE185D)], // pink
  [Color(0xFF818CF8), Color(0xFF3730A3)], // indigo
];

/// The two colors used for gradient block [index], cycling through the
/// palette if there are more events than palette entries.
List<Color> gradientColorsFor(int index) {
  final safeIndex = index % _gradientPalette.length;
  return _gradientPalette[safeIndex < 0 ? safeIndex + _gradientPalette.length : safeIndex];
}

/// A ready-to-use [LinearGradient] for gradient block [index].
LinearGradient gradientFor(int index) {
  return LinearGradient(
    colors: gradientColorsFor(index),
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
