import 'dart:async';

import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/main_screen.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:find_me/widgets/colors_help.dart';
import 'package:flutter/material.dart';

/// 03 — Discovery: a personalized gallery ranked by the recommendation engine.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class DiscoverFilters {
  List<String> types = [];
  List<String> colors = [];
  List<String> styles = [];
  List<String> sizes = [];
  String? gender;
  RangeValues budget = const RangeValues(0, 500);
  String sort = 'match';

  int get activeCount =>
      colors.length + styles.length + sizes.length + (gender != null ? 1 : 0) + (budget.start > 0 || budget.end < 500 ? 1 : 0);
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _queryCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _filters = DiscoverFilters();
  final List<RecoProduct> _items = [];
  int _page = 1;
  int _total = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  static const _typeChips = [
    ('All', <String>[]),
    ('Dresses', ['dress']),
    ('Tops', ['shirt', 'tshirt']),
    ('Bottoms', ['pants', 'jeans', 'shorts', 'skirt']),
    ('Shoes', ['shoes']),
    ('Bags', ['bag']),
    ('Jewelry', ['necklace', 'bracelet', 'ring', 'earrings', 'watch']),
    ('Outerwear', ['jacket']),
    ('Sport', ['sportswear']),
  ];

  static const _sorts = {
    'match': 'Best match',
    'price_asc': 'Price: low to high',
    'price_desc': 'Price: high to low',
    'rating': 'Top rated',
    'popular': 'Most popular',
    'new': 'Newest',
  };

  @override
  void initState() {
    super.initState();
    _applyIncoming(ShellController.discoverQuery.value);
    ShellController.discoverQuery.addListener(_onIncoming);
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) _load();
    });
    _reload();
  }

  @override
  void dispose() {
    ShellController.discoverQuery.removeListener(_onIncoming);
    _queryCtrl.dispose();
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onIncoming() {
    final q = ShellController.discoverQuery.value;
    if (q == null) return; // we reset it to null ourselves after consuming it
    _applyIncoming(q);
    _reload();
  }

  /// Supports plain text and shortcuts from Home: "type:dress", "sort:popular", "max:100".
  void _applyIncoming(String? q) {
    if (q == null) return;
    _queryCtrl.text = '';
    if (q.startsWith('type:')) {
      _filters.types = q.substring(5).split(',');
    } else if (q.startsWith('sort:')) {
      _filters.sort = q.substring(5);
      _filters.types = [];
    } else if (q.startsWith('max:')) {
      final max = double.tryParse(q.substring(4)) ?? 500;
      _filters.budget = RangeValues(0, max.clamp(10, 500).toDouble());
      _filters.sort = 'match';
    } else {
      _queryCtrl.text = q;
      _filters.types = [];
    }
    ShellController.discoverQuery.value = null;
  }

  Future<void> _reload() async {
    setState(() {
      _items.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    await _load();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final f = _filters;
      final (items, hasMore, total) = await FindMeApi.instance.discover(
        query: _queryCtrl.text.trim(),
        types: f.types,
        colors: f.colors,
        styles: f.styles,
        sizes: f.sizes,
        gender: f.gender,
        minPrice: f.budget.start > 0 ? f.budget.start : null,
        maxPrice: f.budget.end < 500 ? f.budget.end : null,
        sort: f.sort,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(items);
        _hasMore = hasMore;
        _total = total;
        _page++;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _sameTypes(List<String> a) => a.length == _filters.types.length && a.every(_filters.types.contains);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.checkroom_rounded, color: context.isDark ? AppColors.camel : AppColors.brown, size: 28),
                    const SizedBox(width: 8),
                    Text('Discover', style: AppTheme.display(30, color: context.fg)),
                  ]),
                  Text('A gallery curated for your style', style: context.text.bodySmall),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _queryCtrl,
                        textInputAction: TextInputAction.search,
                        onChanged: (_) {
                          _debounce?.cancel();
                          _debounce = Timer(const Duration(milliseconds: 450), _reload);
                        },
                        onSubmitted: (_) => _reload(),
                        decoration: InputDecoration(
                          hintText: 'Search the catalogue',
                          prefixIcon: Icon(Icons.search_rounded, color: context.fgMuted),
                          suffixIcon: _queryCtrl.text.isEmpty
                              ? null
                              : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () {
                                  _queryCtrl.clear();
                                  _reload();
                                }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _FilterButton(count: _filters.activeCount, onTap: _openFilters),
                  ]),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 58,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  scrollDirection: Axis.horizontal,
                  itemCount: _typeChips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final (label, types) = _typeChips[i];
                    final selected = _sameTypes(types);
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      showCheckmark: false,
                      labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.ink : context.fg),
                      onSelected: (_) {
                        _filters.types = List.of(types);
                        _reload();
                      },
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 8, 8),
                child: Row(children: [
                  Expanded(child: Text(_loading && _items.isEmpty ? 'Searching…' : '$_total results', style: context.text.bodySmall)),
                  PopupMenuButton<String>(
                    initialValue: _filters.sort,
                    onSelected: (v) {
                      _filters.sort = v;
                      _reload();
                    },
                    itemBuilder: (_) => _sorts.entries.map((e) => PopupMenuItem(value: e.key, child: Text(e.value))).toList(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(children: [
                        Icon(Icons.swap_vert_rounded, size: 18, color: context.fg),
                        const SizedBox(width: 4),
                        Text(_sorts[_filters.sort] ?? 'Sort', style: context.text.labelMedium),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
            if (_error != null && _items.isEmpty)
              SliverToBoxAdapter(child: ErrorRetry(message: _error!, onRetry: _reload))
            else if (_items.isEmpty && _loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 14, childAspectRatio: 0.53),
                  delegate: SliverChildBuilderDelegate((_, __) => const ProductCardSkeleton(width: double.infinity), childCount: 6),
                ),
              )
            else if (_items.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Nothing found',
                  message: 'Try removing a filter, or ask the AI stylist to find alternatives.',
                  action: 'Ask the stylist',
                  onAction: () => ShellController.askStylist(_queryCtrl.text.isEmpty ? null : _queryCtrl.text),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 14, childAspectRatio: 0.53),
                  delegate: SliverChildBuilderDelegate((_, i) => ProductCard(_items[i], heroPrefix: 'disc'), childCount: _items.length),
                ),
              ),
            if (_loading && _items.isNotEmpty)
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: AppColors.camel)))),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilters() async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(filters: _filters),
    );
    if (applied == true) _reload();
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _FilterButton({required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.caramel, shape: BoxShape.circle, boxShadow: AppColors.softShadow),
        child: IconButton(tooltip: 'Filters', icon: const Icon(Icons.tune_rounded, color: AppColors.ink), onPressed: onTap),
      ),
      if (count > 0)
        Positioned(
          right: -2,
          top: -2,
          child: CircleAvatar(radius: 9, backgroundColor: AppColors.ink, child: Text('$count', style: const TextStyle(fontSize: 10, color: AppColors.cream))),
        ),
    ]);
  }
}

class _FilterSheet extends StatefulWidget {
  final DiscoverFilters filters;
  const _FilterSheet({required this.filters});
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  static const colors = ['black', 'white', 'grey', 'beige', 'cream', 'brown', 'red', 'pink', 'blue', 'light blue', 'green', 'yellow', 'orange', 'purple', 'gold', 'silver'];
  static const styles = {'minimalist': 'Minimalist', 'elegant': 'Classy', 'casual': 'Casual', 'sporty': 'Sporty', 'trendy': 'Modern'};
  static const sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const genders = {'women': 'Women', 'men': 'Men', 'kids': 'Kids'};

  DiscoverFilters get f => widget.filters;

  Widget _title(String t) => Padding(padding: const EdgeInsets.only(top: 18, bottom: 10), child: Text(t, style: context.text.titleSmall));

  void _toggle(List<String> list, String v) {
    setState(() {
      if (list.contains(v)) {
        list.remove(v);
      } else {
        list.add(v);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.line, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text('Filters', style: AppTheme.display(24, color: context.fg))),
            TextButton(
              onPressed: () => setState(() {
                f.colors.clear();
                f.styles.clear();
                f.sizes.clear();
                f.gender = null;
                f.budget = const RangeValues(0, 500);
              }),
              child: const Text('Reset', style: TextStyle(color: AppColors.camel)),
            ),
          ]),
          _title('Budget: ${f.budget.start.round()} – ${f.budget.end >= 500 ? '500+' : f.budget.end.round()} TND'),
          RangeSlider(
            values: f.budget,
            min: 0,
            max: 500,
            divisions: 50,
            activeColor: AppColors.camel,
            onChanged: (v) => setState(() => f.budget = v),
          ),
          _title('Colours'),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final c in colors)
              GestureDetector(
                onTap: () => _toggle(f.colors, c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: HelperFunctions.getColor(c) ?? Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: f.colors.contains(c) ? AppColors.camel : context.line, width: f.colors.contains(c) ? 3 : 1),
                  ),
                  child: f.colors.contains(c) ? Icon(Icons.check, size: 16, color: c == 'white' || c == 'cream' || c == 'beige' ? AppColors.ink : Colors.white) : null,
                ),
              ),
          ]),
          _title('Style'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in styles.entries)
              FilterChip(label: Text(e.value), selected: f.styles.contains(e.key), onSelected: (_) => _toggle(f.styles, e.key)),
          ]),
          _title('Size'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in sizes) FilterChip(label: Text(s), selected: f.sizes.contains(s), onSelected: (_) => _toggle(f.sizes, s)),
          ]),
          _title('For'),
          Wrap(spacing: 8, children: [
            for (final e in genders.entries)
              ChoiceChip(label: Text(e.value), selected: f.gender == e.key, onSelected: (sel) => setState(() => f.gender = sel ? e.key : null)),
          ]),
          const SizedBox(height: 26),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Show results')),
        ],
      ),
    );
  }
}
