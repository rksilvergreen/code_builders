
enum MessageFormat {
  elaborate,
  concise;
}

class Message {
  final int duplicates;
  final MessageFormat format;
  final Extra? extra;

  const Message({required this.duplicates, required this.format, this.extra});

}

class Extra {
  final String prefix;
  final String suffix;

  const Extra({required this.prefix, required this.suffix});
}
