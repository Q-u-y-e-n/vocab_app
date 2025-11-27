class Topic {
  final int? id;
  final int userId;
  final String name;

  Topic({this.id, required this.userId, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'userId': userId, 'name': name};

  factory Topic.fromMap(Map<String, dynamic> map) =>
      Topic(id: map['id'], userId: map['userId'], name: map['name']);
}
