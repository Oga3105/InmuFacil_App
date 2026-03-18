import 'dart:convert';

/// Stores the user's notification preferences.
///
/// All fields default to true except [marketingEmails] which defaults to false,
/// matching common best-practice opt-in/opt-out behaviour.
class NotificationSettings {
  final bool offerReceived;
  final bool offerAccepted;
  final bool offerCountered;
  final bool newMessage;
  final bool propertyStatusChange;
  final bool marketingEmails;

  const NotificationSettings({
    required this.offerReceived,
    required this.offerAccepted,
    required this.offerCountered,
    required this.newMessage,
    required this.propertyStatusChange,
    required this.marketingEmails,
  });

  /// Sensible defaults used on first launch or whenever persisted data is absent.
  static const NotificationSettings defaultSettings = NotificationSettings(
    offerReceived: true,
    offerAccepted: true,
    offerCountered: true,
    newMessage: true,
    propertyStatusChange: true,
    marketingEmails: false,
  );

  /// Returns a copy of this instance with the specified fields replaced.
  NotificationSettings copyWith({
    bool? offerReceived,
    bool? offerAccepted,
    bool? offerCountered,
    bool? newMessage,
    bool? propertyStatusChange,
    bool? marketingEmails,
  }) {
    return NotificationSettings(
      offerReceived: offerReceived ?? this.offerReceived,
      offerAccepted: offerAccepted ?? this.offerAccepted,
      offerCountered: offerCountered ?? this.offerCountered,
      newMessage: newMessage ?? this.newMessage,
      propertyStatusChange: propertyStatusChange ?? this.propertyStatusChange,
      marketingEmails: marketingEmails ?? this.marketingEmails,
    );
  }

  /// Serialises this instance to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'offerReceived': offerReceived,
        'offerAccepted': offerAccepted,
        'offerCountered': offerCountered,
        'newMessage': newMessage,
        'propertyStatusChange': propertyStatusChange,
        'marketingEmails': marketingEmails,
      };

  /// Deserialises from a JSON map. Falls back to the default value for any
  /// missing key so that old persisted data remains forward-compatible.
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      offerReceived: json['offerReceived'] as bool? ?? true,
      offerAccepted: json['offerAccepted'] as bool? ?? true,
      offerCountered: json['offerCountered'] as bool? ?? true,
      newMessage: json['newMessage'] as bool? ?? true,
      propertyStatusChange: json['propertyStatusChange'] as bool? ?? true,
      marketingEmails: json['marketingEmails'] as bool? ?? false,
    );
  }

  /// Convenience constructor that parses a raw JSON string produced by
  /// [toJsonString].
  factory NotificationSettings.fromJsonString(String raw) =>
      NotificationSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// Serialises to a JSON string suitable for SharedPreferences storage.
  String toJsonString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettings &&
          runtimeType == other.runtimeType &&
          offerReceived == other.offerReceived &&
          offerAccepted == other.offerAccepted &&
          offerCountered == other.offerCountered &&
          newMessage == other.newMessage &&
          propertyStatusChange == other.propertyStatusChange &&
          marketingEmails == other.marketingEmails;

  @override
  int get hashCode => Object.hash(
        offerReceived,
        offerAccepted,
        offerCountered,
        newMessage,
        propertyStatusChange,
        marketingEmails,
      );
}
