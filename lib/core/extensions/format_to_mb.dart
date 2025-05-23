extension ByTeToMegaByte on int {
  int formatToMegaByte() {
    int bytes = this;
    return (bytes / (1024 * 1024)).ceil();
  }
}
