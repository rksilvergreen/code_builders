import 'package:analyzer/dart/constant/value.dart';
import 'dart_object_extension.dart';

class DartObjectConverter<T> {
  final Type type = T;
  final T Function(DartObject) convert;

  DartObjectConverter(this.convert);
}

DartObjectConverter<Duration> durationDartObjectConverter = DartObjectConverter<Duration>((dartObject) => Duration(
      microseconds: dartObject.getFieldValue('_duration') as int,
    ));