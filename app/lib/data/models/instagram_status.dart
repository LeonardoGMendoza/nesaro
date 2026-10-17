/// Campo "instagram" de users/{uid}. Quem grava é o backend, depois do OAuth.
class InstagramStatus {
  const InstagramStatus({required this.connected, this.username});

  static const disconnected = InstagramStatus(connected: false);

  final bool connected;
  final String? username;

  factory InstagramStatus.fromMap(Map<String, dynamic>? map) => InstagramStatus(
        connected: map?['connected'] as bool? ?? false,
        username: map?['username'] as String?,
      );
}
