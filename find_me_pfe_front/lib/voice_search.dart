<<<<<<< HEAD
import 'package:find_me/chatbot.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:find_me/ui/widgets/voice_input.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Voice Fashion Assistant: speak naturally, e.g.
/// « Je cherche une robe rouge pour une soirée à moins de 100 dinars ».
/// With [returnResult] the transcript is returned to the caller, otherwise it opens the AI stylist.
class VoiceSearch extends StatefulWidget {
  final bool returnResult;
  const VoiceSearch({super.key, this.returnResult = false});
  @override
  State<VoiceSearch> createState() => _VoiceSearchState();
}

class _VoiceSearchState extends State<VoiceSearch> {
  final _voice = VoiceInput.instance;
  String _text = '';
  bool _unavailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _voice.stop();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _text = '');
    final ok = await _voice.start(onText: (t, isFinal) {
      if (!mounted) return;
      setState(() => _text = t);
      if (isFinal && t.trim().isNotEmpty) _finish();
    });
    if (!ok && mounted) setState(() => _unavailable = true);
  }

  Future<void> _finish() async {
    await _voice.stop();
    if (!mounted || _text.trim().isEmpty) return;
    if (widget.returnResult) {
      Navigator.of(context).pop(_text.trim());
    } else {
      Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (_) => ChatbotPage(initialPrompt: _text.trim())));
    }
  }
=======
import 'package:find_me/widgets/drawerwidget.dart';
import 'package:flutter/material.dart';

class VoiceSearch extends StatelessWidget {
  const VoiceSearch({super.key});
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(
        title: const Text('Voice search'),
        actions: [
          ValueListenableBuilder<String>(
            valueListenable: _voice.locale,
            builder: (_, loc, __) => TextButton(
              onPressed: () async {
                _voice.cycleLocale();
                await _voice.stop();
                _start();
              },
              child: Text(VoiceInput.localeLabels[loc] ?? loc, style: const TextStyle(color: AppColors.camel)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(children: [
          const Spacer(),
          Text(
            _unavailable
                ? 'Speech recognition is not available on this device.'
                : _text.isEmpty
                    ? 'Say what you are looking for…'
                    : '“$_text”',
            textAlign: TextAlign.center,
            style: AppTheme.display(26, color: context.fg, height: 1.3),
          ),
          const SizedBox(height: 12),
          Text('e.g. “A red dress for a party under 100 dinars”', textAlign: TextAlign.center, style: context.text.bodySmall),
          const Spacer(),
          ValueListenableBuilder<bool>(
            valueListenable: _voice.listening,
            builder: (_, listening, __) => ValueListenableBuilder<double>(
              valueListenable: _voice.level,
              builder: (_, level, __) {
                final glow = listening ? (12 + level.clamp(0, 10) * 3).toDouble() : 0.0;
                return GestureDetector(
                  onTap: listening ? _finish : _start,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.caramel,
                      boxShadow: [BoxShadow(color: AppColors.camel.withOpacity(0.45), blurRadius: glow, spreadRadius: glow / 3)],
                    ),
                    child: Icon(listening ? Icons.graphic_eq_rounded : Icons.mic_rounded, color: Colors.white, size: 44),
                  ),
                ).animate(target: listening ? 1.0 : 0.0).scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06));
              },
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: _voice.listening,
            builder: (_, l, __) => Text(l ? 'Listening… tap to finish' : 'Tap to speak', style: context.text.labelMedium),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}
=======
      backgroundColor: Color(0xFFFDF1E1),
      appBar: AppBar(
        title: Text("Voice Search",style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.black,
                  fontSize: 18)),
                  centerTitle: true,
                  backgroundColor: Color(0xFFFDF1E1),
      ),
      drawer: DrawerWidget(),
    body: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("Press The Button To Start Speaking", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 24),textAlign: TextAlign.center,),
        RoundedImageButton(
                image: 'assets/images/mic.png',
                onPressed: () {
                  // Add your button functionality here
                  print('Button pressed!');
                },
              ),
      ],
    ),),
    );
  }
}

class RoundedImageButton extends StatelessWidget {
  final String image;
  final VoidCallback onPressed;

  RoundedImageButton({
    required this.image,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              image,
              width: 140,
              height: 140,
            ),
          ),
        ),
      ),
    );
  }
}
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
