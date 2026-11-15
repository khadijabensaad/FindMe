import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Thin wrapper around speech_to_text used by the AI stylist and the voice search page.
class VoiceInput {
  VoiceInput._();
  static final VoiceInput instance = VoiceInput._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;

  /// Locales the user can cycle through (long-press on the mic).
  static const locales = ['fr_FR', 'en_US', 'ar_TN'];
  static const localeLabels = {'fr_FR': 'Français', 'en_US': 'English', 'ar_TN': 'العربية'};
  final ValueNotifier<String> locale = ValueNotifier('fr_FR');
  final ValueNotifier<bool> listening = ValueNotifier(false);
  final ValueNotifier<double> level = ValueNotifier(0);

  Future<bool> init() async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize(
        onStatus: (s) => listening.value = s == 'listening',
        onError: (_) => listening.value = false,
      );
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  void cycleLocale() {
    final i = locales.indexOf(locale.value);
    locale.value = locales[(i + 1) % locales.length];
  }

  /// Starts listening. [onText] receives partial and final transcripts.
  Future<bool> start({required void Function(String text, bool isFinal) onText}) async {
    if (!await init()) return false;
    await _speech.listen(
      localeId: locale.value,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: (l) => level.value = l,
      onResult: (SpeechRecognitionResult r) => onText(r.recognizedWords, r.finalResult),
    );
    listening.value = true;
    return true;
  }

  Future<void> stop() async {
    await _speech.stop();
    listening.value = false;
  }
}
