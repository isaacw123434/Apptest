import 'package:flutter/material.dart';
import '../models.dart';

List<Segment> processSegments(List<Segment> rawSegments) {
  // 0. Flatten groups (Access & Train Groups)
  List<Segment> flattened = [];
  for (var seg in rawSegments) {
    if ((seg.mode == 'access_group' || seg.mode == 'train_group') &&
        seg.subSegments != null &&
        seg.subSegments!.isNotEmpty) {
      flattened.addAll(seg.subSegments!);
    } else {
      flattened.add(seg);
    }
  }

  List<Segment> processed = [];

  // 1. Filter out short walks (<= 2 mins), Parking, and Transfer
  for (var seg in flattened) {
    bool isWalk = seg.mode.toLowerCase() == 'walk' || seg.iconId == 'footprints';
    if (isWalk && seg.time <= 2) {
      continue;
    }
    if (seg.mode.toLowerCase() == 'parking') {
      continue;
    }
    if (seg.mode.toLowerCase() == 'wait' || seg.label.toLowerCase() == 'transfer') {
      continue;
    }
    processed.add(seg);
  }

  // 2. Merge Walk - Transfer - Walk
  List<Segment> mergedWalks = [];
  int i = 0;
  while (i < processed.length) {
    final seg = processed[i];
    bool isWalk = seg.mode.toLowerCase() == 'walk' || seg.iconId == 'footprints';

    if (isWalk && i + 2 < processed.length) {
      final next = processed[i + 1];
      final nextNext = processed[i + 2];
      bool isNextWait = next.mode.toLowerCase() == 'wait' || next.label.toLowerCase() == 'transfer';
      bool isNextNextWalk = nextNext.mode.toLowerCase() == 'walk' || nextNext.iconId == 'footprints';

      if (isNextWait && isNextNextWalk) {
        // Merge
        mergedWalks.add(Segment(
          mode: 'walk',
          label: 'Walk',
          lineColor: seg.lineColor,
          iconId: seg.iconId,
          time: seg.time + next.time + nextNext.time,
          to: nextNext.to,
          detail: seg.detail,
        ));
        i += 3;
        continue;
      }
    }
    mergedWalks.add(seg);
    i++;
  }
  processed = mergedWalks;

  // 3. Merge Consecutive Trains
  List<Segment> mergedTrains = [];
  int j = 0;
  while (j < processed.length) {
    final seg = processed[j];
    if (j + 1 < processed.length) {
      final next = processed[j + 1];
      bool isTrain1 = seg.mode.toLowerCase() == 'train' || seg.iconId == 'train';
      bool isTrain2 = next.mode.toLowerCase() == 'train' || next.iconId == 'train';

      if (isTrain1 && isTrain2) {
        // Merge any consecutive trains
        // If labels differ, combine them. If same, keep one.
        String mergedLabel = seg.label;
        if (seg.label != next.label) {
          // Avoid duplicate text like "CrossCountry + EMR + EMR" if expanding logic runs multiple times
          // But here we are iterating linearly.
          mergedLabel = '${seg.label} + ${next.label}';
        }

        mergedTrains.add(Segment(
          mode: 'train',
          label: mergedLabel,
          lineColor: seg.lineColor,
          iconId: seg.iconId,
          time: seg.time + next.time,
          to: next.to,
          detail: seg.detail,
          path: seg.path,
          co2: (seg.co2 ?? 0) + (next.co2 ?? 0),
          distance: (seg.distance ?? 0) + (next.distance ?? 0),
        ));
        j += 2;
        continue;
      }
    }
    mergedTrains.add(seg);
    j++;
  }
  processed = mergedTrains;

  // 4. Final pass: Fix EMR labels (if not merged)
  List<Segment> finalPass = [];
  for (var seg in processed) {
    String label = seg.label.replaceAll('E M R', 'EMR');

    if (label != seg.label) {
      finalPass.add(Segment(
        mode: seg.mode,
        label: label,
        lineColor: seg.lineColor,
        iconId: seg.iconId,
        time: seg.time,
        to: seg.to,
        detail: seg.detail,
        path: seg.path,
        co2: seg.co2,
        distance: seg.distance,
      ));
    } else {
      finalPass.add(seg);
    }
  }

  return finalPass;
}

List<Segment> collectSchematicSegments(JourneyResult result, Leg? mainLeg) {
  List<Segment> processedSegments = [];
  processedSegments.addAll(processSegments(result.leg1.segments));

  if (mainLeg != null) {
    processedSegments.addAll(processSegments(mainLeg.segments));
  } else {
    processedSegments.addAll(processSegments([
      Segment(
        mode: 'train',
        label: 'CrossCountry',
        lineColor: '#713e8d',
        iconId: 'train',
        time: 102,
      )
    ]));
  }

  processedSegments.addAll(processSegments(result.leg3.segments));
  return processedSegments;
}

Map<String, TimeOfDay> calculateJourneyTimes(JourneyResult result) {
  // Main Leg Departure = 8:03 AM (483 minutes)
  final int mainLegDepartMinutes = 8 * 60 + 3;
  final int startMinutes = mainLegDepartMinutes - result.buffer - result.leg1.time;
  // End Time = Start + Duration
  final int endMinutes = startMinutes + result.time;

  return {
    'start': minutesToTimeOfDay(startMinutes),
    'end': minutesToTimeOfDay(endMinutes),
  };
}

TimeOfDay minutesToTimeOfDay(int totalMinutes) {
  // Handle wraparound
  totalMinutes = totalMinutes % (24 * 60);
  if (totalMinutes < 0) totalMinutes += 24 * 60;

  return TimeOfDay(
    hour: totalMinutes ~/ 60,
    minute: totalMinutes % 60,
  );
}

String formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
