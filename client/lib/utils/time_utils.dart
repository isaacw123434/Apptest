String formatDuration(int minutes, {bool compact = false}) {
  if (minutes < 60) {
    return compact ? '$minutes' : '$minutes min';
  }
  final int hours = minutes ~/ 60;
  final int mins = minutes % 60;
  if (mins == 0) {
    return '${hours}h';
  }
  return '${hours}h ${mins}m';
}
