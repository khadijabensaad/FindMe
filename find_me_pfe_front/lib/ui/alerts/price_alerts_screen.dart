import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Smart Wishlist: price-drop alerts.
class PriceAlertsScreen extends StatefulWidget {
  const PriceAlertsScreen({super.key});
  @override
  State<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends State<PriceAlertsScreen> {
  late Future<(List<PriceAlertItem>, int)> _future = FindMeApi.instance.alerts();

  @override
  void initState() {
    super.initState();
    _future.then((_) => FindMeApi.instance.markAlertsSeen()).catchError((_) {});
  }

  void _reload() => setState(() => _future = FindMeApi.instance.alerts());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Price alerts')),
      body: FutureBuilder<(List<PriceAlertItem>, int)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: AppColors.camel));
          if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: _reload);
          final (alerts, _) = snap.data!;
          if (alerts.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No price alerts',
              message: 'On any product, tap the bell to be notified when the price drops to your target.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final a = alerts[i];
              return Dismissible(
                key: ValueKey(a.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(color: const Color(0xFFC0502E), borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                ),
                onDismissed: (_) {
                  setState(() => alerts.removeAt(i));
                  FindMeApi.instance.deleteAlert(a.id);
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => openProduct(context, a.product, heroTag: 'alert-${a.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: a.reached ? AppColors.success : context.line, width: a.reached ? 1.6 : 1),
                    ),
                    child: Row(children: [
                      SizedBox(width: 70, height: 90, child: Hero(tag: 'alert-${a.id}', child: AppNetworkImage(a.product.thumbnail, radius: 12))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                          const SizedBox(height: 4),
                          Text('Now ${formatPrice(a.currentPrice)} TND · target ${formatPrice(a.targetPrice)} TND', style: context.text.bodySmall),
                          const SizedBox(height: 8),
                          if (a.reached)
                            Row(children: [
                              const Icon(Icons.trending_down_rounded, color: AppColors.success, size: 18),
                              const SizedBox(width: 4),
                              Text(a.dropPercent > 0 ? 'Price dropped ${a.dropPercent}%!' : 'Target reached!',
                                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                            ]).animate().fadeIn().then().shimmer(duration: 1200.ms)
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: a.priceAtCreation <= a.targetPrice ? 1.0 : ((a.priceAtCreation - a.currentPrice) / (a.priceAtCreation - a.targetPrice)).clamp(0.0, 1.0).toDouble(),
                                minHeight: 6,
                                color: AppColors.camel,
                                backgroundColor: context.line,
                              ),
                            ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
