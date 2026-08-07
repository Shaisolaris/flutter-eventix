import '../logic/pricing.dart';
import '../logic/qr_payload.dart';

/// A confirmed ticket purchase for one tier of one event, created when a
/// buyer completes checkout on the Event detail screen.
///
/// An order that spans multiple tiers (e.g. 2 GA + 1 VIP for the same
/// event) produces one [Ticket] per tier, all sharing the same
/// [orderCode] - mirroring how a real ticketing app issues one scannable
/// pass per admission type rather than a single combined pass.
///
/// The price actually paid is captured at purchase time ([unitPriceAtPurchase])
/// rather than recomputed later from the tier's current price, so a
/// ticket's receipt never drifts if the catalog price changes after the
/// fact.
class Ticket {
  const Ticket({
    required this.id,
    required this.eventId,
    required this.tierId,
    required this.tierName,
    required this.quantity,
    required this.unitPriceAtPurchase,
    required this.purchasedAt,
    required this.orderCode,
  });

  /// Locally-generated unique identifier.
  final String id;

  /// Foreign key into the seeded event catalog.
  final String eventId;

  /// Foreign key into that event's tier list.
  final String tierId;

  /// The tier's name at purchase time, e.g. "VIP Lounge" - kept alongside
  /// [tierId] so a ticket still reads correctly even if the catalog is
  /// regenerated with different tier names.
  final String tierName;

  /// How many admissions this ticket covers.
  final int quantity;

  /// The tier's price per ticket at the moment of purchase.
  final double unitPriceAtPurchase;

  final DateTime purchasedAt;

  /// Short human-readable code shared by every ticket from the same
  /// checkout, e.g. "EVX-4B7K2Q".
  final String orderCode;

  /// `quantity * unitPriceAtPurchase`, rounded to the nearest cent. Does
  /// not include booking fee or tax, which are order-level, not per-ticket.
  double get subtotal => roundToCents(quantity * unitPriceAtPurchase);

  /// The deterministic string this ticket's QR-style block encodes.
  String get qrPayload => buildTicketPayload(
        ticketId: id,
        eventId: eventId,
        tierId: tierId,
        quantity: quantity,
      );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'eventId': eventId,
      'tierId': tierId,
      'tierName': tierName,
      'quantity': quantity,
      'unitPriceAtPurchase': unitPriceAtPurchase,
      'purchasedAt': purchasedAt.toIso8601String(),
      'orderCode': orderCode,
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      tierId: json['tierId'] as String,
      tierName: json['tierName'] as String,
      quantity: json['quantity'] as int,
      unitPriceAtPurchase: (json['unitPriceAtPurchase'] as num).toDouble(),
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      orderCode: json['orderCode'] as String,
    );
  }

  @override
  String toString() => 'Ticket($id, event: $eventId, tier: $tierName x$quantity, order: $orderCode)';
}
