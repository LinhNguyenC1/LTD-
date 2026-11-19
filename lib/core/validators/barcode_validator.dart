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
