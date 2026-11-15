import 'package:find_me/data/findme_api.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/profile/style_dna_screen.dart';
import 'package:find_me/widgets/colors_help.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AI Style Quiz — 5 quick steps that bootstrap the Style DNA (solves the cold-start problem).
class StyleQuizScreen extends StatefulWidget {
  const StyleQuizScreen({super.key});
  @override
  State<StyleQuizScreen> createState() => _StyleQuizScreenState();
}

class _StyleQuizScreenState extends State<StyleQuizScreen> {
  final _pages = PageController();
  int _step = 0;
  bool _saving = false;

  final Set<String> _styles = {};
  final Set<String> _colors = {};
  final Set<String> _types = {};
  final Set<String> _occasions = {};
  String? _gender;
  RangeValues _budget = const RangeValues(30, 200);

  static const _styleOptions = [
    ('minimalist', 'Minimalist', 'Clean lines, neutral colours, essentials', Icons.crop_square_rounded),
    ('elegant', 'Elegant', 'Chic, classy, refined pieces', Icons.diamond_outlined),
    ('casual', 'Casual', 'Comfortable, relaxed, everyday', Icons.weekend_outlined),
    ('sporty', 'Sporty', 'Athletic, sneakers, athleisure', Icons.directions_run_rounded),
    ('trendy', 'Trendy', 'Bold, modern, street style', Icons.bolt_rounded),
  ];
  static const _colorOptions = ['black', 'white', 'beige', 'grey', 'brown', 'cream', 'red', 'pink', 'blue', 'light blue', 'green', 'yellow', 'purple', 'gold', 'silver'];
  static const _typeOptions = [
    ('dress', 'Dresses'),
    ('tshirt', 'T-shirts & tops'),
    ('shirt', 'Shirts'),
    ('jeans', 'Jeans'),
    ('pants', 'Pants'),
    ('skirt', 'Skirts'),
    ('jacket', 'Jackets'),
    ('shoes', 'Shoes'),
    ('bag', 'Bags'),
    ('necklace', 'Jewelry'),
    ('sportswear', 'Sportswear'),
  ];
  static const _occasionOptions = [
    ('everyday', 'Everyday'),
    ('work', 'Work'),
    ('party', 'Parties'),
    ('wedding', 'Weddings'),
    ('sport', 'Sport'),
    ('beach', 'Holidays'),
  ];

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _styles.isNotEmpty;
      case 1:
        return _colors.isNotEmpty;
      case 2:
        return _types.isNotEmpty;
      default:
        return true;
    }
  }

  void _next() {
    if (_step < 4) {
      _pages.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await FindMeApi.instance.saveQuiz({
        'styles': _styles.toList(),
        'colors': _colors.toList(),
        'types': _types.toList(),
        'occasions': _occasions.toList(),
        'gender': _gender,
        'budgetMin': _budget.start.round(),
        'budgetMax': _budget.end.round(),
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (_) => const StyleDnaScreen()));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  void _toggle(Set<String> set, String v) => setState(() {
        if (!set.remove(v)) set.add(v);
      });

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Style quiz · ${_step + 1}/5'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (_step + 1) / 5),
            duration: const Duration(milliseconds: 300),
            builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 3, color: AppColors.camel, backgroundColor: context.line),
          ),
        ),
      ),
      body: PageView(
        controller: _pages,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _step = i),
        children: [
          _page('Which styles feel like you?', 'Pick one or more', Column(children: [
            for (final (key, label, desc, icon) in _styleOptions)
              _optionCard(label, desc, icon, _styles.contains(key), () => _toggle(_styles, key)),
          ])),
          _page('Your favourite colours', 'The colours you wear the most', Wrap(spacing: 14, runSpacing: 14, children: [
            for (final c in _colorOptions)
              GestureDetector(
                onTap: () => _toggle(_colors, c),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: HelperFunctions.getColor(c) ?? Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: _colors.contains(c) ? AppColors.camel : context.line, width: _colors.contains(c) ? 3.5 : 1),
                    ),
                    child: _colors.contains(c) ? Icon(Icons.check_rounded, color: ['white', 'cream', 'beige', 'yellow', 'light blue'].contains(c) ? AppColors.ink : Colors.white) : null,
                  ),
                  const SizedBox(height: 4),
                  Text(c, style: context.text.labelSmall),
                ]),
              ),
          ])),
          _page('What do you shop the most?', 'We will prioritise these items', Wrap(spacing: 8, runSpacing: 10, children: [
            for (final (key, label) in _typeOptions)
              FilterChip(label: Text(label), selected: _types.contains(key), onSelected: (_) => _toggle(_types, key)),
          ])),
          _page('Your usual budget', 'Per item, in Tunisian dinars', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_budget.start.round()} – ${_budget.end.round()} TND', style: AppTheme.display(34, color: context.fg)),
            const SizedBox(height: 20),
            RangeSlider(values: _budget, min: 0, max: 600, divisions: 60, activeColor: AppColors.camel, onChanged: (v) => setState(() => _budget = v)),
          ])),
          _page('Occasions & fit', 'Optional, but it helps the stylist', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 10, children: [
              for (final (key, label) in _occasionOptions)
                FilterChip(label: Text(label), selected: _occasions.contains(key), onSelected: (_) => _toggle(_occasions, key)),
            ]),
            const SizedBox(height: 26),
            Text('I mostly shop for', style: context.text.titleSmall),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              for (final (key, label) in const [('women', 'Women'), ('men', 'Men'), ('kids', 'Kids')])
                ChoiceChip(label: Text(label), selected: _gender == key, onSelected: (s) => setState(() => _gender = s ? key : null)),
            ]),
          ])),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(children: [
            if (_step > 0)
              TextButton(onPressed: () => _pages.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut), child: const Text('Back')),
            const Spacer(),
            ElevatedButton(
              onPressed: !_canContinue || _saving ? null : _next,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream))
                  : Text(_step < 4 ? 'Continue' : 'Reveal my Style DNA'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _page(String title, String subtitle, Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTheme.display(28, color: context.fg)).animate().fadeIn(duration: 350.ms).slideY(begin: 0.2),
        const SizedBox(height: 4),
        Text(subtitle, style: context.text.bodySmall),
        const SizedBox(height: 22),
        Expanded(child: SingleChildScrollView(child: child)),
      ]),
    );
  }

  Widget _optionCard(String label, String desc, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : context.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.ink : context.line),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? AppColors.camel : context.fg),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: selected ? AppColors.cream : context.fg)),
              Text(desc, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: selected ? AppColors.cream.withOpacity(0.7) : context.fgMuted)),
            ]),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.camel, key: ValueKey(1)) : const SizedBox(key: ValueKey(0), width: 24),
          ),
        ]),
      ),
    );
  }
}
