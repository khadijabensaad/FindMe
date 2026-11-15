import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/main_screen.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Asks for an outfit name (used by Complete the Look and the stylist).
Future<String?> promptOutfitName(BuildContext context, String suggestion) {
  final ctrl = TextEditingController(text: suggestion.length > 40 ? suggestion.substring(0, 40) : suggestion);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.bg,
      title: Text('Save outfit', style: AppTheme.display(20, color: ctx.fg)),
      content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Outfit name')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? suggestion : ctrl.text.trim()), child: const Text('Save')),
      ],
    ),
  );
}

/// My Wardrobe (Outfit Planner): saved looks, favorites and your style at a glance.
class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});
  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen> {
  late Future<List<SavedOutfit>> _future = FindMeApi.instance.outfits();
  late Future<List<RecoProduct>> _favs = FindMeApi.instance.favorites();
  StyleDna? _dna;

  @override
  void initState() {
    super.initState();
    FindMeApi.instance.styleDna().then((d) {
      if (mounted) setState(() => _dna = d);
    }).catchError((_) {});
  }

  void _reload() => setState(() {
        _future = FindMeApi.instance.outfits();
        _favs = FindMeApi.instance.favorites();
      });

  void _askStylist() {
    Navigator.of(context).popUntil((r) => r.isFirst);
    ShellController.askStylist('Build me a complete outfit');
  }

  String _date(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = context.isDark ? AppColors.camel : AppColors.brown;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(children: [
            Icon(Icons.checkroom_rounded, color: iconColor),
            const SizedBox(width: 8),
            const Text('My Wardrobe'),
          ]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DecoratedBox(
                decoration: const BoxDecoration(gradient: AppColors.caramel, shape: BoxShape.circle),
                child: IconButton(tooltip: 'Create an outfit with the stylist', icon: const Icon(Icons.add_rounded, color: AppColors.ink), onPressed: _askStylist),
              ),
            ),
          ],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: context.line)),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(gradient: AppColors.caramel, borderRadius: BorderRadius.circular(AppRadius.xl)),
                labelColor: AppColors.ink,
                unselectedLabelColor: context.fgMuted,
                labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [Tab(text: 'Saved Looks'), Tab(text: 'Favorites')],
              ),
            ),
          ),
          Expanded(child: TabBarView(children: [_looksTab(), _favoritesTab()])),
        ]),
      ),
    );
  }

  Widget _createBanner() {
    return GestureDetector(
      onTap: _askStylist,
      child: Container(
        height: 130,
        decoration: BoxDecoration(color: context.isDark ? AppColors.nightCard : AppColors.peach, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset('assets/images/Capture.PNG', fit: BoxFit.contain),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Create Your Outfit', style: AppTheme.display(19, color: context.fg)),
                const SizedBox(height: 4),
                Text('The AI stylist builds a complete look for you.', style: context.text.bodySmall),
                const SizedBox(height: 8),
                Row(children: [
                  Text('Start', style: context.text.titleSmall?.copyWith(color: context.accentText)),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: context.accentText),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _styleCard() {
    final d = _dna;
    if (d == null || d.signals == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: context.line), boxShadow: AppColors.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your Style', style: context.text.labelMedium?.copyWith(color: context.accentText)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.workspace_premium_rounded, color: AppColors.camel),
          const SizedBox(width: 8),
          Expanded(child: Text(d.persona, style: AppTheme.display(18, color: context.fg))),
          Text('${(d.confidence * 100).round()}% match', style: context.text.bodySmall),
        ]),
        if (d.topColors.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Your favorite colors', style: context.text.bodySmall),
          const SizedBox(height: 6),
          ColorDots(d.topColors, size: 26),
        ],
      ]),
    );
  }

  Widget _looksTab() {
    return FutureBuilder<List<SavedOutfit>>(
      future: _future,
      builder: (context, snap) {
        final header = <Widget>[_createBanner(), _styleCard(), const SizedBox(height: 18)];
        if (snap.connectionState != ConnectionState.done) {
          return ListView(padding: const EdgeInsets.all(20), children: [...header, const SkeletonBox(height: 180)]);
        }
        if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: _reload);
        final outfits = snap.data!;
        return RefreshIndicator(
          color: AppColors.camel,
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              ...header,
              if (outfits.isEmpty)
                Text('No saved look yet. Open a product and tap "Save outfit" under Complete the look.', style: context.text.bodySmall),
              for (var i = 0; i < outfits.length; i++) _outfitCard(outfits, i),
            ],
          ),
        );
      },
    );
  }

  Widget _outfitCard(List<SavedOutfit> outfits, int i) {
    final o = outfits[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Dismissible(
        key: ValueKey(o.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(color: const Color(0xFFC0502E), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        onDismissed: (_) {
          setState(() => outfits.removeAt(i));
          FindMeApi.instance.deleteOutfit(o.id);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: context.line), boxShadow: AppColors.softShadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(o.name, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (o.plannedFor != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.camel.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                  child: Text(_date(o.plannedFor!), style: TextStyle(color: context.accentText, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(width: 8),
              Text('${formatPrice(o.totalPrice)} TND', style: context.text.titleSmall?.copyWith(color: context.accentText)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: o.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, j) {
                  final p = o.items[j].product;
                  return GestureDetector(
                    onTap: () => openProduct(context, p, heroTag: 'outfit-${o.id}-${p.id}'),
                    child: SizedBox(width: 90, child: Hero(tag: 'outfit-${o.id}-${p.id}', child: AppNetworkImage(p.thumbnail, radius: 14))),
                  );
                },
              ),
            ),
          ]),
        ),
      ).animate(delay: (60 * i).ms).fadeIn().slideY(begin: 0.06),
    );
  }

  Widget _favoritesTab() {
    return FutureBuilder<List<RecoProduct>>(
      future: _favs,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: AppColors.camel));
        if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: _reload);
        final list = snap.data!;
        if (list.isEmpty) {
          return const EmptyState(icon: Icons.favorite_border_rounded, title: 'No favorites yet', message: 'Tap the heart on any product to keep it here.');
        }
        return SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 16), child: ProductGrid(list, heroPrefix: 'wardrobe'));
      },
    );
  }
}
