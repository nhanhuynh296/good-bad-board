import 'package:uuid/uuid.dart';

enum Elo {
  c2, // Newbie
  c1, // Trinity
  b2, // Ryan
  b1, // Wei
  a2, // Nathan
  a1, // Justin
  s2, // Josh
  s1,
}

class Player {
  final String name;
  final Elo elo;
  final String id;

  Player({required this.name, required this.elo}) : id = Uuid().v4();
}
