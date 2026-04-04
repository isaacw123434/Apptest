// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/models.dart';

void main() {
  test('Color parsing benchmark', () {
    final segment = Segment(
      mode: 'bus',
      label: 'Bus 1',
      lineColor: '#FF5733',
      iconId: 'bus',
      time: 10,
    );

    const int iterations = 1000000;

    // Baseline: Parsing
    final stopwatchParsing = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
        // ignore: unused_local_variable
        Color color;
        try {
          color = Color(
            int.parse(segment.lineColor.replaceAll('#', ''), radix: 16) + 0xFF000000,
          );
        } catch (e) {
          color = Colors.grey;
        }
    }
    stopwatchParsing.stop();
    print('Parsing $iterations times took: ${stopwatchParsing.elapsedMilliseconds}ms');

    final stopwatchCached = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
       // ignore: unused_local_variable
       final color = segment.color;
    }
    stopwatchCached.stop();
    print('Cached access $iterations times took: ${stopwatchCached.elapsedMilliseconds}ms');
  });
}
