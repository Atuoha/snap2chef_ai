class Recording {
  String id;
  String filePath;
  String dateTime;
  bool isPlaying;


  factory Recording.initialize() {
    return Recording(id: '', filePath: '', dateTime: '');
  }

  Recording({
    required this.id,
    required this.filePath,
    required this.dateTime,
    this.isPlaying = false,
  });

  void toggleIsPlaying() {
    isPlaying = !isPlaying;
  }
}