class User {
  final String id;
  final String name;
  final String email;
  final DateTime joinDate;
  final double? weight;
  final double? height;
  final String? fitnessLevel;
  final List<String>? fitnessGoals;


  User({
    required this.id,
    required this.name,
    required this.email,
    required this.joinDate,
    this.weight,
    this.height,
    this.fitnessLevel,
    this.fitnessGoals,

  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      joinDate: DateTime.parse(json['joinDate'] as String),
      weight: json['weight'] != null ? json['weight'].toDouble() : null,
      height: json['height'] != null ? json['height'].toDouble() : null,
      fitnessLevel: json['fitnessLevel'] as String?,
      fitnessGoals: json['fitnessGoals'] != null
          ? List<String>.from(json['fitnessGoals'] as List)
          : null,

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'joinDate': joinDate.toIso8601String(),
      'weight': weight,
      'height': height,
      'fitnessLevel': fitnessLevel,
      'fitnessGoals': fitnessGoals,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? joinDate,
    double? weight,
    double? height,
    String? fitnessLevel,
    List<String>? fitnessGoals,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      joinDate: joinDate ?? this.joinDate,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.joinDate == joinDate &&
        other.weight == weight &&
        other.height == height &&
        other.fitnessLevel == fitnessLevel &&
        other.fitnessGoals == fitnessGoals ;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    name.hashCode ^
    email.hashCode ^
    joinDate.hashCode ^
    weight.hashCode ^
    height.hashCode ^
    fitnessLevel.hashCode ^
    fitnessGoals.hashCode ;
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, joinDate: $joinDate, '
        'weight: $weight, height: $height, fitnessLevel: $fitnessLevel, '
        'fitnessGoals: $fitnessGoals)';
  }
}