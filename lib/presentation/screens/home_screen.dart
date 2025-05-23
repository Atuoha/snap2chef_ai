import 'dart:async';
import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:record/record.dart';
import 'package:snap2chef/core/extensions/format_to_mb.dart';
import 'package:snap2chef/infrastructure/audio_recording_controller.dart';
import 'package:snap2chef/infrastructure/image_upload_controller.dart';
import 'package:snap2chef/infrastructure/recipe_controller.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/model/recording.dart';
import '../widgets/image_previewer.dart';
import '../widgets/upload_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final RecorderController recorderController;
  File? selectedFile;
  Completer? completer;
  String? fileName;
  int? fileSize;
  late AudioPlayer audioPlayer;
  late AudioRecorder audioRecord;
  bool isRecording = false;
  String? audioPath;
  late Uuid uid;
  bool isDoneRecording = false;
  Recording recording = Recording.initialize();
  late GenerativeModel _model;
  String apiKey = "";

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioRecord = AudioRecorder();
    uid = const Uuid();

    recorderController = RecorderController()
      ..updateFrequency = const Duration(milliseconds: 50);
    _model = GenerativeModel(model: AppStrings.AI_MODEL, apiKey: apiKey);

    _initSpeech();
  }

  @override
  void dispose() {
    super.dispose();
    audioRecord.dispose();
    audioPlayer.dispose();
  }

  void assignCroppedImage(CroppedFile? croppedFile) {
    if (croppedFile != null) {
      setState(() {
        selectedFile = File(croppedFile.path);
      });
    }
  }

  void setFile(File? pickedFile) {
    setState(() {
      selectedFile = pickedFile;
      fileName = pickedFile?.path.split('/').last;
      fileSize = pickedFile?.lengthSync().formatToMegaByte();
    });
  }

  void startRecordingSetups(String filePath) {
    setState(() {
      isRecording = true;
      isDoneRecording = false;
      audioPath = filePath;
    });
  }

  void stopRecordingSetups(Recording newRecording) {
    setState(() {
      recording = newRecording;
    });

    setState(() {
      isRecording = false;
      isDoneRecording = true;
    });
  }

  void pauseRecordingSetups() {
    setState(() {
      recording.isPlaying = false;
    });
  }

  void removeFile() {
    setState(() {
      selectedFile = null;
      fileSize = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);

    return Scaffold(
      floatingActionButton: selectedFile != null
          ? FloatingActionButton.extended(
              onPressed: () => RecipeController.sendRequest(
                context,
                selectedFile,
                isDoneRecording,
                recording,
                _model,
                removeFile,
              ),
              backgroundColor: AppColors.primaryColor,
              icon: const Icon(Iconsax.send_1, color: Colors.white),
              label: const Text(
                "Send Request",
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.APP_TITLE,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              Text(
                AppStrings.APP_SUBTITLE,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Gap(20),
              !isRecording
                  ? selectedFile != null
                        ? ImagePreviewer(
                            size: size,
                            pickedFile: selectedFile,
                            removeFile: removeFile,
                            context: context,
                            completer: completer,
                            setFile: setFile,
                            assignCroppedImage: assignCroppedImage,
                          )
                        : GestureDetector(
                            onTap: () =>
                                ImageUploadController.showFilePickerButtonSheet(
                                  context,
                                  completer,
                                  setFile,
                                  assignCroppedImage,
                                ),
                            child: UploadContainer(
                              title: 'an image of a food or snack',
                              size: size,
                            ),
                          )
                  : SizedBox.shrink(),
              const Gap(20),

              if (selectedFile == null) ...[
                Text(
                  "or record your voice",
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      if (isRecording) {
                        AudioRecordingController.stopRecording(
                          audioRecord,
                          recorderController,
                          uid,
                          stopRecordingSetups,
                        );
                      } else {
                        AudioRecordingController.startRecording(
                          audioRecord,
                          recorderController,
                          startRecordingSetups,
                          uid,
                        );
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: AppColors.primaryColor,
                      radius: 30,
                      child: Center(
                        child: Icon(
                          isRecording ? Iconsax.stop : Iconsax.microphone,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),


                Center(
                  child: GestureDetector(
                    onTap:(){
                      if (_speechToText.isNotListening) {
                        _startListening();
                      } else {
                        _stopListening();
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: AppColors.primaryColor,
                      radius: 30,
                      child: Center(
                        child: Icon(
                          _speechToText.isNotListening ? Iconsax.stop : Iconsax.microphone,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const Gap(10),
                Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    _speechToText.isListening
                        ? _lastWords
                        : _speechEnabled
                        ? 'Tap the microphone to start listening...'
                        : 'Speech not available',
                  ),
                ),
              ],
              if (isRecording) ...[
                AudioWaveforms(
                  enableGesture: false,
                  size: Size(size.width, 100),
                  recorderController: recorderController,
                  waveStyle: const WaveStyle(
                    waveColor: Color(0xFFB39DDB), // light purple
                    showMiddleLine: true,
                    extendWaveform: true,
                    middleLineColor: Colors.deepPurple,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  margin: const EdgeInsets.only(top: 20),
                ),
              ],

              isDoneRecording
                  ? ListTile(
                      leading: const Icon(Icons.mic_none),
                      title: Text('Your Recording'),
                      subtitle: Text(recording.dateTime),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            icon: Icon(
                              recording.isPlaying
                                  ? Iconsax.pause
                                  : Iconsax.play,
                              color: AppColors.primaryColor,
                            ),
                            onPressed: () =>
                                AudioRecordingController.playPauseRecording(
                                  recording,
                                  audioPlayer,
                                  pauseRecordingSetups,
                                ),
                          ),
                          IconButton(
                            onPressed: () => RecipeController.sendRequest(
                              context,
                              selectedFile,
                              isDoneRecording,
                              recording,
                              _model,
                              removeFile,
                            ),
                            icon: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 3,
                              children: [
                                const Icon(
                                  Iconsax.send_1,
                                  color: AppColors.primaryColor,
                                ),
                                Text(
                                  "Send Request",
                                  style: TextStyle(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

