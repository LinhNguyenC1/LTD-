import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/cached_product.dart';
import '../../data/repositories/product_repository.dart';

class SearchViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;
  Timer? _debounceTimer;

  List<CachedProduct> _allResults = [];
  List<CachedProduct> _filteredResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'name', 'barcode', 'brand'
  String? _errorMessage;

  SearchViewModel({ProductRepository? productRepository})
      : _productRepository = productRepository ?? ProductRepository();

  List<CachedProduct> get searchResults => _filteredResults;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  String? get errorMessage => _errorMessage;
  int get totalCount => _filteredResults.length;
  bool get isEmpty => _filteredResults.isEmpty && !_isSearching;

  Future<void> search(String query) async {
    _debounceTimer?.cancel();
    _searchQuery = query;
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _productRepository.searchProducts(query);
      if (query != _searchQuery) return;
      _allResults = results;
      _applyFilter();
    } catch (e) {
      if (query != _searchQuery) return;
      _errorMessage = 'Lỗi tìm kiếm: $e';
      _filteredResults = [];
    } finally {
      if (query == _searchQuery) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  void searchDebounced(String query,
      {Duration duration = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _searchQuery = query;
    _debounceTimer = Timer(duration, () {
      search(query);
    });
  }

  void filterBy(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    _searchQuery = '';
    _errorMessage = null;
    search('');
  }

  void _applyFilter() {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredResults = List.from(_allResults);
      return;
    }

    switch (_selectedFilter) {
      case 'name':
        _filteredResults = _allResults
            .where((p) => p.productName.toLowerCase().contains(q))
            .toList();
        break;
      case 'barcode':
        _filteredResults = _allResults
            .where((p) => (p.barcode ?? '').toLowerCase().contains(q))
            .toList();
        break;
      case 'brand':
        _filteredResults = _allResults
            .where((p) => (p.brand ?? '').toLowerCase().contains(q))
            .toList();
        break;
      case 'all':
      default:
        _filteredResults = _allResults.where((p) {
          final matchName = p.productName.toLowerCase().contains(q);
          final matchBrand = (p.brand ?? '').toLowerCase().contains(q);
          final matchBarcode = (p.barcode ?? '').toLowerCase().contains(q);
          return matchName || matchBrand || matchBarcode;
        }).toList();
        break;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
