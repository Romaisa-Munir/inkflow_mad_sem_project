class AuthorModel {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final int bookCount;
  final int likes;
  final DateTime joinedDate;
  final bool isAuthor;
  final DateTime? lastActive;

  AuthorModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.bookCount,
    required this.likes,
    required this.joinedDate,
    this.isAuthor = true,
    this.lastActive,
  });

  factory AuthorModel.fromMap(String id, Map<String, dynamic> data) {
    // Improved name resolution
    String name = _resolveDisplayName(data, id);

    return AuthorModel(
      id: id,
      name: name,
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      bookCount: data['bookCount'] ?? 0,
      likes: data['likes'] ?? 0,
      joinedDate: DateTime.fromMillisecondsSinceEpoch(
        data['joinedDate'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isAuthor: data['isAuthor'] ?? true,
      lastActive: data['lastActive'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastActive'])
          : null,
    );
  }

  /// Helper method to resolve the best display name from available data
  static String _resolveDisplayName(Map<String, dynamic> data, String id) {
    String? name;

    // First priority: name field (if set and not default)
    name = data['name'];
    if (name != null && name.isNotEmpty && name != 'Your Username') {
      return name;
    }

    // Second priority: displayName
    name = data['displayName'];
    if (name != null && name.isNotEmpty && name != 'Your Username') {
      return name;
    }

    // Third priority: username
    name = data['username'];
    if (name != null && name.isNotEmpty && name != 'Your Username') {
      return name;
    }

    // Fourth priority: email prefix (if email exists)
    String? email = data['email'];
    if (email != null && email.isNotEmpty) {
      String emailPrefix = email.split('@')[0];
      if (emailPrefix.isNotEmpty && emailPrefix.length > 1) {
        // Capitalize first letter and make it more readable
        return emailPrefix[0].toUpperCase() + emailPrefix.substring(1);
      }
    }

    // Last resort: generate a user-friendly name
    return 'Author${id.substring(0, 6)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'bookCount': bookCount,
      'likes': likes,
      'joinedDate': joinedDate.millisecondsSinceEpoch,
      'isAuthor': isAuthor,
      'lastActive': lastActive?.millisecondsSinceEpoch,
    };
  }

  AuthorModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    int? bookCount,
    int? followers,
    int? likes,
    DateTime? joinedDate,
    bool? isAuthor,
    DateTime? lastActive,
  }) {
    return AuthorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bookCount: bookCount ?? this.bookCount,
      likes: likes ?? this.likes,
      joinedDate: joinedDate ?? this.joinedDate,
      isAuthor: isAuthor ?? this.isAuthor,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  @override
  String toString() {
    return 'AuthorModel(id: $id, name: $name, email: $email, bookCount: $bookCount, likes: $likes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}