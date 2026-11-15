import 'dart:typed_data';

import 'package:find_me/data/findme_api.dart';
import 'package:find_me/data/models.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

/// Visual Fashion Search: take / pick a photo, the vision model describes the garment,
/// the recommendation engine finds the closest products in the catalogue.
class VisualSearchScreen extends StatefulWidget {
  const VisualSearchScreen({super.key});
  @override
  State<VisualSearchScreen> createState() => _VisualSearchScreenState();
}

class _VisualSearchScreenState extends State<VisualSearchScreen> {
  Uint8List? _image;
  VisualSearchResult? _result;
  String? _error;
  bool _loading = false;

  Future<void> _pick(ImageSource source) async {
    final x = await ImagePicker().pickImage(source: source, maxWidth: 1280, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes(); // works on mobile and web
    setState(() {
      _image = bytes;
      _result = null;
      _error = null;
      _loading = true;
    });
    try {
      final r = await FindMeApi.instance.visualSearch(bytes, x.name.isEmpty ? 'photo.jpg' : x.name);
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Find similar')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 6, 20, 40), children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: context.line)),
            clipBehavior: Clip.antiAlias,
            child: _image == null
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.image_search_rounded, size: 48, color: AppColors.camel),
                    const SizedBox(height: 10),
                    Text('Snap a garment you love', style: AppTheme.display(20, color: context.fg)),
                    const SizedBox(height: 4),
                    Text('FINDME finds similar items in the shops', style: context.text.bodySmall),
                  ])
                : Stack(fit: StackFit.expand, children: [
                    Image.memory(_image!, fit: BoxFit.cover),
                    if (_loading)
                      Container(
                        color: Colors.black.withOpacity(0.35),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const CircularProgressIndicator(color: AppColors.cream),
                          const SizedBox(height: 12),
                          const Text('Analysing the style…', style: TextStyle(color: AppColors.cream, fontFamily: 'Poppins')),
                        ]),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms, color: Colors.white24),
                  ]),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: ElevatedButton.icon(onPressed: _loading ? null : () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Camera'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Gallery'))),
        ]),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 20), child: Text(_error!, style: const TextStyle(color: Color(0xFFB3261E)))),
        if (r != null && !r.isFashion)
          const Padding(padding: EdgeInsets.only(top: 24), child: Text("We couldn't detect a fashion item. Try a closer photo of the garment.")),
        if (r != null && r.isFashion) ...[
          const SizedBox(height: 22),
          Text('Detected', style: context.text.labelSmall),
          const SizedBox(height: 6),
          if (r.description != null) Text(r.description!, style: context.text.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final t in [if (r.type != null) r.type!, ...r.colors, ...r.styles]) Chip(label: Text(t)),
          ]),
          const SizedBox(height: 10),
          if (r.products.isEmpty)
            const EmptyState(icon: Icons.search_off_rounded, title: 'No similar item', message: 'Nothing close enough is in the catalogue yet.')
          else ...[
            Text('Closest matches', style: AppTheme.display(22, color: context.fg)),
            const SizedBox(height: 12),
            ProductGrid(r.products, heroPrefix: 'visual', padding: EdgeInsets.zero),
          ],
        ],
      ]),
    );
  }
}
