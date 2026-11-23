/// Sylius stores money in grosze (minor units).
String formatPln(int grosze) {
  final negative = grosze < 0;
  final abs = grosze.abs();
  final whole = abs ~/ 100;
  final fraction = abs % 100;
  final wholeStr = _groupThousands(whole);
  final sign = negative ? '-' : '';
  return '$sign$wholeStr,${fraction.toString().padLeft(2, '0')} zł';
}

String _groupThousands(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    if (i > 0 && fromEnd % 3 == 0) {
      buf.write(' ');
    }
    buf.write(s[i]);
  }
  return buf.toString();
}
