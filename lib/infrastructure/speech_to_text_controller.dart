import 'package:flutter/cupertino.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/constants/enums/status.dart';
import '../presentation/components/toast_info.dart';

class SpeechToTextController {
  static void initSpeech(
    SpeechToText speechToText,
    void Function(bool) setSpeechEnabled,
  ) async {
    try {
      final speechEnabled = await speechToText.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );
      setSpeechEnabled(speechEnabled);

      if (!speechEnabled) {
        toastInfo(
          msg: "Microphone permission not granted or speech not available.",
          status: Status.error,
        );
      }
    } catch (e) {
      debugPrint("Speech initialization failed: $e");
    }
  }

  static void startListening(
    Function setRecording,
    bool speechEnabled,
    SpeechToText speechToText,
    Function setNewState,
  ) async {
    setRecording();
    if (!speechEnabled) {
      toastInfo(msg: "Speech not initialized yet.", status: Status.error);
      return;
    }

    await speechToText.listen(
      onResult: (result) => onSpeechResult(result, setNewState),
    );
    setNewState();
  }

  static void stopListening(
    SpeechToText speechToText,
    setKeyword,
    Function setNewState,
  ) async {
    await speechToText.stop();
    setKeyword();
    setNewState();
  }

  static void onSpeechResult(SpeechRecognitionResult result, setLastWords) {
    setLastWords(result.recognizedWords);
  }
}
