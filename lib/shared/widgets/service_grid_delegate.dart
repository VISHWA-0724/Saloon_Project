import 'dart:math' as math;

import 'package:flutter/material.dart';

SliverGridDelegateWithFixedCrossAxisCount serviceGridDelegateForWidth(
  double width, {
  int minColumns = 2,
  int maxColumns = 4,
}) {
  final columns = (width / 190).floor().clamp(minColumns, maxColumns);
  final totalSpacing = 12 * (columns - 1);
  final itemWidth = (width - totalSpacing) / columns;
  final targetHeight = math.max(270.0, math.min(335.0, itemWidth * 1.6));

  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: itemWidth / targetHeight,
  );
}
