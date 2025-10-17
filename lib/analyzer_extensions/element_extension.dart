import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'dart_type_extension.dart';
import 'dart_object_extension.dart';

extension ElementExtension on Element {
  bool isAnnotated<T>({bool withTypeParams = false}) => metadata.any((elementAnnotation) {
        DartType? annotationType = elementAnnotation.computeConstantValue()?.type;
        if (annotationType == null) return false;
        return annotationType.isType<T>(withTypeParams: withTypeParams);
      });

  List<DartObject> getAllAnnotationDartObjects() => metadata
      .map((elementAnnotation) => elementAnnotation.computeConstantValue())
      .where((dartObject) => dartObject != null)
      .cast<DartObject>()
      .toList();

  List<DartObject> getAllAnnotationDartObjectsOf<T>({bool withTypeParameters = false}) => getAllAnnotationDartObjects()
      .where((dartObject) => dartObject.type!.isType<T>(withTypeParams: withTypeParameters))
      .cast<DartObject>()
      .toList();

  List<dynamic> getAllAnnotations() => getAllAnnotationDartObjects().map((dartObject) => getValue(dartObject)).toList();

  List<T> getAllAnnotationsOf<T>({bool withTypeParameters = false}) =>
      getAllAnnotationDartObjectsOf<T>(withTypeParameters: withTypeParameters)
          .map((dartObject) => getValue(dartObject))
          .cast<T>()
          .toList();

  T? getAnnotationOf<T>({bool withTypeParameters = false}) =>
      getAllAnnotationsOf<T>(withTypeParameters: withTypeParameters).firstOrNull;
}
