import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/services/notification_service.dart';
import '../../core/validators/barcode_validator.dart';
import '../../data/local/daos/history_dao.dart';
import '../../data/models/cached_product.dart';
import '../../data/models/product_nutrition.dart';
import '../../data/models/scan_history_item.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../rules/allergy_evaluator.dart';
import '../rules/nutrition_evaluator.dart';

enum ScanStatus {
  idle,
  loading,
  success,
  notFound,
  networkError,
  formatError,
  invalidBarcode,
}

class ScanViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;
  final ProfileRepository _profileRepository;
  final HistoryDao _historyDao;
  final NotificationService _notificationService;

  ScanStatus _status = ScanStatus.idle;
  CachedProduct? _scannedProduct;
  ProductNutrition? _scannedNutrition;
  List<String> _allergenViolations = [];
  List<String> _nutritionViolations = [];
  String? _errorMessage;
  String? _lastScannedBarcode;
  String _manualBarcode = '';
  bool _isInFlight = false;

  ScanViewModel({
    ProductRepository? productRepository,
    ProfileRepository? profileRepository,
    HistoryDao? historyDao,
    NotificationService? notificationService,
  })  : _productRepository = productRepository ?? ProductRepository(),
        _profileRepository = profileRepository ?? ProfileRepository(),
        _historyDao = historyDao ?? HistoryDao(),
        _notificationService =
            notificationService ?? NotificationService.instance;

  ScanStatus get status => _status;
  bool get isLoading => _status == ScanStatus.loading;
  bool get isSuccess => _status == ScanStatus.success;
  bool get isNotFound => _status == ScanStatus.notFound;
  bool get isNetworkError => _status == ScanStatus.networkError;
  bool get isFormatError => _status == ScanStatus.formatError;
  bool get isInvalidBarcode => _status == ScanStatus.invalidBarcode;

  CachedProduct? get scannedProduct => _scannedProduct;
  ProductNutrition? get scannedNutrition => _scannedNutrition;
  List<String> get allergenViolations => List.unmodifiable(_allergenViolations);
  List<String> get nutritionViolations => List.unmodifiable(_nutritionViolations);
  String? get errorMessage => _errorMessage;
  String? get lastScannedBarcode => _lastScannedBarcode;
  String get manualBarcode => _manualBarcode;
  bool get isInFlight => _isInFlight;

  String? validateBarcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mã vạch';
    }
    final clean = value.trim();
    if (!BarcodeValidator.isValid(clean)) {
      return 'Mã vạch không hợp lệ (cần 8, 12 hoặc 13 chữ số)';
    }
    return null;
  }

  void setManualBarcode(String value) {
    _manualBarcode = value;
    notifyListeners();
  }

  Future<bool> lookupBarcode(String barcode, {int? activeUserId}) async {
    final clean = barcode.trim();
    if (!BarcodeValidator.isValid(clean)) {
      _status = ScanStatus.invalidBarcode;
      _errorMessage = 'Mã vạch không hợp lệ (cần 8, 12 hoặc 13 chữ số)';
      notifyListeners();
      return false;
    }

    if (_isInFlight) {
      return false;
    }

    _isInFlight = true;
    _status = ScanStatus.loading;
    _errorMessage = null;
    _lastScannedBarcode = clean;
    notifyListeners();

    try {
      final product = await _productRepository.getProductByBarcode(clean);
      if (product == null) {
        _status = ScanStatus.notFound;
        _errorMessage = 'Không tìm thấy thông tin sản phẩm trên hệ thống.';
        _scannedProduct = null;
        _scannedNutrition = null;
        _allergenViolations = [];
        _nutritionViolations = [];
        notifyListeners();
        return false;
      }

      _scannedProduct = product;
      if (product.id != null) {
        _scannedNutrition =
            await _productRepository.getNutritionByProductId(product.id!);
      } else {
        _scannedNutrition = null;
      }

      final profile = await _profileRepository.fetchUserProfile(activeUserId);
      final userAllergens = profile?.allergens ?? [];
      final userTargets = profile?.nutritionTargets ?? {};

      _allergenViolations = AllergyEvaluator.evaluate(
        userAllergens: userAllergens,
        ingredientsText: product.ingredientsText,
      );

      if (_scannedNutrition != null) {
        _nutritionViolations = NutritionEvaluator.evaluate(
          targets: userTargets,
          actualData: _scannedNutrition!.nutritionData,
        );
      } else {
        _nutritionViolations = [];
      }

      final bool hasAllergenViolation = _allergenViolations.isNotEmpty;
      final bool hasNutritionViolation = _nutritionViolations.isNotEmpty;
      final String evaluationStatus = hasAllergenViolation
          ? 'VIOLATION'
          : (hasNutritionViolation ? 'WARNING' : 'SAFE');
      final String violationReasons = hasAllergenViolation
          ? 'Chứa chất dị ứng: ${_allergenViolations.join(', ')}'
          : (hasNutritionViolation
              ? _nutritionViolations.join('; ')
              : 'Đủ dữ liệu, không ghi nhận vi phạm tiêu chí trong hồ sơ.');

      if (product.id != null) {
        try {
          await _historyDao.insertHistoryItem(
            ScanHistoryItem(
              productId: product.id!,
              evaluationStatus: evaluationStatus,
              violationReasons: violationReasons,
              scannedAt: DateTime.now().toIso8601String(),
            ),
          );
        } catch (_) {}
      }

      if (_allergenViolations.length == 1) {
        await _notificationService.showAllergenAlert(
          productName: product.productName,
          allergenName: _allergenViolations.first,
        );
      } else if (_allergenViolations.length > 1) {
        await _notificationService.showAggregatedAllergenAlert(
          productName: product.productName,
          allergens: _allergenViolations,
        );
      }

      if (hasNutritionViolation) {
        await _notificationService.showNutritionAlert(
          productName: product.productName,
          warningDetails: _nutritionViolations.join(', '),
        );
      }

      if (!hasAllergenViolation && !hasNutritionViolation) {
        await _notificationService
            .showSafeScanNotification(product.productName);
      }

      await _notificationService
          .showScanCompletedNotification(product.productName);

      _status = ScanStatus.success;
      notifyListeners();
      return true;
    } on SocketException {
      _status = ScanStatus.networkError;
      _errorMessage = 'Lỗi kết nối mạng, vui lòng kiểm tra kết nối.';
      notifyListeners();
      return false;
    } on TimeoutException {
      _status = ScanStatus.networkError;
      _errorMessage = 'Hết thời gian chờ kết nối (Timeout).';
      notifyListeners();
      return false;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socket') ||
          errStr.contains('timeout') ||
          errStr.contains('network') ||
          errStr.contains('kết nối')) {
        _status = ScanStatus.networkError;
        _errorMessage = 'Lỗi kết nối mạng, vui lòng thử lại sau.';
      } else {
        _status = ScanStatus.formatError;
        _errorMessage = 'Đã xảy ra lỗi trong quá trình tra cứu: $e';
      }
      notifyListeners();
      return false;
    } finally {
      _isInFlight = false;
    }
  }

  Future<void> retry() async {
    if (_lastScannedBarcode != null && _lastScannedBarcode!.isNotEmpty) {
      await lookupBarcode(_lastScannedBarcode!);
    }
  }

  void reset() {
    _status = ScanStatus.idle;
    _scannedProduct = null;
    _scannedNutrition = null;
    _allergenViolations = [];
    _nutritionViolations = [];
    _errorMessage = null;
    _isInFlight = false;
    notifyListeners();
  }
}
