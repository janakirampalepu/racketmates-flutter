/// Display fallback for backend keys until the server-driven Messages /
/// reference-data provider exists (backlog 15.1): `et_game` -> `Game`.
String humanizeKey(String? key) {
  if (key == null || key.isEmpty) return '';
  final words = key
      .replaceFirst(RegExp(r'^[a-z]{1,4}_'), '')
      .split('_')
      .where((w) => w.isNotEmpty);
  return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
