class AuthorModel {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final int bookCount;
  final int followers;
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
    required this.followers,
    required this.likes,
    required this.joinedDate,
    this.isAuthor = true,
    this.lastActive,
  });

  factory AuthorModel.fromMap(String id, Map<String, dynamic> data) {
    // Create a better name fallback
    String name = data['name'] ??
        data['displayName'] ??
        data['username'] ??
        data['email']?.split('@')[0] ??
        'Author${id.substring(0, 6)}';

    return AuthorModel(
      id: id,
      name: name,
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      bookCount: data['bookCount'] ?? 0,
      followers: data['followers'] ?? 0,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'bookCount': bookCount,
      'followers': followers,
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
      followers: followers ?? this.followers,
      likes: likes ?? this.likes,
      joinedDate: joinedDate ?? this.joinedDate,
      isAuthor: isAuthor ?? this.isAuthor,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  @override
  String toString() {
    return 'AuthorModel(id: $id, name: $name, email: $email, bookCount: $bookCount, followers: $followers, likes: $likes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}