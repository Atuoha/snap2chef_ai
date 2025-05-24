// ignore_for_file: constant_identifier_names

class AppStrings {
  static const String AI_MODEL = 'gemini-2.0-flash';

  static const String APP_SUBTITLE =  "Capture a photo or use your voice to get step-by-step guidance on how to prepare your favorite dishes or snacks";
  static const String APP_TITLE = "Your Personal AI Recipe Guide";

  static const String AI_TEXT_PART = "You are a recipe ai expert. Generate a recipe based on this image, include recipe name, preparation steps, and a public YouTube video demonstrating the preparation step."
      "If the image is not a food, snacks or drink, politely inform the user that you can only answer recipe queries and ask them to close and upload a food/snack/drink image.";

  static const String AI_AUDIO_PART =
  "You are a recipe ai expert. Generate a recipe based on this text, include recipe name, preparation steps. I'd also love for you to show me any valid image online relating to this food/drink/snack and a public YouTube video demonstrating the preparation step.If the text doesn't contain things related to a food, snacks or drink, politely inform the user that you can only answer recipe queries and ask them to close and upload a food/snack/drink image. Output the YouTube video URL on a new line prefixed with 'YouTube Video URL: ', it should be a https URL and the image URL on a new line prefixed with 'Image URL: ' and it should be a https URL too, The text is: ";

}
