import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../business_logic/viewmodels/search_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cached_product_adapter.dart';
import '../../widgets/pack_widget.dart';
import '../product/detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<SearchViewModel>();
      _searchController.text = vm.searchQuery;
      if (vm.searchResults.isEmpty && !vm.isSearching) {
        vm.search('');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchVm = context.watch<SearchViewModel>();

    const filters = [
      ('all', 'Tất cả', Key('filter_chip_all')),
      ('name', 'Tên sản phẩm', Key('filter_chip_name')),
      ('barcode', 'Mã vạch', Key('filter_chip_barcode')),
      ('brand', 'Thương hiệu', Key('filter_chip_brand')),
    ];

    return Scaffold(
      backgroundColor: canvasBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: inkText),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: TextField(
          key: const Key('search_input_field'),
          controller: _searchController,
          autofocus: false,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm, mã vạch...',
            hintStyle: const TextStyle(color: subText, fontSize: 15),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: primaryGreen),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    key: const Key('search_clear_button'),
                    icon: const Icon(Icons.close, color: subText),
                    onPressed: () {
                      _searchController.clear();
                      searchVm.clearSearch();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() {});
            searchVm.searchDebounced(val);
          },
          onSubmitted: (val) {
            searchVm.search(val);
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isSelected = searchVm.selectedFilter == f.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: f.$3,
                      label: Text(
                        f.$2,
                        style: TextStyle(
                          color: isSelected ? Colors.white : inkText,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: primaryGreen,
                      backgroundColor: const Color(0xFFF0F4F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? primaryGreen : Colors.transparent,
                        ),
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) {
                          searchVm.filterBy(f.$1);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: cardBorder),

          // Total Count Header
          if (!searchVm.isSearching && !searchVm.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                '${searchVm.totalCount} sản phẩm tìm thấy',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subText,
                ),
              ),
            ),

          // Content Zone
          Expanded(
            child: searchVm.isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  )
                : searchVm.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: subText,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Không tìm thấy sản phẩm phù hợp',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: inkText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Thử kiểm tra lại tên, mã vạch hoặc đổi bộ lọc',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: subText),
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton.icon(
                                key: const Key('search_reset_button'),
                                icon: const Icon(Icons.refresh, color: primaryGreen),
                                label: const Text(
                                  'Xem tất cả sản phẩm',
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: primaryGreen),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  searchVm.filterBy('all');
                                  searchVm.clearSearch();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: searchVm.searchResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = searchVm.searchResults[index];
                          final food = product.toFood();

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailPage(food: food),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorder),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x08000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Pack Widget Preview
                                  PackWidget(food: food, small: true),
                                  const SizedBox(width: 14),

                                  // Product Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (product.brand != null &&
                                            product.brand!.isNotEmpty)
                                          Text(
                                            product.brand!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: subText,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        Text(
                                          product.productName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: inkText,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            if (product.barcode != null &&
                                                product.barcode!.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF0F4F1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  product.barcode!,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: inkText,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            if (product.nutriscoreGrade != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE4F1E5),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Nutri-Score ${product.nutriscoreGrade!.toUpperCase()}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: primaryGreen,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Icon(
                                    Icons.chevron_right,
                                    color: subText,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
