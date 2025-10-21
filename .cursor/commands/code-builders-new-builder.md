# Create New Code Builder Command

This command creates a new code builder with all required files and configuration. The command accepts the builder name as an argument and handles the complete setup process.

## Command Usage

`@code-builders-new-builder <builder_name> [description]`

Examples:
- `@code-builders-new-builder user_validator`
- `@code-builders-new-builder message_creator "Creates message classes from annotated models"`

## What This Command Does

- Validates that code builders infrastructure is initialized
- Creates the builder directory structure in `lib/_code_builders/<builder_name>`
- Generates the three required builder files (annotations.dart, builder.dart, converters.dart)
- Optionally accepts a description to generate appropriate annotations and builder logic
- Updates the `build.yaml` configuration with the new builder

## Prerequisites Validation

Before creating the new builder, verify the following files and directories exist:

1. `build.yaml` in the package root
2. `mason.yaml` in the package root
3. `pubspec.yaml` with required dev_dependencies (build_runner, code_builders)
4. `lib/_code_builders/` directory

**If any prerequisites are missing:**
- Notify the user that code builders infrastructure is not initialized
- Ask if they want to run the initialization process first
- Wait for user confirmation before proceeding

## Builder Creation Process

### Step 1: Create Builder Directory

Create a new directory: `lib/_code_builders/<builder_name>/`

### Step 2: Attempt Mason Brick Generation

Try to run the mason command to generate the builder files:

```bash
mason make code_builder --builder_name <builder_name>
```

**If mason command fails or is not available:**
Proceed to manual file creation (Step 3)

### Step 3: Create Builder Files

Create three files in the `lib/_code_builders/<builder_name>/` directory. The content varies depending on whether a description was provided.

#### File 1: annotations.dart

**Without Description:**
Create an empty file (no content).

**With Description:**
Generate appropriate annotation classes based on the builder's purpose. These annotations will be imported by package files to mark classes for analysis by the builder.

Example for a message creator builder:

```dart
/// Marks a class to have messages generated from it
class Message {
  final int duplicates;
  final MessageFormat format;
  final Extra? extra;
  final List<Signature> signatures;

  const Message({
    required this.duplicates,
    required this.format,
    this.extra,
    required this.signatures,
  });
}

/// Message format options
enum MessageFormat {
  text,
  html,
  markdown,
}

/// Additional metadata for messages
class Extra {
  final String prefix;
  final String suffix;

  const Extra({
    required this.prefix,
    required this.suffix,
  });
}

/// Signature information
class Signature {
  final String name;
  final bool isApproved;

  const Signature({
    required this.name,
    required this.isApproved,
  });
}
```

**Key Principles for Annotations:**
- Create annotation classes that represent the metadata users will provide
- Keep annotations as simple as possible while achieving the user's goals
- Only include enums if there are truly predefined options to constrain
- Only use nested classes if the configuration complexity genuinely warrants it
- Use const constructors for compile-time constants
- Add documentation comments explaining each annotation's purpose
- **Avoid over-engineering**: Start simple and add complexity only when necessary

#### File 2: builder.dart

**Without Description:**
For a builder named `user_validator`, create a minimal template:

```dart
import 'package:code_builders/code_builder.dart';
import 'annotations.dart';

part 'converters.dart';

Builder userValidatorBuilder(BuilderOptions options) => CodeBuilder(
      name: 'user_validator_builder',
      buildExtensions: {
        '{{dir}}/{{file}}.dart': ['{{dir}}/.gen/{{file}}.gen.user_validator.dart']
      },
      dartObjectConverters: _dartObjectConverters,
      build: (buildStep) async {
        return null;
      },
    );
```

**With Description:**
Generate the builder with appropriate build logic based on the description. The build function should contain the code generation logic.

**IMPORTANT**: Always use the `code_builders` package's BufferWritable classes (Class, Method, Constructor, etc.) and analyzer_extensions to simplify and structure the code generation. Avoid manual string building with StringBuffer for class/method generation.

Example for a message creator builder:

```dart
import 'package:code_builders/code_builder.dart';
import 'annotations.dart';

part 'converters.dart';

Builder messageCreatorBuilder(BuilderOptions options) => CodeBuilder(
      name: 'message_creator_builder',
      buildExtensions: {
        '{{dir}}/{{file}}.dart': ['{{dir}}/.gen/{{file}}.gen.message_creator.dart']
      },
      dartObjectConverters: _dartObjectConverters,
      build: (buildStep) async {
        // Analyze annotated classes and generate message implementations
        final library = buildStep.inputLibrary;
        final buffer = StringBuffer();
        
        // Process each class annotated with @Message
        for (final element in library.topLevelElements) {
          if (element is ClassElement) {
            final messageAnnotation = element.getAnnotation<Message>();
            if (messageAnnotation != null) {
              _generateMessageClass(element, messageAnnotation).writeTo(buffer);
              buffer.writeln();
            }
          }
        }
        
        return buffer.toString();
      },
    );

/// Generates a message class from the annotated element using BufferWritable
Class _generateMessageClass(ClassElement element, Message annotation) {
  final className = element.name;
  
  return Class(
    name: 'Generated$className',
    properties: [
      Property(
        name: 'content',
        type: 'String',
        isFinal: true,
      ),
      Property(
        name: 'format',
        type: 'MessageFormat',
        isFinal: true,
      ),
      Property(
        name: 'duplicates',
        type: 'int',
        isFinal: true,
        defaultValue: '${annotation.duplicates}',
      ),
    ],
    constructors: [
      Constructor(
        isConst: true,
        parameters: [
          Parameter(
            name: 'content',
            isRequired: true,
            isNamed: true,
            prefix: 'this.',
          ),
          Parameter(
            name: 'format',
            isRequired: true,
            isNamed: true,
            prefix: 'this.',
          ),
          Parameter(
            name: 'duplicates',
            isRequired: true,
            isNamed: true,
            prefix: 'this.',
          ),
        ],
      ),
    ],
    methods: [
      Method(
        name: 'toJson',
        returnType: 'Map<String, dynamic>',
        body: '''
    return {
      'content': content,
      'format': format.name,
      'duplicates': duplicates,
    };
    ''',
      ),
    ],
  );
}
```

**Key Principles for Builder Logic:**
- **Always use BufferWritable classes**: Use `Class`, `Method`, `Constructor`, `Property`, `Getter`, `Setter`, etc. from `code_builders/buffer_writable`
- **Leverage analyzer_extensions**: Use extension methods like `element.getAnnotation<T>()`, `element.properties`, `element.methods`, etc.
- Access the input library via `buildStep.inputLibrary`
- Iterate through elements to find annotated classes
- Extract helper functions that return BufferWritable objects (e.g., `Class`, `Method`)
- Call `.writeTo(buffer)` on BufferWritable objects to generate code
- Keep code generation logic neat and readable by using structured classes instead of string concatenation
- Return the generated code as a string

**Template Pattern:**
- Replace `userValidator`/`messageCreator` with camelCase version of the builder name
- Replace `user_validator`/`message_creator` with snake_case version of the builder name
- Keep `{{dir}}` and `{{file}}` as literal strings

#### File 3: converters.dart

**Without Description:**
Create a minimal template:

```dart
part of 'builder.dart';

final _dartObjectConverters = <Type, DartObjectConverter>{};
```

**With Description:**
Generate converters for each annotation class defined in annotations.dart. Converters translate Dart analyzer's DartObject representations into your annotation types.

Example for message creator annotations:

```dart
part of 'builder.dart';

final _dartObjectConverters = {
  MessageFormat: _messageFormatDartObjectConverter,
  Extra: _extraDartObjectConverter,
  Signature: _signatureDartObjectConverter,
  Message: _messageDartObjectConverter,
};

// Converter for enum types - maps enum name to enum value
DartObjectConverter<MessageFormat> _messageFormatDartObjectConverter = 
    DartObjectConverter<MessageFormat>(
      (dartObject) => MessageFormat.values.firstWhere(
        (e) => e.name == dartObject.variable!.name
      )
    );

// Converter for simple class with primitive fields
DartObjectConverter<Extra> _extraDartObjectConverter = 
    DartObjectConverter<Extra>(
      (dartObject) => Extra(
        prefix: dartObject.getFieldValue('prefix') as String,
        suffix: dartObject.getFieldValue('suffix') as String,
      )
    );

// Converter for class with primitive fields
DartObjectConverter<Signature> _signatureDartObjectConverter = 
    DartObjectConverter<Signature>(
      (dartObject) => Signature(
        name: dartObject.getFieldValue('name') as String,
        isApproved: dartObject.getFieldValue('isApproved') as bool,
      )
    );

// Converter for complex class with nested objects and lists
DartObjectConverter<Message> _messageDartObjectConverter = 
    DartObjectConverter<Message>(
      (dartObject) => Message(
        duplicates: dartObject.getFieldValue('duplicates') as int,
        format: dartObject.getFieldValue(
          'format', 
          [_messageFormatDartObjectConverter]
        ) as MessageFormat,
        extra: dartObject.getFieldValue(
          'extra', 
          [_extraDartObjectConverter]
        ) as Extra?,
        signatures: dartObject.getFieldValue(
          'signatures', 
          [_signatureDartObjectConverter]
        ).cast<Signature>(),
      )
    );
```

**Converter Patterns:**

1. **Enum Converters:**
   ```dart
   DartObjectConverter<MyEnum>(
     (dartObject) => MyEnum.values.firstWhere(
       (e) => e.name == dartObject.variable!.name
     )
   )
   ```

2. **Simple Class Converters (primitives only):**
   ```dart
   DartObjectConverter<MyClass>(
     (dartObject) => MyClass(
       stringField: dartObject.getFieldValue('stringField') as String,
       intField: dartObject.getFieldValue('intField') as int,
       boolField: dartObject.getFieldValue('boolField') as bool,
       doubleField: dartObject.getFieldValue('doubleField') as double,
     )
   )
   ```

3. **Complex Class Converters (with nested objects):**
   ```dart
   DartObjectConverter<ParentClass>(
     (dartObject) => ParentClass(
       primitiveField: dartObject.getFieldValue('primitiveField') as String,
       // Pass converter for nested object as second parameter
       nestedObject: dartObject.getFieldValue(
         'nestedObject',
         [_nestedObjectConverter]
       ) as NestedClass,
       // Nullable nested object
       optionalNested: dartObject.getFieldValue(
         'optionalNested',
         [_nestedObjectConverter]
       ) as NestedClass?,
     )
   )
   ```

4. **List Field Converters:**
   ```dart
   DartObjectConverter<MyClass>(
     (dartObject) => MyClass(
       // List of primitives
       stringList: dartObject.getFieldValue('stringList').cast<String>(),
       // List of custom objects
       objectList: dartObject.getFieldValue(
         'objectList',
         [_objectConverter]
       ).cast<CustomObject>(),
     )
   )
   ```

**Key Principles for Converters:**
- Create one converter per annotation type
- Register all converters in the `_dartObjectConverters` map
- Use `dartObject.variable!.name` for enums
- Use `dartObject.getFieldValue('fieldName')` for primitive fields
- Pass nested converters as an array to `getFieldValue` for complex types
- Use `.cast<T>()` for lists of custom objects
- Handle nullable fields with `as Type?`

### Step 4: Update build.yaml

Add the new builder configuration to the `build.yaml` file under the `builders:` section.

**Default Configuration Example:**

For a builder named `user_validator`, add:

```yaml
builders:
  user_validator:
    import: "package:example/_code_builders/user_validator/builder.dart"
    builder_factories: ["userValidatorBuilder"]
    build_extensions:
      {
        "{{dir}}/{{file}}.dart":
          ["{{dir}}/gen/{{file}}.gen.user_validator.dart"],
      }
    auto_apply: none
    build_to: source
```

**Configuration Parameters:**

The above shows default parameters, but adjust based on the builder's purpose and user's description:

- **`import`**: Path to the builder file (always required, use actual package name)
- **`builder_factories`**: List of builder factory function names (always required)
- **`build_extensions`**: Input/output file mapping
  - Adjust output directory (e.g., `{{dir}}/.gen/` vs `{{dir}}/gen/`) based on user preference
  - Adjust file naming pattern to match the builder's purpose
  - Keep `{{dir}}` and `{{file}}` as literal strings
- **`auto_apply`**: 
  - `none` (default): Builder runs only on files specified in `targets` section
  - `dependents`: Automatically runs on all files that depend on packages with this builder
  - `all_packages`: Runs on all packages
  - Adjust based on how the builder should be triggered
- **`build_to`**: 
  - `source` (default): Generates files in the source tree
  - `cache`: Generates files in build cache
  - Choose based on whether generated files should be committed
- **`generate_for`**: Optional, can be added to specify specific files/patterns
- **`required_inputs`**: Optional, specify file extensions this builder requires

**Template Pattern:**
- First `user_validator` is the builder key (snake_case)
- Import path uses snake_case for directory name
- Builder factory uses camelCase with "Builder" suffix
- Build extensions use snake_case in the output file name

**Important:** 
- Replace `example` in the import path with the actual package name from `pubspec.yaml`
- Configure parameters to match the user's description and intended use case
- The default values shown are good starting points but may need adjustment

## Naming Convention Examples

| Input Name       | snake_case         | camelCase          |
|------------------|--------------------|--------------------|
| user_validator   | user_validator     | userValidator      |
| UserValidator    | user_validator     | userValidator      |
| messageCreator   | message_creator    | messageCreator     |
| APIHandler       | api_handler        | apiHandler         |

## Validation After Creation

Verify that the following were created successfully:

- [ ] Directory `lib/_code_builders/<builder_name>/` exists
- [ ] File `annotations.dart` exists with appropriate content
  - Empty if no description provided
  - Contains annotation classes if description was provided
- [ ] File `builder.dart` exists with correct content
  - Contains minimal template if no description provided
  - Contains build logic and helper functions if description was provided
- [ ] File `converters.dart` exists with correct content
  - Contains empty map if no description provided
  - Contains all necessary converters if description was provided
- [ ] `build.yaml` contains the new builder configuration
- [ ] All naming conventions (snake_case, camelCase) are applied correctly
- [ ] If description was provided, verify annotation types match converter types

## Error Handling

### Missing Prerequisites
If code builders infrastructure is not initialized, halt execution and prompt the user to run the initialization command first.

### Existing Builder
If a builder with the same name already exists, notify the user and ask if they want to:
1. Overwrite the existing builder
2. Cancel the operation
3. Choose a different name

### File Creation Failures
If file creation fails, report the specific error and provide guidance on manual creation.

## Post-Creation Steps

After successfully creating the builder, inform the user of the next steps:

**If created without description:**
1. The builder skeleton has been created successfully
2. Add annotation classes to `annotations.dart` that users will import and use
3. Implement the build logic in `builder.dart` within the `build` function
4. Add necessary helper functions for code generation in `builder.dart`
5. Create converters for each annotation type in `converters.dart`
6. Run `dart run build_runner build` to test the builder

**If created with description:**
1. The builder has been created with initial implementation
2. Review the generated annotations in `annotations.dart` and adjust as needed
3. Review the build logic in `builder.dart` and refine the code generation
4. Verify converters in `converters.dart` match all annotation types
5. Test the builder by:
   - Creating a test file with the annotations
   - Running `dart run build_runner build`
   - Verifying the generated output
6. Iterate on the implementation based on test results

## Additional Resources

**Understanding Converters:**
- Converters bridge Dart analyzer's compile-time representation to runtime objects
- Each annotation class needs a corresponding converter
- Nested objects require their converters to be passed as parameters
- Lists of custom objects need explicit type casting

**BufferWritable Classes (Critical):**
- **Always use these instead of manual string building** for structured code generation
- Available classes: `Class`, `Enum`, `Mixin`, `Extension`, `Method`, `Constructor`, `Property`, `Getter`, `Setter`, `GlobalFunction`, `GlobalVariable`
- Benefits: Type-safe, readable, maintainable, and automatically handles formatting
- Pattern: Create BufferWritable objects in helper functions, then call `.writeTo(buffer)` in the build function
- Import from: `package:code_builders/code_builder.dart`

**Analyzer Extensions:**
- Use `element.getAnnotation<T>()` to retrieve typed annotations
- Access element properties with `element.properties`, `element.methods`, etc.
- Simplify type checking and element traversal
- Import from: `package:code_builders/code_builder.dart` (includes analyzer extensions)

**Builder Development Tips:**
- Start with simple annotations and gradually add complexity only as needed
- Use helper functions that return BufferWritable objects to keep code organized
- Test with minimal examples before applying to larger codebases
- Avoid over-engineering: Simple solutions are better than complex ones
- Let BufferWritable classes handle formatting and indentation automatically

