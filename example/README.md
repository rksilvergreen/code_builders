# Code Builders Example

This example demonstrates the `code_builders` package with a practical **`@Copyable`** code generator.

## What is @Copyable?

The `@Copyable` annotation generates `copyWith` methods for immutable data classes, solving the tedious and error-prone task of writing them manually.

## Features Demonstrated

### 1. **Basic CopyWith Generation**
```dart
@Copyable()
class Address {
  final String street;
  final String city;
  final int zipCode;
  
  const Address({required this.street, required this.city, required this.zipCode});
}
```

**Generates:**
```dart
extension AddressCopyable on Address {
  Address copyWith({String? street, String? city, int? zipCode}) {
    return Address(
      street: street ?? this.street,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
    );
  }
}
```

### 2. **Field-Level Annotations**

Use `@CopyableField` to control individual fields:

```dart
@Copyable(nullableStrategy: NullableStrategy.separateMethod)
class User {
  @CopyableField(immutable: true)
  final String id;  // Excluded from copyWith
  
  @CopyableField(parameterName: 'userAge')
  final int? age;  // Custom parameter name
  
  final String name;
  
  const User({required this.id, required this.name, this.age});
}
```

**Generates:**
```dart
extension UserCopyable on User {
  User copyWith({String? name, int? userAge}) {
    return User(id: this.id, name: name ?? this.name, age: userAge ?? this.age);
  }
  
  User copyWithNull(List<String> fieldNames) {
    return User(
      id: this.id,
      name: this.name,
      age: fieldNames.contains('userAge') ? null : this.age,
    );
  }
}
```

### 3. **Custom Copy Expressions**

Handle collections with deep copying:

```dart
@Copyable()
class Profile {
  @CopyableField(
    deepCopy: true,
    customCopyExpression: 'tags?.map((e) => e).toList()',
  )
  final List<String>? tags;
  
  const Profile({this.tags});
}
```

### 4. **Mixin Style Generation**

```dart
@Copyable(style: GenerationStyle.mixin)
class Settings {
  final String theme;
  final bool notificationsEnabled;
  
  const Settings({required this.theme, required this.notificationsEnabled});
}
```

**Generates:**
```dart
mixin SettingsCopyableMixin {
  String get theme;
  bool get notificationsEnabled;
  
  Settings copyWith({String? theme, bool? notificationsEnabled}) {
    return Settings(
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
```

## Code Builder Features Showcased

This example demonstrates:

✅ **Multiple Enum Types** - `NullableStrategy`, `GenerationStyle`, `NestedCopyStrategy`  
✅ **Class-Level Annotations** - `@Copyable()`  
✅ **Field-Level Annotations** - `@CopyableField()`  
✅ **Complex Annotation Parameters** - Enums, strings, booleans, lists  
✅ **DartObjectConverter** - Converting annotation objects  
✅ **Extension Generation** - Creating extension methods  
✅ **Mixin Generation** - Creating mixins  
✅ **Analyzing Class Fields** - Reading all properties  
✅ **Analyzing Field Annotations** - Reading per-field configuration  
✅ **Method Generation** - Creating `copyWith` and `copyWithNull` methods  
✅ **Conditional Logic** - Different generation based on strategies  
✅ **Nullability Handling** - Checking nullable types  

## Running the Generator

1. **Install dependencies:**
   ```bash
   dart pub get
   ```

2. **Run the code generator:**
   ```bash
   dart run build_runner build
   ```

3. **See generated files in:**
   ```
   lib/_gen/main.gen.copyable.dart
   ```

4. **Run the example:**
   ```bash
   dart run lib/main.dart
   ```

## Annotation Options

### @Copyable

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `nullableStrategy` | `NullableStrategy` | `standard` | How to handle nullable fields (`standard` or `separateMethod`) |
| `style` | `GenerationStyle` | `extension` | Generate as `extension` or `mixin` |
| `nestedCopyStrategy` | `NestedCopyStrategy` | `shallow` | How to copy nested objects |
| `nameSuffix` | `String?` | null | Custom suffix for generated name |
| `generateDocs` | `bool` | true | Generate documentation comments |
| `includePrivateFields` | `bool` | false | Include private fields (starting with `_`) |
| `imports` | `List<String>` | `[]` | Custom imports to add |

### @CopyableField

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `exclude` | `bool` | false | Exclude field from copyWith |
| `parameterName` | `String?` | null | Custom parameter name |
| `deepCopy` | `bool` | false | Force deep copy for this field |
| `customCopyExpression` | `String?` | null | Custom copy logic |
| `immutable` | `bool` | false | Mark as immutable (same as `exclude: true`) |

## Real-World Use Cases

This `@Copyable` generator solves real problems:

1. **Flutter State Management** - Copying state objects immutably
2. **API Models** - Updating DTOs without mutation
3. **Redux/Bloc Patterns** - Creating new state instances
4. **Form Editing** - Updating user input data
5. **Database Models** - Partial updates

## Learn More

Check out the source code in `lib/_code_builders/copyable/` to see:
- `annotations.dart` - The annotation definitions
- `converters.dart` - DartObjectConverters for reading annotations
- `builder.dart` - The code generation logic

