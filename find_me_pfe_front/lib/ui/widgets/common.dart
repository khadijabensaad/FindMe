import 'package:cached_network_image/cached_network_image.dart';
import 'package:find_me/Core/Search/product_detail.dart';
import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/widgets/colors_help.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

String formatPrice(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

void openProduct(BuildContext context, RecoProduct p, {String? heroTag}) {
  FindMeApi.instance.track('click', productId: p.id);
  Navigator.of(context).push(CupertinoPageRoute(
    builder: (_) => ProductDetail(identifier: p.id, initial: p, heroTag: heroTag),
  ));
}

// ---------------------------------------------------------------------------
// Images & skeletons
// ---------------------------------------------------------------------------
class AppNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double radius;
  const AppNetworkImage(this.url, {super.key, this.fit = BoxFit.cover, this.radius = 0});

  @override
  Widget build(BuildContext context) {
    final img = url.isEmpty
        ? Container(color: context.line, child: Icon(Icons.checkroom_rounded, color: context.fgMuted, size: 36))
        : CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 250),
            placeholder: (_, __) => SkeletonBox(radius: radius),
            errorWidget: (_, __, ___) => Container(color: context.line, child: Icon(Icons.image_not_supported_outlined, color: context.fgMuted)),
          );
    return radius > 0 ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: img) : img;
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  const SkeletonBox({super.key, this.width, this.height, this.radius = AppRadius.md});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.isDark ? const Color(0xFF2A1F17) : const Color(0xFFF3E2CB),
      highlightColor: context.isDark ? const Color(0xFF3A2C21) : const Color(0xFFFFF7EC),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  final double width;
  const ProductCardSkeleton({super.key, this.width = 170});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : 170.0;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const AspectRatio(aspectRatio: 4 / 5, child: SkeletonBox(radius: AppRadius.lg)),
          const SizedBox(height: 10),
          SkeletonBox(width: w * 0.4, height: 10, radius: 6),
          const SizedBox(height: 6),
          SkeletonBox(width: w * 0.8, height: 12, radius: 6),
          const SizedBox(height: 6),
          SkeletonBox(width: w * 0.3, height: 12, radius: 6),
        ]);
      }),
    );
  }
}

class HorizontalSkeletonList extends StatelessWidget {
  final double height;
  const HorizontalSkeletonList({super.key, this.height = 300});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => const ProductCardSkeleton(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small atoms
// ---------------------------------------------------------------------------
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  final IconData? icon;
  const SectionHeader(this.title, {super.key, this.subtitle, this.action, this.onAction, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 10, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(title, style: AppTheme.display(22, color: context.fg))),
              const SizedBox(width: 6),
              Icon(icon ?? Icons.auto_awesome, size: 16, color: AppColors.camel),
            ]),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: context.text.bodySmall),
            ],
          ]),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: context.accentText),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(action!, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5)),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ]),
          ),
      ]),
    );
  }
}

class BadgePill extends StatelessWidget {
  final String label;
  const BadgePill(this.label, {super.key});

  static Color colorFor(String label) {
    switch (label) {
      case 'Best Match':
        return const Color(0xFFF6D3A6);
      case 'Trending':
        return const Color(0xFFF5D3CB);
      case 'Discount':
        return const Color(0xFFF7CFC4);
      case 'New':
        return const Color(0xFFDCEBDD);
      default:
        return AppColors.sand;
    }
  }

  static Color textFor(String label) {
    switch (label) {
      case 'Best Match':
        return const Color(0xFF7A4613);
      case 'Trending':
        return const Color(0xFF8A3B2C);
      case 'Discount':
        return const Color(0xFF9A2516);
      case 'New':
        return const Color(0xFF2F5E3E);
      default:
        return AppColors.ink;
    }
  }

  static IconData iconFor(String label) {
    switch (label) {
      case 'Best Match':
        return Icons.auto_awesome;
      case 'Trending':
        return Icons.local_fire_department_rounded;
      case 'Discount':
        return Icons.sell_rounded;
      case 'New':
        return Icons.fiber_new_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: colorFor(label), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(iconFor(label), size: 11, color: textFor(label)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: textFor(label))),
      ]),
    );
  }
}

class MatchPill extends StatelessWidget {
  final int percent;
  final bool dense;
  const MatchPill(this.percent, {super.key, this.dense = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(color: AppColors.ink.withOpacity(0.78), borderRadius: BorderRadius.circular(20)),
      child: Text('$percent% match',
          style: TextStyle(fontFamily: 'Poppins', fontSize: dense ? 10 : 11, fontWeight: FontWeight.w600, color: AppColors.cream)),
    );
  }
}

class PriceText extends StatelessWidget {
  final RecoProduct p;
  final double size;
  const PriceText(this.p, {super.key, this.size = 14});
  @override
  Widget build(BuildContext context) {
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
      Text('${formatPrice(p.effectivePrice)} TND',
          style: TextStyle(fontFamily: 'Poppins', fontSize: size, fontWeight: FontWeight.w700, color: p.hasDiscount ? const Color(0xFFA8321F) : context.fg)),
      if (p.hasDiscount)
        Text('${formatPrice(p.price)}',
            style: TextStyle(fontFamily: 'Poppins', fontSize: size - 3, color: context.fgMuted, decoration: TextDecoration.lineThrough)),
    ]);
  }
}

class ColorDots extends StatelessWidget {
  final List<String> colors;
  final double size;
  const ColorDots(this.colors, {super.key, this.size = 12});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final c in colors.take(5))
        Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: HelperFunctions.getColor(c) ?? Colors.grey,
            shape: BoxShape.circle,
            border: Border.all(color: context.line, width: 1),
          ),
        ),
    ]);
  }
}

/// Heart with a bounce micro-interaction; optimistic update + API call.
class FavoriteButton extends StatefulWidget {
  final RecoProduct product;
  final double size;
  final ValueChanged<bool>? onChanged;
  const FavoriteButton(this.product, {super.key, this.size = 36, this.onChanged});
  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
  ]).animate(_ctrl);
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final before = widget.product.isFavorite;
    setState(() {
      widget.product.isFavorite = !before;
      _busy = true;
    });
    _ctrl.forward(from: 0);
    try {
      final now = await FindMeApi.instance.toggleFavorite(widget.product.id);
      widget.product.isFavorite = now;
      widget.onChanged?.call(now);
    } catch (_) {
      widget.product.isFavorite = before;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update favorites')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fav = widget.product.isFavorite;
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: context.card.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ScaleTransition(
          scale: _scale,
          child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: widget.size * 0.52, color: fav ? const Color(0xFFC0502E) : AppColors.brown),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product card (vertical)
// ---------------------------------------------------------------------------
class ProductCard extends StatefulWidget {
  final RecoProduct product;
  final String heroPrefix;
  final double? width;
  final bool showMatch;
  final VoidCallback? onTap;
  const ProductCard(this.product, {super.key, this.heroPrefix = 'p', this.width, this.showMatch = true, this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final heroTag = '${widget.heroPrefix}-${p.id}';
    final badges = p.badges.take(2).toList();
    final open = widget.onTap ?? () => openProduct(context, p, heroTag: heroTag);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: open,
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.line),
            boxShadow: context.isDark ? null : AppColors.softShadow,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(children: [
                Positioned.fill(
                  child: Hero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(color: context.isDark ? AppColors.nightLine : const Color(0xFFF7EBDB), child: AppNetworkImage(p.thumbnail)),
                    ),
                  ),
                ),
                if (badges.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      for (final b in badges) Padding(padding: const EdgeInsets.only(bottom: 4), child: BadgePill(b)),
                    ]),
                  ),
                Positioned(top: 6, right: 6, child: FavoriteButton(p, size: 32)),
                if (widget.showMatch && p.matchPercent != null && p.matchPercent! > 0)
                  Positioned(left: 8, bottom: 8, child: MatchPill(p.matchPercent!, dense: true)),
                if (p.alternative)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(20)),
                      child: Text('Alternative', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: context.fgMuted)),
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 2, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.brand.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelSmall?.copyWith(letterSpacing: 0.8)),
                const SizedBox(height: 1),
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall?.copyWith(fontSize: 13)),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: PriceText(p, size: 13.5)),
                  Material(
                    color: AppColors.camel,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: open,
                      child: const SizedBox(width: 30, height: 30, child: Icon(Icons.shopping_bag_outlined, size: 17, color: AppColors.ink)),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Horizontal rail of product cards with staggered entrance.
class ProductRail extends StatelessWidget {
  final List<RecoProduct> products;
  final String heroPrefix;
  final double cardWidth;
  const ProductRail(this.products, {super.key, required this.heroPrefix, this.cardWidth = 165});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (cardWidth - 16) * 5 / 4 + 112,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => ProductCard(products[i], heroPrefix: heroPrefix, width: cardWidth)
            .animate(delay: (60 * i).ms)
            .fadeIn(duration: 350.ms)
            .slideX(begin: 0.08, curve: Curves.easeOutCubic),
      ),
    );
  }
}

/// Two-column grid that sizes itself (use inside slivers via SliverToBoxAdapter or directly).
class ProductGrid extends StatelessWidget {
  final List<RecoProduct> products;
  final String heroPrefix;
  final EdgeInsets padding;
  const ProductGrid(this.products, {super.key, required this.heroPrefix, this.padding = const EdgeInsets.symmetric(horizontal: 20)});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 14, childAspectRatio: 0.53),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductCard(products[i], heroPrefix: heroPrefix)
          .animate(delay: (40 * (i % 6)).ms)
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.06, curve: Curves.easeOutCubic),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: context.card, shape: BoxShape.circle, border: Border.all(color: context.line), boxShadow: AppColors.softShadow),
          child: Icon(icon, size: 36, color: AppColors.camel),
        ),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: AppTheme.display(22, color: context.fg)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.fgMuted)),
        if (action != null) ...[
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onAction, child: Text(action!)),
        ],
      ]).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96)),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Connection issue',
        message: message,
        action: 'Retry',
        onAction: onRetry,
      );
}
