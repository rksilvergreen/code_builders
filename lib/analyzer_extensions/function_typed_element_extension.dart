part of code_builders;

extension FunctionTypedElementExtension on FunctionTypedElement {
  List<ParameterElement> getParametersAnnotatedWith<T>({bool withTypeParams = false}) =>
      parameters.where((parameter) => parameter.isAnnotated<T>(withTypeParams: withTypeParams)).toList();

  List<TypeParameterElement> getTypeParametersAnnotatedWith<T>({bool withTypeParams = false}) =>
      typeParameters.where((typeParameter) => typeParameter.isAnnotated<T>(withTypeParams: withTypeParams)).toList();
}

// class XOP {
//   final String name;

//   const XOP({this.name = 'XOP'});
// }

// @XOP()
// class SomeClass<@XOP()T> {

//   @XOP()
//   void someMethod(@XOP()int number) {

//     @XOP()
//     var x = 5;
//   }
// }
