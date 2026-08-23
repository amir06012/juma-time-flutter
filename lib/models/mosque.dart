class Mosque {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  Mosque({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Mosque.fromPlacesJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'] as Map<String, dynamic>;
    return Mosque(
      placeId: json['place_id'] as String,
      name: json['name'] as String? ?? 'Unnamed mosque',
      // formatted_address (Text Search) is the full address; vicinity
      // (Nearby Search) is only a short one - prefer the full one and fall
      // back to vicinity for any caller still passing Nearby Search JSON.
      address: (json['formatted_address'] ?? json['vicinity']) as String? ?? '',
      latitude: (location['lat'] as num).toDouble(),
      longitude: (location['lng'] as num).toDouble(),
    );
  }
}
