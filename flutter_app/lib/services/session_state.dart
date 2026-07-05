class SessionState {
  static String getRole(Map<String, dynamic>? metadata) {
    return metadata?['role'] ?? 'Medical Representative';
  }

  static String getName(Map<String, dynamic>? metadata) {
    return metadata?['name'] ?? 'User';
  }

  static void setRole(String role) {}

  static void clear() {}
}
