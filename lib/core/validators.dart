class Validators {
  static String? required(String? v, {String field = '字段'}) {
    if (v == null || v.trim().isEmpty) return '$field为必填';
    return null;
  }

  static String? length(String? v, {int min = 1, int max = 200, String field = '字段'}) {
    final len = (v ?? '').trim().length;
    if (len < min) return '$field长度不能少于$min';
    if (len > max) return '$field长度不能超过$max';
    return null;
  }
}