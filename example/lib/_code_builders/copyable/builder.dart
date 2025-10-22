import 'package:code_builders/code_builder.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'annotations.dart';

part 'converters.dart';

Builder copyableBuilder(BuilderOptions options) => CodeBuilder(
      name: 'copyable',
      buildExtensions: {
        '{{dir}}/{{file}}.dart': ['{{dir}}/_gen/{{file}}.gen.copyable.dart']
      },
      dartObjectConverters: _dartObjectConverters,
      build: (buildStep) async {
        LibraryElement library = await buildStep.resolver.libraryFor(buildStep.inputId);

        // Collect all classes annotated with @Copyable
        List<ClassElement> copyableClasses = library.getAllClassesAnnotatedWith<Copyable>();

        if (copyableClasses.isEmpty) {
          return null;
        }

        final buffer = StringBuffer();

        // Add part of directive using PartOf class
        final partOf = PartOf.fromBuildStep(buildStep);
        partOf.writeToBuffer(buffer);

        // Generate extensions/mixins for each annotated class
        for (final classElement in copyableClasses) {
          final annotation = classElement.getAnnotationOf<Copyable>()!;

          // Get all fields from the class
          final fields = classElement.fields.where((field) {
            // Skip static fields
            if (field.isStatic) return false;

            // Skip synthetic fields (like enum values)
            if (field.isSynthetic) return false;

            // Skip private fields unless includePrivateFields is true
            final fieldName = field.name;
            if (fieldName != null && fieldName.startsWith('_') && !annotation.includePrivateFields) return false;

            return true;
          }).toList();

          if (annotation.style == GenerationStyle.extension) {
            _generateExtension(buffer, classElement, annotation, fields);
          } else {
            _generateMixin(buffer, classElement, annotation, fields);
          }

          buffer.writeln();
        }

        return buffer;
      },
    );

void _generateExtension(
  StringBuffer buffer,
  ClassElement classElement,
  Copyable annotation,
  List<FieldElement> fields,
) {
  final className = classElement.name!;
  final extensionName = annotation.nameSuffix ?? '${className}Copyable';

  final extension = Extension(
    extensionName: extensionName,
    extendedType: className,
    methods: [
      _generateCopyWithMethod(classElement, annotation, fields),
      if (annotation.nullableStrategy == NullableStrategy.separateMethod)
        _generateCopyWithNullMethod(classElement, annotation, fields),
    ],
  );

  extension.writeToBuffer(buffer);
}

void _generateMixin(
  StringBuffer buffer,
  ClassElement classElement,
  Copyable annotation,
  List<FieldElement> fields,
) {
  final className = classElement.name!;
  final mixinName = annotation.nameSuffix ?? '${className}CopyableMixin';

  // For mixins, specify the class it can be mixed into using 'on' constraint
  final mixin = Mixin(
    name: mixinName,
    on: [className],
    methods: [
      _generateCopyWithMethod(classElement, annotation, fields),
      if (annotation.nullableStrategy == NullableStrategy.separateMethod)
        _generateCopyWithNullMethod(classElement, annotation, fields),
    ],
  );

  mixin.writeToBuffer(buffer);
}

Method _generateCopyWithMethod(
  ClassElement classElement,
  Copyable annotation,
  List<FieldElement> fields,
) {
  final className = classElement.name!;

  // Build parameters list (excluding fields marked with @CopyableField(exclude: true) or immutable: true)
  final parameters = <MethodParameter>[];
  final assignments = <String>[];

  for (final field in fields) {
    final fieldAnnotation = field.getAnnotationOf<CopyableField>();

    // Check if field should be excluded
    final shouldExclude = fieldAnnotation?.exclude == true || fieldAnnotation?.immutable == true;

    if (!shouldExclude) {
      final paramName = fieldAnnotation?.parameterName ?? field.name!;
      final fieldType = field.type.getDisplayString();

      // Make parameter nullable if the field is nullable
      final isNullable = field.type.nullabilitySuffix == NullabilitySuffix.question;
      final paramType = isNullable ? fieldType : '$fieldType?';

      parameters.add(MethodParameter(
        type: paramType,
        name: paramName,
        named: true,
      ));

      // Generate assignment logic
      final customExpression = fieldAnnotation?.customCopyExpression;
      if (customExpression != null) {
        // Wrap custom expression in parentheses to ensure proper precedence
        assignments.add('${field.name}: $paramName ?? ($customExpression)');
      } else {
        assignments.add('${field.name}: $paramName ?? this.${field.name}');
      }
    } else {
      // Field is excluded, just use current value
      assignments.add('${field.name}: this.${field.name}');
    }
  }

  return Method(
    returnType: className,
    name: 'copyWith',
    parameters: parameters,
    body: (b) {
      b.write('return $className(');
      b.write(assignments.join(', '));
      b.write(');');
    },
  );
}

Method _generateCopyWithNullMethod(
  ClassElement classElement,
  Copyable annotation,
  List<FieldElement> fields,
) {
  final className = classElement.name!;

  final assignments = <String>[];

  for (final field in fields) {
    final fieldAnnotation = field.getAnnotationOf<CopyableField>();
    final shouldExclude = fieldAnnotation?.exclude == true || fieldAnnotation?.immutable == true;

    // Check if type is nullable by checking nullability suffix
    final isNullable = field.type.nullabilitySuffix == NullabilitySuffix.question;

    if (!shouldExclude && isNullable) {
      final paramName = fieldAnnotation?.parameterName ?? field.name;
      assignments.add('${field.name}: fieldNames.contains(\'$paramName\') ? null : this.${field.name}');
    } else {
      assignments.add('${field.name}: this.${field.name}');
    }
  }

  return Method(
    returnType: className,
    name: 'copyWithNull',
    parameters: [
      MethodParameter(
        type: 'List<String>',
        name: 'fieldNames',
        named: false,
      ),
    ],
    body: (b) {
      b.write('return $className(');
      b.write(assignments.join(', '));
      b.write(');');
    },
  );
}
