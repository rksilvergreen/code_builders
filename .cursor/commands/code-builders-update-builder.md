# Update Existing Code Builder Command

This command updates an existing code builder by validating and fixing converters, verifying build.yaml configuration, and applying any requested modifications. The command ensures all annotations have proper DartObjectConverters and the builder is correctly configured.

## Documentation References

- **Official Documentation**: [https://rksilvergreen.github.io/code_builders/](https://rksilvergreen.github.io/code_builders/)
- **Working Examples**: [https://github.com/rksilvergreen/code_builders/tree/main/example](https://github.com/rksilvergreen/code_builders/tree/main/example)

Refer to these resources throughout the development process for detailed API documentation and real-world implementation examples.

## Command Usage

`@code-builders-update-builder [builder_name] [description]`

Examples:
- `@code-builders-update-builder` - Will prompt for builder name
- `@code-builders-update-builder api_endpoint` - Updates the api_endpoint builder
- `@code-builders-update-builder copyable "Add support for deep copying nested objects"`

## What This Command Does

- Validates that the specified builder exists in `lib/_code_builders/`
- Analyzes all annotation classes in `annotations.dart`
- Checks that every annotation has a corresponding DartObjectConverter in `converters.dart`
- Generates missing converters automatically
- Verifies the builder is properly registered in `build.yaml`
- Applies any additional modifications specified in the description
- Uses code_builders BufferWritable classes and analyzer_extensions for any code generation

## Prerequisites

Before updating a builder, verify:

1. The builder directory exists at `lib/_code_builders/<builder_name>/`
2. The builder has the three core files: `annotations.dart`, `builder.dart`, `converters.dart`
3. The `build.yaml` file exists in the package root

**If builder name is not provided:**
- List all existing builders in `lib/_code_builders/`
- Prompt the user to select one
- Wait for user response before proceeding

## Update Process

### Step 1: Validate Builder Exists

Check that `lib/_code_builders/<builder_name>/` directory exists and contains:
- `annotations.dart`
- `builder.dart`
- `converters.dart`

**If builder not found:**
- Inform the user that the builder doesn't exist
- Suggest running `@code-builders-new-builder` instead
- Halt execution

### Step 2: Analyze Annotations

Read and parse the `annotations.dart` file to identify all annotation types:

1. **Scan for annotation classes** - Identify all class declarations
2. **Scan for enums** - Identify all enum declarations
3. **Map annotation structure** - For each annotation, identify:
   - Field names and types
   - Nested custom types
   - Collection types (List, Map, Set)
   - Required vs optional fields

**Reference**: Study how annotations are structured in the examples:
- [api_endpoint annotations](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint/annotations.dart)
- [copyable annotations](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable/annotations.dart)

### Step 3: Validate Converters

Read and parse the `converters.dart` file to check converter coverage:

1. **Extract existing converters** - Identify all DartObjectConverter declarations
2. **Compare with annotations** - Check that every annotation type has a converter
3. **Identify missing converters** - List any annotation types without converters
4. **Validate converter registration** - Ensure all converters are registered in `_dartObjectConverters` map

**Reference**: See how converters are structured in the examples:
- [api_endpoint converters](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint/converters.dart)
- [copyable converters](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable/converters.dart)

### Step 4: Generate Missing Converters

For each annotation type without a converter, generate the appropriate DartObjectConverter:

**Converter Generation Patterns:**

1. **For Enum Types:**
   - Use `dartObject.variable!.name` pattern
   - See [api_endpoint converters](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint/converters.dart) for enum examples

2. **For Simple Classes (primitives only):**
   - Use `dartObject.getFieldValue('fieldName')` for each field
   - See [copyable converters](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable/converters.dart) for simple class examples

3. **For Complex Classes (with nested objects):**
   - Pass nested converters as array parameter to `getFieldValue`
   - See [api_endpoint converters](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint/converters.dart) for complex class examples

4. **For Classes with Lists:**
   - Use `.cast<T>()` for type-safe conversion
   - See [copyable converters](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable/converters.dart) for list examples

5. **For Classes with Maps:**
   - Use `.cast<K, V>()` for strictly typed maps
   - Pass appropriate converters for custom key/value types

**Converter Registration:**
- Add all new converters to the `_dartObjectConverters` map
- Format: `TypeName: _typeNameDartObjectConverter,`
- Maintain alphabetical order for readability

**Key Principles:**
- Follow the exact patterns shown in the [example converters](https://github.com/rksilvergreen/code_builders/tree/main/example)
- Ensure type safety with proper casting
- Handle nullable fields with `as Type?`
- For complex dependency chains, generate converters in the correct order (dependencies first)

### Step 5: Verify build.yaml Configuration

Check that the builder is properly configured in `build.yaml`:

1. **Verify builder entry exists** in the `builders:` section
2. **Validate configuration parameters:**
   - `import` path points to correct builder file
   - `builder_factories` lists the correct factory function name
   - `build_extensions` defines appropriate input/output mapping
   - `auto_apply` is set appropriately
   - `build_to` is configured correctly

3. **Check targets configuration** (if applicable)

**Reference**: See [example build.yaml](https://github.com/rksilvergreen/code_builders/blob/main/example/build.yaml) for proper configuration structure.

**If configuration is incorrect or missing:**
- Report the issues to the user
- Offer to fix the configuration
- Apply corrections following the example pattern

### Step 6: Apply Description Updates (if provided)

If a description was provided, interpret and apply the requested changes:

**Common Update Scenarios:**

1. **Adding new annotations:**
   - Add annotation classes to `annotations.dart`
   - Generate corresponding converters
   - Update builder logic if needed

2. **Modifying builder logic:**
   - Update the `build` function in `builder.dart`
   - Use BufferWritable classes (Class, Method, Property, etc.)
   - Follow patterns from [example builders](https://github.com/rksilvergreen/code_builders/tree/main/example)

3. **Refining code generation:**
   - Update helper functions in `builder.dart`
   - Leverage analyzer_extensions for element analysis
   - Maintain clean, structured code using BufferWritable classes

4. **Changing output configuration:**
   - Update `build_extensions` in `build.yaml`
   - Adjust file naming patterns
   - Modify output directories

**Important Guidelines:**
- **Always use BufferWritable classes** for code generation (Class, Method, Constructor, Property, etc.)
- **Leverage analyzer_extensions** for element traversal and annotation retrieval
- Reference the [official documentation](https://rksilvergreen.github.io/code_builders/) for complete API details
- Study the [working examples](https://github.com/rksilvergreen/code_builders/tree/main/example) for best practices

## Validation After Update

Verify that all changes were applied correctly:

- [ ] All annotation types have corresponding converters in `converters.dart`
- [ ] All converters are registered in the `_dartObjectConverters` map
- [ ] Converter implementations match annotation structure (fields, types, nullability)
- [ ] `build.yaml` contains proper builder configuration
- [ ] Import paths are correct (package name, builder directory)
- [ ] Builder factory function name matches configuration
- [ ] If description was provided, all requested changes were applied
- [ ] Code follows BufferWritable patterns for any generated code
- [ ] No syntax errors in modified files

## Error Handling

### Builder Not Found
If the specified builder doesn't exist:
- List all available builders in `lib/_code_builders/`
- Suggest creating a new builder with `@code-builders-new-builder`
- Halt execution

### Missing Core Files
If any core file (annotations.dart, builder.dart, converters.dart) is missing:
- Report which files are missing
- Offer to regenerate the missing files
- Wait for user confirmation

### Parse Errors
If annotation or converter files have syntax errors:
- Report the specific errors
- Attempt to continue with valid portions
- Warn about potential incomplete updates

### Circular Dependencies
If annotations have circular type dependencies:
- Detect the circular reference
- Report the issue to the user
- Suggest restructuring the annotations

## Post-Update Steps

After successfully updating the builder, inform the user:

**Without Description (Validation Only):**
1. Summary of what was validated
2. List of missing converters that were added
3. Any build.yaml issues that were fixed
4. Reminder to run `dart run build_runner build` to test

**With Description (Modifications Applied):**
1. Summary of all changes made
2. List of new/modified annotations
3. List of new/modified converters
4. Changes to builder logic (if any)
5. Changes to build.yaml configuration (if any)
6. Next steps:
   - Review the changes in each file
   - Test the builder with `dart run build_runner build`
   - Verify the generated output matches expectations
   - Iterate on the implementation if needed

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

**Builder Update Tips:**
- Validate before modifying - understand the current state first
- Generate converters automatically when possible
- Follow existing patterns in the codebase
- Test incrementally after each change
- Use the example builders as reference for best practices
- Let BufferWritable classes handle code formatting automatically
- **Study the complete examples** to see best practices in action:
  - [api_endpoint builder](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/api_endpoint)
  - [copyable builder](https://github.com/rksilvergreen/code_builders/tree/main/example/lib/_code_builders/copyable)

