import '../models.dart';

class RouteSelector {
  static List<JourneyResult> selectJourneys(List<JourneyResult> combos, String tab) {
    // Group & Sort based on "Diversity First" Algorithm
    Map<String, List<JourneyResult>> grouped = {};
    for (var result in combos) {
      final anchor = result.anchor;
      if (!grouped.containsKey(anchor)) {
        grouped[anchor] = [];
      }
      grouped[anchor]!.add(result);
    }

    // Helper to sort a list of results based on tab
    void sortResults(List<JourneyResult> results) {
      if (tab == 'fastest') {
        results.sort((a, b) => a.time.compareTo(b.time));
      } else if (tab == 'cheapest') {
        results.sort((a, b) => a.cost.compareTo(b.cost));
      } else {
        // Smart
        int minRisk = 0;
        if (combos.isNotEmpty) {
          minRisk = combos.map((c) => c.risk).reduce((a, b) => a < b ? a : b);
        }
        results.sort((a, b) {
          double scoreA = a.cost + (a.time * 0.3) + ((a.risk - minRisk) * 20.0) + a.emissions.val;
          double scoreB = b.cost + (b.time * 0.3) + ((b.risk - minRisk) * 20.0) + b.emissions.val;
          return scoreA.compareTo(scoreB);
        });
      }
    }

    // Sort within groups
    for (var key in grouped.keys) {
      sortResults(grouped[key]!);
    }

    // Sort groups by their best journey
    var sortedKeys = grouped.keys.toList();

    // We need a way to compare two journeys based on current tab logic
    int compareJourneys(JourneyResult a, JourneyResult b) {
        if (tab == 'fastest') {
          return a.time.compareTo(b.time);
        } else if (tab == 'cheapest') {
          return a.cost.compareTo(b.cost);
        } else {
          int minRisk = 0;
          if (combos.isNotEmpty) {
            minRisk = combos.map((c) => c.risk).reduce((x, y) => x < y ? x : y);
          }
          double scoreA = a.cost + (a.time * 0.3) + ((a.risk - minRisk) * 20.0) + a.emissions.val;
          double scoreB = b.cost + (b.time * 0.3) + ((b.risk - minRisk) * 20.0) + b.emissions.val;
          return scoreA.compareTo(scoreB);
        }
    }

    sortedKeys.sort((k1, k2) {
      return compareJourneys(grouped[k1]!.first, grouped[k2]!.first);
    });

    List<JourneyResult> finalResults = [];
    Set<String> usedAnchors = {};
    int slots = 999;

    // Round 1: Diversity
    for (var key in sortedKeys) {
      if (finalResults.length >= slots) break;
      final group = grouped[key]!;
      if (group.isNotEmpty) {
        finalResults.add(group.first);
        usedAnchors.add(key);
      }
    }

    // Round 2: Depth
    if (finalResults.length < slots) {
      Map<String, int> groupIndices = {};
      for(var key in sortedKeys) {
        groupIndices[key] = usedAnchors.contains(key) ? 1 : 0;
      }

      while (finalResults.length < slots) {
        JourneyResult? bestCandidate;
        String? bestCandidateKey;

        for (var key in sortedKeys) {
          final index = groupIndices[key]!;
          if (index < grouped[key]!.length) {
            final candidate = grouped[key]![index];
            if (bestCandidate == null || compareJourneys(candidate, bestCandidate) < 0) {
               if (bestCandidate == null) {
                 bestCandidate = candidate;
                 bestCandidateKey = key;
               } else if (compareJourneys(candidate, bestCandidate) < 0) {
                 bestCandidate = candidate;
                 bestCandidateKey = key;
               }
            }
          }
        }

        if (bestCandidate != null) {
          finalResults.add(bestCandidate);
          final key = bestCandidateKey!;
          groupIndices[key] = (groupIndices[key] ?? 0) + 1;
        } else {
          break;
        }
      }
    }

    return finalResults;
  }
}
