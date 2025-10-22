# Create New Code Builder Command

This command creates a new code builder with all required files and configuration. The command accepts the builder name as an argument and handles the complete setup process.

## Documentation References

- **Official Documentation**: [https://rksilvergreen.github.io/code_builders/](https://rksilvergreen.github.io/code_builders/)
- **Working Examples**: [https://github.com/rksilvergreen/code_builders/tree/main/example](https://github.com/rksilvergreen/code_builders/tree/main/example)

Refer to these resources throughout the development process for detailed API documentation and real-world implementation examples.

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

**Reference**: See example annotations for complete working examples:
- [api_endpoint annotations](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint/annotations.dart)
- [copyable annotations](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable/annotations.dart)

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

**Reference**: See example builder implementations for complete working examples demonstrating:
- [api_endpoint builder](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint/builder.dart) - Shows how to structure the build function and use BufferWritable classes
- [copyable builder](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable/builder.dart) - Demonstrates analyzer_extensions usage and helper function organization

**Key Principles for Builder Logic:**
- **Always use BufferWritable classes**: Use `Class`, `Method`, `Constructor`, `Property`, `Getter`, `Setter`, etc. from `code_builders/buffer_writable`
- **Leverage analyzer_extensions**: Use extension methods like `element.getAnnotation<T>()`, `element.properties`, `element.methods`, etc.
- Access the input library via `buildStep.inputLibrary`
- Iterate through elements to find annotated classes
- Extract helper functions that return BufferWritable objects (e.g., `Class`, `Method`)
- Call `.writeTo(buffer)` on BufferWritable objects to generate code
- Keep code generation logic neat and readable by using structured classes instead of string concatenation
- Return the generated code as a string

For detailed API documentation on all available BufferWritable classes and their parameters, refer to the [official documentation](https://rksilvergreen.github.io/code_builders/).

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

**Reference**: See example converters for complete working examples demonstrating:
- [api_endpoint converters](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint/converters.dart) - Enum types and complex classes with nested objects
- [copyable converters](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable/converters.dart) - Simple classes with primitive fields and list fields

**Converter Pattern Structure:**

```dart
part of 'builder.dart';

final _dartObjectConverters = {
  TypeA: _typeADartConverterObject,
  TypeB: _typeBDartConverterObject,
  ...
};

DartObjectConverter<TypeA> _typeADartConverterObject = ...
DartObjectConverter<TypeB> _typeBDartConverterObject = ...
...
```

**Converter Pattern Quick Reference:**

The example converters demonstrate all common patterns:

1. **Enum Converters** - Use `dartObject.variable!.name` to map enum values (see [api_endpoint](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint/converters.dart))
2. **Simple Class Converters** - Use `dartObject.getFieldValue('fieldName')` for primitive fields (see [copyable](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable/converters.dart))
3. **Complex Class Converters** - Pass nested converters as array to `getFieldValue` for custom types (see [api_endpoint](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint/converters.dart))
4. **List Field Converters** - Use `.cast<T>()` for type-safe list conversion (see [copyable](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable/converters.dart))
5. **Map Field Converters** - Use `.cast<K, V>()` for strictly typed maps

**Key Principles for Converters:**
- Create one converter per annotation type
- Register all converters in the `_dartObjectConverters` map with Type as key
- Use `dartObject.variable!.name` for enums
- Use `dartObject.getFieldValue('fieldName')` for primitive fields
- Pass nested converters as an array to `getFieldValue` for complex types
- Use `.cast<T>()` for lists and `.cast<K, V>()` for maps
- Handle nullable fields with `as Type?`

Refer to the example implementations for detailed syntax and real-world usage:
- [api_endpoint converters](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint/converters.dart)
- [copyable converters](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable/converters.dart)

### Step 4: Update build.yaml

Add the new builder configuration to the `build.yaml` file under the `builders:` section.

**Reference**: See [example build.yaml](https://github.com/rksilvergreen/code_builders/blob/main/example/build.yaml) for complete working configurations showing:
- How to configure the `api_endpoint` builder
- How to configure the `copyable` builder
- Proper structure for `targets` and `builders` sections
- Configuration parameters like `import`, `builder_factories`, `build_extensions`, `auto_apply`, and `build_to`

Follow the same pattern as the examples, adjusting:
- Builder name to match your builder (snake_case)
- Import path to match your package name and builder directory
- Builder factory function name (camelCase with "Builder" suffix)
- Build extensions to match your desired output file naming pattern
- Configuration parameters based on the builder's purpose and user's description

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

**Primary References:**
- **Official Documentation**: [https://rksilvergreen.github.io/code_builders/](https://rksilvergreen.github.io/code_builders/) - Complete API reference for all BufferWritable classes and utilities
- **Working Examples**: [https://github.com/rksilvergreen/code_builders/tree/main/example](https://github.com/rksilvergreen/code_builders/tree/main/example) - Full implementations of builders:
  - [api_endpoint builder](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint)
  - [copyable builder](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable)

**Understanding Converters:**
- Converters bridge Dart analyzer's compile-time representation to runtime objects
- Each annotation class needs a corresponding converter
- Nested objects require their converters to be passed as parameters
- Lists of custom objects need explicit type casting
- **See the example converters** for all patterns:
  - [api_endpoint converters](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint/converters.dart)
  - [copyable converters](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable/converters.dart)

**BufferWritable Classes (Critical):**
- **Always use these instead of manual string building** for structured code generation
- Available classes: `Class`, `Enum`, `Mixin`, `Extension`, `Method`, `Constructor`, `Property`, `Getter`, `Setter`, `GlobalFunction`, `GlobalVariable`
- Benefits: Type-safe, readable, maintainable, and automatically handles formatting
- Pattern: Create BufferWritable objects in helper functions, then call `.writeTo(buffer)` in the build function
- Import from: `package:code_builders/code_builder.dart`
- **Full API details**: [https://rksilvergreen.github.io/code_builders/](https://rksilvergreen.github.io/code_builders/)

**Analyzer Extensions:**
- Use `element.getAnnotation<T>()` to retrieve typed annotations
- Access element properties with `element.properties`, `element.methods`, etc.
- Simplify type checking and element traversal
- Import from: `package:code_builders/code_builder.dart` (includes analyzer extensions)
- **Usage examples**: 
  - [api_endpoint builder.dart](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint/builder.dart)
  - [copyable builder.dart](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable/builder.dart)

**Builder Development Tips:**
- Start with simple annotations and gradually add complexity only as needed
- Use helper functions that return BufferWritable objects to keep code organized
- Test with minimal examples before applying to larger codebases
- Avoid over-engineering: Simple solutions are better than complex ones
- Let BufferWritable classes handle formatting and indentation automatically
- **Study the complete examples** to see best practices in action:
  - [api_endpoint builder](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint)
  - [copyable builder](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable)

