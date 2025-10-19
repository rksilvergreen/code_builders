part of code_builder;

abstract class BufferWritable {
  void _writeToBuffer(StringBuffer b);
}

extension BufferWritableIterableExtension on Iterable<BufferWritable> {
  void _writeToBuffer(StringBuffer b) => forEach((e) => e._writeToBuffer(b));
}

abstract class PublicBufferWritable extends BufferWritable {
  void writeToBuffer(StringBuffer b) => _writeToBuffer(b);
}

extension PublicBufferWritableIterableExtension on Iterable<PublicBufferWritable> {
  void writeToBuffer(StringBuffer b) => forEach((e) => e.writeToBuffer(b));
}