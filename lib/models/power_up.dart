
import 'dart:math';

import 'package:flutter/foundation.dart';

class PowerUp {
  final String id;
  final String type;
  final Point<int> position;
  final Duration duration;

  PowerUp({
    required this.type,
    required this.position,
    required this.duration,
  }) : id = UniqueKey().toString();
}


