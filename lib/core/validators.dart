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

  static String? email(String? v) {
    final val = (v ?? '').trim();
    if (val.isEmpty) return '邮箱为必填';
    final re = RegExp(r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$');
    if (!re.hasMatch(val)) return '邮箱格式不正确';
    return null;
  }

  static bool isEmail(String v) {
    final val = v.trim();
    final re = RegExp(r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$');
    return re.hasMatch(val);
  }

  static String? username(String? v) {
    final val = (v ?? '').trim();
    if (val.isEmpty) return '用户名为必填';
    if (val.length < 3) return '用户名长度至少3位';
    final re = RegExp(r'^[A-Za-z0-9_\.\-]+$');
    if (!re.hasMatch(val)) return '用户名仅允许字母、数字、下划线和.-';
    return null;
  }

  static String? identifier(String? v) {
    final val = (v ?? '').trim();
    if (val.isEmpty) return '用户名或邮箱为必填';
    // 如果是邮箱，沿用邮箱规则；否则按用户名规则校验
    if (isEmail(val)) {
      return null; // email 通过
    }
    if (val.length < 3) return '用户名长度至少3位';
    final re = RegExp(r'^[A-Za-z0-9_\.\-]+$');
    if (!re.hasMatch(val)) return '用户名仅允许字母、数字、下划线和.-';
    return null;
  }

  static String? password(String? v) {
    final val = (v ?? '').trim();
    if (val.isEmpty) return '密码为必填';
    if (val.length < 6) return '密码长度至少6位';
    return null;
  }
}