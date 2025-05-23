import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../domain/model/recording.dart';

class AudioRecordingController {
  static Future<String> getRecordingFilePath(Uuid uid) async {
    final uidString = uid.v4();
    Directory baseDir;

    if (Platform.isAndroid) {
      baseDir = (await getExternalStorageDirectory())!;
    } else if (Platform.isIOS) {
      baseDir = await getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError("Recording not supported on this platform");
    }

    final recordsDir = Directory('${baseDir.path}/records');
    await recordsDir.create(recursive: true);
    return '${recordsDir.path}/$uidString.wav';
  }

  // start recording
  static Future<void> startRecording(
    AudioRecorder audioRecord,
    RecorderController recorderController,
    Function startRecordingSetups,
    Uuid uid,
  ) async {
    if (await audioRecord.hasPermission()) {
      try {
        final externalDir = await getExternalStorageDirectory();
        final recordsDir = Directory('${externalDir?.path}/records');
        await recordsDir.create(recursive: true);

        final filePath = await getRecordingFilePath(uid);
        await recorderController.record(
          path: filePath,
          bitRate: 128000,
          sampleRate: 44100,
        );
        startRecordingSetups(filePath);
      } catch (e) {
        if (kDebugMode) {
          print('Error recording: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('No Permission');
      }
    }
  }

  // stop recording
  static Future<void> stopRecording(
    AudioRecorder audioRecord,
    RecorderController recorderController,
    Uuid uid,
    Function stopRecordingSetups,
  ) async {
    try {
      final path = await audioRecord.stop();
      String currentDateTime = DateFormat(
        'E, MMM d, y h:mma',
      ).format(DateTime.now());

      await recorderController.stop();
      Recording newRecording = Recording(
        id: uid.v4(),
        filePath: path!,
        dateTime: currentDateTime,
      );

      stopRecordingSetups(newRecording);
    } catch (e) {
      if (kDebugMode) {
        print('error stopping recording');
      }
    }
  }

  // playPause Recording
  static Future<void> playPauseRecording(Recording recording, AudioPlayer audioPlayer, Function pauseRecordingSetups) async {
    await audioPlayer.stop();
    recording.toggleIsPlaying();

    if (recording.isPlaying) {
      Source urlSource = UrlSource(recording.filePath);
      await audioPlayer.play(urlSource);

      audioPlayer.onPlayerComplete.listen((event) {
        pauseRecordingSetups();
      });
    } else {
      await audioPlayer.pause();
    }
  }
}
