import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_eventix/core/logic/availability.dart';
import 'package:flutter_eventix/core/models/ticket_tier.dart';

/// Every expected value below was hand-traced against the formulas in
/// availability.dart before being written down:
///
///   remaining          = totalQuantity - soldQuantity
///   isSoldOut           = remaining <= 0
///   isLowStock          = remaining > 0 && remaining <= threshold (default 10)
///   maxPurchasableForTier = 0 if remaining <= 0, else min(remaining, maxPerOrder)
///   canPurchase(qty)     = qty > 0 && qty <= maxPurchasableForTier
///   isEventSoldOut       = true for an empty tier list, else every tier sold out
///   startingPriceForTiers = cheapest tier that is not sold out, falling back to
///                            the cheapest tier overall once every tier is sold out
TicketTier _tier({
  required String id,
  required double price,
  required int totalQuantity,
  required int soldQuantity,
  int maxPerOrder = 8,
}) {
  return TicketTier(
    id: id,
    name: 'Tier $id',
    description: 'Test fixture tier',
    price: price,
    totalQuantity: totalQuantity,
    soldQuantity: soldQuantity,
    maxPerOrder: maxPerOrder,
  );
}

void main() {
  group('remainingForTier', () {
    test('subtracts sold from total', () {
      final tier = _tier(id: 'a', price: 40, totalQuantity: 100, soldQuantity: 40);
      expect(remainingForTier(tier), 60);
    });

    test('is zero when every ticket has been sold', () {
      final tier = _tier(id: 'b', price: 25, totalQuantity: 50, soldQuantity: 50);
      expect(remainingForTier(tier), 0);
    });
  });

  group('isSoldOut', () {
    test('false when tickets remain', () {
      final tier = _tier(id: 'a', price: 40, totalQuantity: 100, soldQuantity: 40);
      expect(isSoldOut(tier), isFalse);
    });

    test('true once totalQuantity equals soldQuantity', () {
      final tier = _tier(id: 'b', price: 25, totalQuantity: 50, soldQuantity: 50);
      expect(isSoldOut(tier), isTrue);
    });
  });

  group('isLowStock', () {
    test('true when remaining is positive but at or below the default threshold of 10', () {
      final tier = _tier(id: 'c', price: 60, totalQuantity: 30, soldQuantity: 25); // remaining 5
      expect(isLowStock(tier), isTrue);
    });

    test('false when a sold-out tier has zero remaining', () {
      final tier = _tier(id: 'b', price: 25, totalQuantity: 50, soldQuantity: 50); // remaining 0
      expect(isLowStock(tier), isFalse);
    });

    test('false when remaining is comfortably above the default threshold', () {
      final tier = _tier(id: 'a', price: 40, totalQuantity: 100, soldQuantity: 40); // remaining 60
      expect(isLowStock(tier), isFalse);
    });

    test('respects a custom threshold', () {
      final tier = _tier(id: 'c', price: 60, totalQuantity: 30, soldQuantity: 25); // remaining 5
      expect(isLowStock(tier, threshold: 5), isTrue);
      expect(isLowStock(tier, threshold: 4), isFalse);
    });
  });

  group('maxPurchasableForTier', () {
    test('capped by remaining seats when remaining is the tighter limit', () {
      final tier = _tier(id: 'c', price: 60, totalQuantity: 30, soldQuantity: 25, maxPerOrder: 8); // remaining 5
      expect(maxPurchasableForTier(tier), 5);
    });

    test('capped by maxPerOrder when inventory is plentiful', () {
      final tier = _tier(id: 'd', price: 15, totalQuantity: 20, soldQuantity: 12, maxPerOrder: 3); // remaining 8
      expect(maxPurchasableForTier(tier), 3);
    });

    test('zero once sold out, regardless of maxPerOrder', () {
      final tier = _tier(id: 'b', price: 25, totalQuantity: 50, soldQuantity: 50, maxPerOrder: 8);
      expect(maxPurchasableForTier(tier), 0);
    });
  });

  group('canPurchase', () {
    final tier = _tier(id: 'c', price: 60, totalQuantity: 30, soldQuantity: 25, maxPerOrder: 8); // remaining 5

    test('true up to the maximum purchasable quantity', () {
      expect(canPurchase(tier, 5), isTrue);
    });

    test('false above the maximum purchasable quantity', () {
      expect(canPurchase(tier, 6), isFalse);
    });

    test('false for zero or negative quantities', () {
      expect(canPurchase(tier, 0), isFalse);
      expect(canPurchase(tier, -1), isFalse);
    });
  });

  group('isEventSoldOut', () {
    test('false when at least one tier still has inventory', () {
      final a = _tier(id: 'a', price: 40, totalQuantity: 100, soldQuantity: 40);
      final b = _tier(id: 'b', price: 25, totalQuantity: 50, soldQuantity: 50);
      expect(isEventSoldOut([a, b]), isFalse);
    });

    test('true when every tier is sold out', () {
      final b = _tier(id: 'b', price: 25, totalQuantity: 50, soldQuantity: 50);
      final e = _tier(id: 'e', price: 90, totalQuantity: 10, soldQuantity: 10);
      expect(isEventSoldOut([b, e]), isTrue);
    });

    test('true for an event with no tiers at all', () {
      expect(isEventSoldOut(const []), isTrue);
    });
  });

  group('startingPriceForTiers', () {
    test('the lowest price among tiers that still have inventory', () {
      final cheapSoldOut = _tier(id: 'cheap-sold-out', price: 20, totalQuantity: 10, soldQuantity: 10);
      final midAvailable = _tier(id: 'mid-available', price: 45, totalQuantity: 10, soldQuantity: 2);
      final highAvailable = _tier(id: 'high-available', price: 90, totalQuantity: 10, soldQuantity: 2);
      expect(startingPriceForTiers([cheapSoldOut, midAvailable, highAvailable]), 45);
    });

    test('falls back to the cheapest tier overall once every tier is sold out', () {
      final a = _tier(id: 'a', price: 40, totalQuantity: 10, soldQuantity: 10);
      final b = _tier(id: 'b', price: 25, totalQuantity: 10, soldQuantity: 10);
      expect(startingPriceForTiers([a, b]), 25);
    });

    test('throws for an empty tier list', () {
      expect(() => startingPriceForTiers(const []), throwsArgumentError);
    });
  });
}
