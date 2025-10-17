part of dart_source_builder;

class DartObjectConverter<T> {
  final Type type = T;
  final T Function(DartObject) convert;

  DartObjectConverter(this.convert);
}

DartObjectConverter<Duration> durationDartObjectConverter = DartObjectConverter<Duration>((dartObject) => Duration(
      microseconds: dartObject.getFieldValue('_duration') as int,
    ));

enum Color {
  red,
  green,
  blue,
}

DartObjectConverter<Color> colorDartObjectConverter =
    DartObjectConverter<Color>((dartObject) => Color.values.firstWhere((e) => e.name == dartObject.toString()));
