# Code Builder

A code generation library for Dart that provides a flexible framework for creating custom builders with the Dart build system.

This library extends the [build] package to simplify code generation by providing utilities for working with directives, creating code structures, and managing package dependencies.

## Key Features

- Customizable input matching with glob patterns
- Automatic code formatting with dart_style
- Support for imports, exports, parts, and part-of directives
- Generated file headers and error handling

## Usage

```dart
final builder = CodeBuilder(
  name: 'my_generator',
  buildExtensions: {
    'lib/models/*.dart': ['lib/generated/*.g.dart']
  },
  build: (buildStep) async {
    final buffer = StringBuffer();
    buffer.writeln('// Generated code');
    return buffer;
  },
);
```

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  code_builders: ^0.1.0
```
