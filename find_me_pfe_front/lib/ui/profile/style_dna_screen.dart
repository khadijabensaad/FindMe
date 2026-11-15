import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/profile/style_quiz_screen.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AI Style DNA — computed from real signals (favorites, views, chats, quiz).
class StyleDnaScreen extends StatefulWidget {
  const StyleDnaScreen({super.key});

  static String styleLabel(String s) => const {
        'minimalist': 'Minimalist',
        'elegant': 'Elegant',
        'casual': 'Casual',
        'sporty': 'Sporty',
        'trendy': 'Trendy',
      }[s] ??
      s;

  static String typeLabel(String t) => const {
        'tshirt': 'T-shirts',
        'dress': 'Dresses',
        'shoes': 'Shoes',
        'bag': 'Bags',
        'pants': 'Pants',
        'jeans': 'Jeans',
        'shirt': 'Shirts',
        'jacket': 'Jackets',
        'skirt': 'Skirts',
        'shorts': 'Shorts',
        'sportswear': 'Sportswear',
        'necklace': 'Necklaces',
        'bracelet': 'Bracelets',
        'ring': 'Rings',
        'earrings': 'Earrings',
        'watch': 'Watches',
        'accessory': 'Accessories',
        'cosmetics': 'Beauty',
      }[t] ??
      t;

  @override
  State<StyleDnaScreen> createState() => _StyleDnaScreenState();
}

class _StyleDnaScreenState extends State<StyleDnaScreen> {
  late Future<StyleDna> _future = FindMeApi.instance.styleDna();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<StyleDna>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: AppColors.camel));
          if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: () => setState(() => _future = FindMeApi.instance.styleDna()));
          final d = snap.data!;
          final styles = d.styles.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          return ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 40), children: [
            Text('YOUR STYLE DNA', textAlign: TextAlign.center, style: context.text.labelSmall?.copyWith(letterSpacing: 2, color: AppColors.camel)),
            const SizedBox(height: 8),
            Text(d.persona, textAlign: TextAlign.center, style: AppTheme.display(36, color: context.fg)).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 4),
            Text('Your fashion personality', textAlign: TextAlign.center, style: context.text.bodySmall),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.line)),
                child: Text('Confidence ${(d.confidence * 100).round()}% · ${d.signals} signals', style: context.text.labelSmall),
              ),
            ),
            const SizedBox(height: 26),
            Text('Your style preferences', style: context.text.titleMedium),
            const SizedBox(height: 12),
            for (var i = 0; i < styles.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(StyleDnaScreen.styleLabel(styles[i].key), style: context.text.bodyMedium)),
                    Text('${styles[i].value}%', style: context.text.titleSmall),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: styles[i].value / 100),
                      duration: Duration(milliseconds: 700 + 120 * i),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 10, color: i == 0 ? AppColors.brown : AppColors.camel.withOpacity(0.75), backgroundColor: context.line),
                    ),
                  ),
                ]),
              ),
            if (d.topColors.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Your favorite colours', style: context.text.titleMedium),
              const SizedBox(height: 12),
              Row(children: [ColorDots(d.topColors, size: 34)]),
            ],
            if (d.topTypes.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text('What you love', style: context.text.titleMedium),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final t in d.topTypes) Chip(label: Text(StyleDnaScreen.typeLabel(t)))]),
            ],
            if (d.topBrands.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text('Brands you like', style: context.text.titleMedium),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final b in d.topBrands) Chip(label: Text(b.toUpperCase()))]),
            ],
            if (d.budgetMax != null) ...[
              const SizedBox(height: 22),
              Text('Usual budget', style: context.text.titleMedium),
              const SizedBox(height: 6),
              Text('${formatPrice(d.budgetMin ?? 0)} – ${formatPrice(d.budgetMax!)} TND', style: AppTheme.display(24, color: context.fg)),
            ],
            const SizedBox(height: 28),
            Text(
              'Computed from your favorites, the products you open, your conversations with the stylist and your quiz answers. Recent signals count more.',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.quiz_outlined),
              label: Text(d.hasQuiz ? 'Retake the style quiz' : 'Take the style quiz'),
              onPressed: () async {
                await Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const StyleQuizScreen()));
                setState(() => _future = FindMeApi.instance.styleDna());
              },
            ),
          ]);
        },
      ),
    );
  }
}
