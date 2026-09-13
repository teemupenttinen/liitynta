String formatUpdatedAgo(DateTime? updatedAt) {
  if (updatedAt == null) return 'Päivitetään...';
  final diff = DateTime.now().difference(updatedAt);
  if (diff.inSeconds < 60) return 'Päivitetty juuri äsken';
  if (diff.inMinutes < 60) return 'Päivitetty ${diff.inMinutes} min sitten';
  if (diff.inHours < 24) return 'Päivitetty ${diff.inHours} t sitten';
  return 'Päivitetty yli vuorokausi sitten';
}

/// Label for the departure-time pill on the map, for example "Lähde nyt" or
/// "Lähtö huomenna klo 7.30".
String formatDeparture(DateTime? departAt) {
  if (departAt == null) return 'Lähde nyt';
  final now = DateTime.now();
  // UTC dates, so that a daylight saving change does not shorten a day.
  final days = DateTime.utc(departAt.year, departAt.month, departAt.day)
      .difference(DateTime.utc(now.year, now.month, now.day))
      .inDays;
  final clock =
      'klo ${departAt.hour}.${departAt.minute.toString().padLeft(2, '0')}';
  if (days == 0) return 'Lähtö $clock';
  if (days == 1) return 'Lähtö huomenna $clock';
  return 'Lähtö ${departAt.day}.${departAt.month}. $clock';
}
