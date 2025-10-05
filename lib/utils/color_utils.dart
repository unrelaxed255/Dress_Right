import 'package:flutter/material.dart';

extension ColorAlphaUtils on Color {
  Color withFraction(double opacity) {
    final alpha = (opacity.clamp(0, 1) * 255).round();
    return withAlpha(alpha);
  }
}
