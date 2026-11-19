class FormValidator {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email không được để trống';
    }
    final clean = value.trim();
    if (!_emailRegExp.hasMatch(clean)) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Họ tên không được để trống';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu';
    }
    if (password != confirmPassword) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }
}

class BarcodeValidator {
  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  static bool isValid(String? barcode) {
    if (barcode == null) return false;
    final clean = barcode.trim();
    if (clean.isEmpty) return false;
    if (!_digitsOnly.hasMatch(clean)) return false;

    // Supported formats: EAN-8 (8 digits), UPC-A (12 digits), EAN-13 (13 digits)
    final len = clean.length;
    return len == 8 || len == 12 || len == 13;
  }
}
