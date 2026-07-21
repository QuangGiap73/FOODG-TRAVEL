class RecommendationTextUtils {
  const RecommendationTextUtils._();

  static String normalizeToken(String value) {
    return normalizeText(value)
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  }

  static String normalizeText(String value) {
    return removeVietnameseDiacritics(value)
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String removeVietnameseDiacritics(String value) {
    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩ'
        'òóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨ'
        'ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiii'
        'ooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIII'
        'OOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    final buffer = StringBuffer();
    for (final char in value.split('')) {
      final index = from.indexOf(char);
      buffer.write(index == -1 || index >= to.length ? char : to[index]);
    }
    return buffer.toString();
  }
}
