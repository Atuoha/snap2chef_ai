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
import '../presentation/components/toast_info.dart';

class RecipeController {
  // send image to gemini
  static Future<void> _sendImageToGemini(
    File? selectedFile,
    GenerativeModel model,
    BuildContext context,
    Function removeFile,
    Function removeText,
  ) async {
    toastInfo(msg: "Obtaining recipe and preparations", status: Status.success);
    
    if (selectedFile == null) return;

    final bytes = await selectedFile.readAsBytes();

    final prompt = TextPart(AppStrings.AI_TEXT_PART);
    final image = DataPart('image/jpeg', bytes);

    final response = await model.generateContent([
      Content.multi([prompt, image]),
    ]);

    if (context.mounted) {
      _displayRecipe(
        response.text,
        context,
        selectedFile,
        removeFile,
        removeText,
      );
    }
  }

  // send audio text prompt
  static Future<void> _sendAudioTextPrompt(
    GenerativeModel model,
    BuildContext context,
    String transcribedText,
    File? selectedFile,
    Function removeFile,
    Function removeText,
  ) async {
    toastInfo(msg: "Obtaining recipe and preparations", status: Status.success);

    final prompt = '${AppStrings.AI_AUDIO_PART} ${transcribedText.trim()}.';
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (context.mounted) {
      _displayRecipe(
        response.text,
        context,
        selectedFile,
        removeFile,
        removeText,
      );
    }
  }

  static void _displayRecipe(
    String? recipeText,
    BuildContext context,
    File? selectedFile,
    Function removeFile,
    Function removeText,
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
                if (selectedFile != null) {
                  removeFile();
                } else {
                  removeText();
                }
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
    GenerativeModel model,
    Function removeFile,
    String transcribedText,
    Function removeText,
  ) async {
    context.showLoader();
    toastInfo(msg: "Processing...", status: Status.success);
    try {
      if (selectedFile != null) {
        await _sendImageToGemini(
          selectedFile,
          model,
          context,
          removeFile,
          removeText,
        );
      } else if (transcribedText.isNotEmpty) {
        await _sendAudioTextPrompt(
          model,
          context,
          transcribedText,
          selectedFile,
          removeFile,
          removeText,
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
