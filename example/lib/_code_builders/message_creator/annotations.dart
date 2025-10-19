
enum MessageFormat {
  elaborate,
  concise;
}

class Message {
  final int duplicates;
  final MessageFormat format;
  final Extra? extra;
  final List<Signature> signatures;

  const Message({required this.duplicates, required this.format, this.extra, required this.signatures});

  @override
  String toString() {
    return 'Message(duplicates: $duplicates, format: $format, extra: $extra, signatures: $signatures)';
  }

}

class Extra {
  final String prefix;
  final String suffix;

  const Extra({required this.prefix, required this.suffix});

  @override
  String toString() {
    return 'Extra(prefix: $prefix, suffix: $suffix)';
  }
}

class Signature {
  final String name;
  final bool isApproved;

  const Signature({required this.name, required this.isApproved});

  @override
  String toString() {
    return 'Signature(name: $name, isApproved: $isApproved)';
  }
}
