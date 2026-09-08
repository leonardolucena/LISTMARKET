String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}

String formatPrice(double price) {
  return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
}
