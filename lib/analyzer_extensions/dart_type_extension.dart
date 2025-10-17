part of dart_source_builder;

extension DartTypeExtension on DartType {
  bool isType<T>({bool withTypeParams = false}) {
    String firstType = getDisplayString();
    String secondType = '$T';
    return _isSameType(firstType, secondType, withTypeParams);
  }

  bool isDartType(DartType dartType, {bool withTypeParams = false}) {
    String firstType = '$this';
    String secondType = '$dartType';
    return _isSameType(firstType, secondType, withTypeParams);
  }
}

bool _isSameType(String firstType, String secondType, bool withTypeParams) {
  if (withTypeParams) {
    return firstType == secondType;
  } else {
    int firstIndex = firstType.indexOf('<');
    int secondIndex = secondType.indexOf('<');

    if (firstIndex != -1) firstType = firstType.substring(0, firstIndex);
    if (secondIndex != -1) secondType = secondType.substring(0, secondIndex);
    return firstType == secondType;
  }
}
