// ignore_for_file: prefer_single_quotes

class FormatError implements Exception {
  FormatError(this.message);
  final String message;

  @override
  String toString() {
    return "FormatError: $message";
  }
}
