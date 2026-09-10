String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}

String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) {
    return 'há ${diff.inMinutes} minuto${diff.inMinutes == 1 ? '' : 's'}';
  }
  if (diff.inHours < 24) {
    return 'há ${diff.inHours} hora${diff.inHours == 1 ? '' : 's'}';
  }
  if (diff.inDays < 7) {
    return 'há ${diff.inDays} dia${diff.inDays == 1 ? '' : 's'}';
  }

  return formatDate(date);
}

String formatPrice(double price) {
  return price.toStringAsFixed(2).replaceAll('.', ',');
}
