String formatDuration(Duration duration) =>
    '${duration.inMinutes.toString().padLeft(2, '0')}:'
    '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

String formatSeconds(double seconds) =>
    formatDuration(Duration(milliseconds: (seconds * 1000).floor()));
