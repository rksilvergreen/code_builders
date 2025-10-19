import 'package:code_builders/code_builder.dart';
import 'annotations.dart';

part 'converters.dart';

Builder {{builder_name.camelCase()}}Builder(BuilderOptions options) => CodeBuilder(
      name: '{{builder_name.snakeCase()}}_builder',
      buildExtensions: {
        '{{dir}}/{{file}}.dart': ['{{dir}}/.gen/{{file}}.gen.{{builder_name.snakeCase()}}.dart']
      },
      dartObjectConverters: _dartObjectConverters,
      build: (buildStep) async {
        return null;
      },
    );
