import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:snap2chef/core/extensions/format_to_mb.dart';
import 'package:snap2chef/infrastructure/image_upload_controller.dart';
import 'package:snap2chef/infrastructure/recipe_controller.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/enums/status.dart';
import '../components/toast_info.dart';
import '../widgets/glowing_microphone.dart';
import '../widgets/image_previewer.dart';
import '../widgets/query_text_box.dart';
import '../widgets/upload_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? selectedFile;
  Completer? completer;
  String? fileName;
  int? fileSize;
  late GenerativeModel _model;
  String apiKey = "";
  final TextEditingController _query = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool isRecording = false;
  bool isDoneRecording = false;

  void removeText() {
    setState(() {
      _query.clear();
      isDoneRecording = false;
      _lastWords = "";
    });
    _query.clear();
  }

  void setKeyword(String prompt) {
    if (prompt.isEmpty) {
      toastInfo(msg: "You didn't say anything!", status: Status.error);
      setState(() {
        isDoneRecording = false;
        isRecording = false;
      });
      return;
    }

    setState(() {
      _lastWords = "";
      isRecording = false;
      _query.text = prompt;
      isDoneRecording = true;
    });
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );
      if (!_speechEnabled) {
        toastInfo(
          msg: "Microphone permission not granted or speech not available.",
          status: Status.error,
        );
      }
      setState(() {});
    } catch (e) {
      debugPrint("Speech initialization failed: $e");
    }
  }

  void _startListening() async {
    setState(() {
      isRecording = true;
    });
    if (!_speechEnabled) {
      toastInfo(msg: "Speech not initialized yet.", status: Status.error);
      return;
    }

    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setKeyword(_lastWords);
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
    _model = GenerativeModel(model: AppStrings.AI_MODEL, apiKey: apiKey);

    _initSpeech();
  }

  @override
  void dispose() {
    super.dispose();
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
      floatingActionButton: selectedFile != null || _query.text.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => RecipeController.sendRequest(
                context,
                selectedFile,
                _model,
                removeFile,
                _query.text,
                removeText,
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
              if (!isDoneRecording)
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
                if (!isDoneRecording) ...[
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
                        if (!_speechEnabled) {
                          toastInfo(
                            msg: "Speech recognition not ready yet.",
                            status: Status.error,
                          );
                          return;
                        }
                        if (_speechToText.isNotListening) {
                          _startListening();
                        } else {
                          _stopListening();
                        }
                      },
                      child: GlowingMicButton(
                        isListening: !_speechToText.isNotListening,
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
                  const Gap(10),
                ],

                isDoneRecording
                    ? QueryTextBox(query: _query)
                    : SizedBox.shrink(),
              ],

              const Gap(20),
              selectedFile != null || _query.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        if (selectedFile != null) {
                          removeFile();
                        } else {
                          removeText();
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: AppColors.primaryColor,
                        radius: 30,
                        child: Icon(Iconsax.close_circle, color: Colors.white),
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

