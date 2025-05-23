import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

extension XFileExtension on XFile {
  Future<File> toFile() async {
    final bytes = await readAsBytes();
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${this.name}');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }
}
