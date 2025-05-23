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
import 'package:snap2chef/infrastructure/speech_to_text_controller.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/enums/status.dart';
import '../components/toast_info.dart';
import '../widgets/glowing_microphone.dart';
import '../widgets/image_previewer.dart';
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

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: AppStrings.AI_MODEL, apiKey: apiKey);
    SpeechToTextController.initSpeech(_speechToText, (enabled) {
      setState(() {
        _speechEnabled = enabled;
      });
    });
  }

  // remove text
  void removeText() {
    setState(() {
      _query.clear();
      isDoneRecording = false;
    });
  }

  // set keyword
  void setKeyword() {
    if (_lastWords.isEmpty) {
      toastInfo(msg: "You didn't say anything!", status: Status.error);
      setState(() {
        isDoneRecording = false;
        isRecording = false;
      });
      return;
    }

    setState(() {
      isRecording = false;
      _query.text = _lastWords;
      isDoneRecording = true;
      _lastWords = "";
    });
  }

  // set recording to true
  void setRecording() {
    setState(() {
      isRecording = true;
      isDoneRecording = false;
    });
  }

  // set new state
  void setNewState() {
    setState(() {});
  }

  // set last words
  void setLastWords(String words) {
    setState(() {
      _lastWords = words;
    });
  }

  // assign cropped image
  void assignCroppedImage(CroppedFile? croppedFile) {
    if (croppedFile != null) {
      setState(() {
        selectedFile = File(croppedFile.path);
      });
    }
  }

  // set file
  void setFile(File? pickedFile) {
    setState(() {
      selectedFile = pickedFile;
      fileName = pickedFile?.path.split('/').last;
      fileSize = pickedFile?.lengthSync().formatToMegaByte();
    });
  }

  // remove file
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
                          SpeechToTextController.startListening(
                            setRecording,
                            _speechEnabled,
                            _speechToText,
                            setNewState,
                          );
                        } else {
                          SpeechToTextController.stopListening(
                            _speechToText,
                            setKeyword,
                            setNewState,
                          );
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
                    ? TextFormField(
                        controller: _query,
                        maxLines: 4,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(color: AppColors.lighterGrey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.primaryColor,
                              width: 2.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.black,
                        ),
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                      )
                    : SizedBox.shrink(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
