import 'package:code_builders/code_builder.dart';
import 'annotations.dart';

part 'converters.dart';

Builder apiEndpointBuilder(BuilderOptions options) => CodeBuilder(
      name: 'api_endpoint',
      buildExtensions: {
        '{{dir}}/{{file}}.dart': ['{{dir}}/.gen/{{file}}.gen.api_endpoint.dart']
      },
      dartObjectConverters: _dartObjectConverters,
      build: (buildStep) async {
        LibraryElement library = await buildStep.resolver.libraryFor(buildStep.inputId);

        // Collect all abstract classes annotated with @ApiEndpoint
        List<ClassElement> apiClasses =
            library.getAllClassesAnnotatedWith<ApiEndpoint>().where((c) => c.isAbstract).toList();

        if (apiClasses.isEmpty) {
          return null;
        }

        final buffer = StringBuffer();

        final partOf = PartOf.fromBuildStep(buildStep);
        partOf.writeToBuffer(buffer);
        buffer.writeln();

        // Generate implementation for each API class
        for (final classElement in apiClasses) {
          final annotation = classElement.getAnnotationOf<ApiEndpoint>()!;
          _generateApiImplementation(buffer, classElement, annotation);
          buffer.writeln();
        }

        return buffer;
      },
    );

void _generateApiImplementation(
  StringBuffer buffer,
  ClassElement classElement,
  ApiEndpoint annotation,
) {
  final className = classElement.name!;
  final implClassName = '${className}Impl';

  // Find the abstract method (should be only one)
  final method = classElement.methods.firstWhere((m) => m.isAbstract);
  final methodName = method.name;
  final returnType = method.returnType.getDisplayString();

  // Generate the implementation class
  final implClass = Class(
    name: implClassName,
    implementations: [className],
    properties: [
      Property(
        Final: true,
        type: 'String',
        name: 'baseUrl',
      ),
      if (annotation.auth != null && annotation.auth!.tokenField != null)
        Property(
          Final: true,
          type: 'String?',
          name: annotation.auth!.tokenField!,
        ),
    ],
    constructors: [
      Constructor(
        Const: true,
        className: implClassName,
        parameters: [
          ConstructorParameter(
            assigned: true,
            type: 'String',
            name: 'baseUrl',
            named: true,
            Required: true,
          ),
          if (annotation.auth != null && annotation.auth!.tokenField != null)
            ConstructorParameter(
              assigned: true,
              type: 'String?',
              name: annotation.auth!.tokenField!,
              named: true,
            ),
        ],
      ),
    ],
    methods: [
      Method(
        override: true,
        returnType: returnType,
        name: methodName!,
        parameters: method.formalParameters.map((p) {
          return MethodParameter(
            type: p.type.getDisplayString(),
            name: p.name!,
            named: p.isNamed,
            Required: p.isRequiredNamed,
            optional: p.isOptionalPositional,
          );
        }).toList(),
        async: true,
        body: (b) => _generateMethodBody(b, method, annotation),
      ),
    ],
  );

  implClass.writeToBuffer(buffer);
}

void _generateMethodBody(
  StringBuffer b,
  MethodElement method,
  ApiEndpoint annotation,
) {
  // Build the URL
  b.writeln('// Build URL');
  b.write('var url = baseUrl + \'${annotation.path}\'');

  // Replace path parameters
  for (final pathParam in annotation.pathParams) {
    b.write('.replaceAll(\'{${pathParam.name}}\', ${pathParam.name}.toString())');
  }
  b.writeln(';');
  b.writeln();

  // Add query parameters
  if (annotation.queryParams.isNotEmpty) {
    b.writeln('// Add query parameters');
    b.writeln('final queryParams = <String, String>{};');
    for (final entry in annotation.queryParams.entries) {
      final paramName = entry.key;
      final queryParam = entry.value;

      if (queryParam.required) {
        b.writeln('queryParams[\'$paramName\'] = $paramName.toString();');
      } else if (queryParam.defaultValue != null) {
        b.writeln('queryParams[\'$paramName\'] = ($paramName ?? ${queryParam.defaultValue}).toString();');
      } else {
        b.writeln('if ($paramName != null) queryParams[\'$paramName\'] = $paramName.toString();');
      }
    }
    b.writeln('if (queryParams.isNotEmpty) {');
    b.writeln('  url += \'?\' + queryParams.entries.map((e) => \'\${e.key}=\${e.value}\').join(\'&\');');
    b.writeln('}');
    b.writeln();
  }

  // Build headers
  b.writeln('// Build headers');
  b.writeln('final headers = <String, String>{};');
  for (final entry in annotation.headers.entries) {
    final headerName = entry.key;
    final header = entry.value;
    var headerValue = header.value;

    // Handle token replacement in header values
    if (annotation.auth != null &&
        annotation.auth!.tokenField != null &&
        headerValue.contains('{${annotation.auth!.tokenField}}')) {
      headerValue = headerValue.replaceAll('{${annotation.auth!.tokenField}}', '\$${annotation.auth!.tokenField}');
    }

    b.writeln('headers[\'$headerName\'] = \'$headerValue\';');
  }

  if (annotation.includeTimestamp) {
    b.writeln('headers[\'X-Timestamp\'] = DateTime.now().toIso8601String();');
  }
  b.writeln();

  // Build request body
  if (annotation.requestBody != null) {
    b.writeln('// Build request body');
    final requestBody = annotation.requestBody!;

    if (requestBody.contentType == ContentType.json) {
      b.writeln('final body = {');
      for (final entry in requestBody.fields.entries) {
        final fieldName = entry.key;
        final mapping = entry.value;
        final jsonKey = mapping.jsonKey ?? fieldName;

        // Assume request parameter name matches field name
        b.writeln('  \'$jsonKey\': request.$fieldName,');
      }
      b.writeln('};');
      b.writeln();
    }
  }

  // Make HTTP request (simplified - would use http package in reality)
  b.writeln('// Make HTTP request');
  b.writeln('// In a real implementation, this would use the http package');
  b.writeln('// For now, returning mock response');
  b.writeln();

  // Build response object
  final responseFields = annotation.responseMapping.fields;
  final returnTypeName = method.returnType.element?.name ?? 'dynamic';

  b.writeln('// Parse response (mock)');
  b.writeln('final responseData = <String, dynamic>{};');
  b.writeln('return $returnTypeName(');
  for (final entry in responseFields.entries) {
    final fieldName = entry.key;
    final mapping = entry.value;
    final jsonKey = mapping.jsonKey ?? fieldName;

    if (mapping.type == 'DateTime') {
      b.writeln('  $fieldName: DateTime.parse(responseData[\'$jsonKey\']),');
    } else {
      b.writeln('  $fieldName: responseData[\'$jsonKey\'] as ${mapping.type},');
    }
  }
  b.write(');');
}
