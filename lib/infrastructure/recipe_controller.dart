import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gap/gap.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:snap2chef/core/extensions/loading.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/enums/status.dart';
import '../domain/model/recording.dart';
import '../presentation/components/toast_info.dart';

class RecipeController {


  // send image to gemini
  static Future<void> _sendImageToGemini(
    File? selectedFile,
    GenerativeModel model,
    BuildContext context,
    Function removeFile,
  ) async {
    if (selectedFile == null) return;

    final bytes = await selectedFile.readAsBytes();

    final prompt = TextPart(AppStrings.AI_TEXT_PART);
    final image = DataPart('image/jpeg', bytes);

    final response = await model.generateContent([
      Content.multi([prompt, image]),
    ]);

    if (context.mounted) {
      _displayRecipe(response.text, context, selectedFile, removeFile);
    }
  }

  // transcribe audio and send to gemini
  static Future<void> _transcribeAudioAndSendToGemini(
    GenerativeModel model,
    BuildContext context,
    File? selectedFile,
    Recording recording,
    Function removeFile,
  ) async {
    toastInfo(msg: "Transcribing audio...", status: Status.success);
    File file = File(recording.filePath);
    final bytes = await file.readAsBytes();
    final audio = DataPart('audio/mpeg', bytes);

    final response = await model.generateContent([
      Content.multi([
        TextPart(
          "Please transcribe this voice note and generate a recipe from it.",
        ),
        audio,
      ]),
    ]);

    if (context.mounted) {
      _displayRecipe(response.text, context, selectedFile, removeFile);
    }
  }

  static void _displayRecipe(
    String? recipeText,
    BuildContext context,
    File? selectedFile,
    Function removeFile,
  ) {
    if (recipeText == null || recipeText.isEmpty) {
      recipeText = "No recipe could be generated or parsed from the response.";
    }
    if (kDebugMode) {
      print("Recipe Text: $recipeText");
    }
    String workingRecipeText = recipeText;

    // Remove youtube url and prepare youtube url
    final youtubeUrlRegex = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:m\.)?(?:youtube\.com|youtu\.be)\/(?:watch\?v=|embed\/|v\/|)([\w-]{11})(?:\S+)?',
      caseSensitive: false,
    );

    String? videoId;

    final match = youtubeUrlRegex.firstMatch(recipeText);
    if (kDebugMode) {
      print("Match: $match");
    }
    if (match != null && match.groupCount >= 1) {
      videoId = match.group(1)?.trim();
      workingRecipeText = recipeText.replaceAll(youtubeUrlRegex, '').trim();
    }
    if (kDebugMode) {
      print("Youtube ID: $videoId");
    }

    String? cleanedRecipeText = workingRecipeText;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        YoutubePlayerController? ytController;

        if (videoId != null) {
          ytController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              disableDragSeek: false,
              loop: false,
              isLive: false,
              forceHD: false,
              enableCaption: true,
            ),
          );
        }

        return AlertDialog(
          title: const Text('Generated Recipe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                selectedFile != null
                    ? Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: AppColors.primaryColor),
                          image: DecorationImage(
                            image: FileImage(File(selectedFile.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
                Gap(16),
                MarkdownBody(
                  data: cleanedRecipeText,
                  styleSheet: MarkdownStyleSheet(
                    h1: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    h2: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    strong: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                if (videoId != null && ytController != null) ...[
                  const Gap(16),
                  YoutubePlayer(
                    controller: ytController,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: AppColors.primaryColor,
                    progressColors: const ProgressBarColors(
                      playedColor: AppColors.primaryColor,
                      handleColor: Colors.amberAccent,
                    ),
                    onReady: () {
                      // Controller is ready
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                ytController?.dispose();
                Navigator.of(dialogContext).pop();
                removeFile();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void sendRequest(
    BuildContext context,
    File? selectedFile,
    bool isDoneRecording,
    Recording recording,
    GenerativeModel model,
    Function removeFile,
  ) async {
    context.showLoader();
    toastInfo(msg: "Processing", status: Status.success);
    try {
      if (selectedFile != null) {
        await _sendImageToGemini(selectedFile, model, context, removeFile);
      } else if (isDoneRecording && recording.filePath.isNotEmpty) {
        await _transcribeAudioAndSendToGemini(
          model,
          context,
          selectedFile,
          recording,
          removeFile,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending request: $e');
      }
      toastInfo(msg: "Error sending request:$e ", status: Status.error);
    } finally {
      if (context.mounted) {
        context.hideLoader();
      }
    }
  }
}
