import 'package:intl/intl.dart';

String formatRupiah(num value) {
  final formatter = NumberFormat.decimalPattern('id_ID');
  return 'Rp ${formatter.format(value)}';
}

String generateOrderCode() {
  final now = DateTime.now();
  final datePart =
      '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final randomPart = (100 + now.millisecond % 900).toString();
  return '#ORD-$datePart-$randomPart';
}
