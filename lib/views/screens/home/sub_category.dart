import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/views/screens/home/product_details.dart';
import 'package:jebby/repositories/api_repository.dart';

import '../../../models/products_model.dart' as pm;
import '../../../constants/app_url.dart';
import '../../../utils/api_datetime.dart';
import 'package:jebby/constants/color.dart';

class SubCategoryScreen extends StatefulWidget {
  final String parentCategoryName;
  final String subcategoryName;
  final String subcategoryId;

  const SubCategoryScreen({
    super.key,
    required this.parentCategoryName,
    required this.subcategoryName,
    required this.subcategoryId,
  });

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<pm.Data> _all = [];
  bool _loading = true;
  String? _error;
  String _sortKey = 'default';
  int _activeFilterCount = 0;
  final Set<String> _filterTags = {};

  static const _accent = Color(0xFFF6A400);
  static const _pageBg = Color(0xFFF5F5F5);
  /// Subcategory toolbar / controls (match design spec)
  static const _borderLight = Color(0xFFE0E0E0);
  static const _textPrimary = Color(0xFF000000);
  static const _textSecondary = Color(0xFF666666);
  static const _breadcrumbStrong = Color(0xFF555555);
  static const _hintSearch = Color(0xFF9E9E9E);
  static const _filterBadge = Color(0xFFF2994A);

  String _subcategoryDescription() {
    final category = widget.parentCategoryName.trim();
    final subcategory = widget.subcategoryName.trim();
    if (subcategory.isEmpty) {
      return 'Explore available products in this section and find options that suit your needs.';
    }
    if (category.isEmpty) {
      return 'Browse the best $subcategory products available for rent with trusted quality and fair pricing.';
    }
    return 'Browse the best $subcategory options in $category. Compare products, prices, and ratings to find the right fit for your needs.';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiRepository.shared.fetchProductsBySubCategoryId(
        widget.subcategoryId,
      );
      if (!mounted) return;
      setState(() {
        _all = result?.data ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<pm.Data> get _visible {
    final q = _searchController.text.trim().toLowerCase();
    var list = List<pm.Data>.from(_all);
    if (q.isNotEmpty) {
      list =
          list
              .where((e) => (e.name ?? '').toLowerCase().contains(q))
              .toList();
    }
    if (_filterTags.contains('Delivery available')) {
      list =
          list
              .where((e) {
                final dc = e.delivery_charges?.toString().trim() ?? '';
                return dc.isNotEmpty;
              })
              .toList();
    }
    switch (_sortKey) {
      case 'price_asc':
        list.sort(
          (a, b) => (a.price ?? 0).compareTo(b.price ?? 0),
        );
        break;
      case 'price_desc':
        list.sort(
          (a, b) => (b.price ?? 0).compareTo(a.price ?? 0),
        );
        break;
      case 'name':
        list.sort((a, b) {
          final aName = (a.name ?? '').trim();
          final bName = (b.name ?? '').trim();
          return aName.toLowerCase().compareTo(bName.toLowerCase());
        });
        break;
      default:
        break;
    }
    return list;
  }

  String get _sortLabel {
    switch (_sortKey) {
      case 'name':
        return 'Name (A-Z)';
      case 'price_asc':
        return 'Low to high';
      case 'price_desc':
        return 'High to low';
      default:
        return 'Sort';
    }
  }

  bool _isNew(pm.Data item) {
    final raw = item.createdAt?.toString();
    if (raw == null || raw.isEmpty) return false;
    final d = parseApiDateTime(raw);
    if (d == null) return false;
    return DateTime.now().difference(d).inDays <= 14;
  }

  void _openSort() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          color: Colors.white,
          child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Default',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
                onTap: () {
                  setState(() => _sortKey = 'default');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(
                  'Name (A–Z)',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
                onTap: () {
                  setState(() => _sortKey = 'name');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(
                  'Price: Low to high',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
                onTap: () {
                  setState(() => _sortKey = 'price_asc');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(
                  'Price: High to low',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
                onTap: () {
                  setState(() => _sortKey = 'price_desc');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  void _openFilter() {
    const options = ['Delivery available'];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Container(
              color: Colors.white,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Filters',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...options.map((o) {
                        final on = _filterTags.contains(o);
                        return CheckboxListTile(
                          value: on,
                          title: Text(
                            o,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _textPrimary,
                            ),
                          ),
                          onChanged: (v) {
                            setModal(() {
                              if (v == true) {
                                _filterTags.add(o);
                              } else {
                                _filterTags.remove(o);
                              }
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _activeFilterCount = _filterTags.length;
                          });
                          Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                        ),
                        child: Text(
                          'Apply',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _goToDetail(pm.Data item) {
    Get.to(
      () => ProductDetailScreen(
        item.id,
        item.name,
        item.price,
        item.stars,
        AppUrl.baseUrlM + (item.image ?? ''),
        item.specifications,
        item.userId,
        item.description,
        item.delivery_charges,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
          style: IconButton.styleFrom(foregroundColor: Colors.black),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load products',
                  style: GoogleFonts.inter(color: Colors.black54),
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: _buildSearch(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: _buildSortFilterRow(),
                  ),
                ),
                if (_visible.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No products match your search.',
                          style: GoogleFonts.inter(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 225,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = _visible[index];
                        return _ProductTile(
                          item: item,
                          isNew: _isNew(item),
                          onTap: () => _goToDetail(item),
                        );
                      }, childCount: _visible.length),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.subcategoryName,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                height: 1.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15),
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _breadcrumbStrong,
                  height: 1.25,
                ),
                children: [
                  TextSpan(text: widget.parentCategoryName),
                  const TextSpan(text: ' > '),
                  TextSpan(
                    text: widget.subcategoryName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _breadcrumbStrong,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            _subcategoryDescription(),
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w400,
              color: _textSecondary,
            ),
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        cursorColor: _textSecondary,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: _textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search by Product Name',
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: _hintSearch,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              'assets/images/searchnew.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildSortFilterRow() {
    return Row(
      children: [
        Expanded(child: _toolbarPill(onTap: _openSort, child: _sortButtonChild())),
        const SizedBox(width: 12),
        Expanded(child: _toolbarPill(onTap: _openFilter, child: _filterButtonChild())),
      ],
    );
  }

  Widget _toolbarPill({required VoidCallback onTap, required Widget child}) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: _borderLight, width: 1),
    );
    return Material(
      color: Colors.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: child,
        ),
      ),
    );
  }

  Widget _sortButtonChild() {
    return Row(
      children: [
        Icon(Icons.swap_vert, size: 20, color: _textPrimary.withOpacity(0.88)),
        const SizedBox(width: 8),
        Text(
          _sortLabel,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary.withOpacity(0.9),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 22,
          color: _textPrimary.withOpacity(0.55),
        ),
      ],
    );
  }

  Widget _filterButtonChild() {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 20, color: _textPrimary.withOpacity(0.88)),
            const SizedBox(width: 8),
            Text(
              'Filter',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary.withOpacity(0.9),
              ),
            ),
          ],
        ),
        const Spacer(),
        if (_activeFilterCount > 0)
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _filterBadge,
              shape: BoxShape.circle,
            ),
            child: Text(
              _activeFilterCount > 9 ? '9+' : '$_activeFilterCount',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.item,
    required this.isNew,
    required this.onTap,
  });

  final pm.Data item;
  final bool isNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imagePath = item.image?.toString() ?? '';
    final imageUrl = imagePath.startsWith('http') ? imagePath : AppUrl.baseUrlM + imagePath;
    final price = item.price;
    final priceStr = price != null
        ? '\$${price.toDouble().toStringAsFixed(2)}'
        : '\$—';
    final stars = double.tryParse(item.stars?.toString() ?? '0') ?? 0.0;
    final int filledStars = stars.round().clamp(0, 5);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 118,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (_, __) => Container(
                          color: const Color(0xFFF0EDE8),
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: Color(0xFFE0B878),
                              size: 40,
                            ),
                          ),
                        ),
                    errorWidget:
                        (_, __, ___) => Container(
                          height: 118,
                          color: const Color(0xFFF0EDE8),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                  ),
                ),
                if (isNew)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade500,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 15.5,
                      color: const Color(0xFF2A2A2E),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    priceStr,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                      color: const Color(0xFF1D1D21),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: List.generate(5, (index) {
                      final active = index < filledStars;
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          active ? Icons.star : Icons.star_border,
                          color:
                              active
                                  ? const Color(0xFFF6AE02)
                                  : const Color(0xFFC6C8CF),
                          size: 18,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
