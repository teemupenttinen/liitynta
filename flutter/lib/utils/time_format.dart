String formatUpdatedAgo(DateTime? updatedAt) {
  if (updatedAt == null) return 'Päivitetään...';
  final diff = DateTime.now().difference(updatedAt);
  if (diff.inSeconds < 60) return 'Päivitetty juuri äsken';
  if (diff.inMinutes < 60) return 'Päivitetty ${diff.inMinutes} min sitten';
  if (diff.inHours < 24) return 'Päivitetty ${diff.inHours} t sitten';
  return 'Päivitetty yli vuorokausi sitten';
}
