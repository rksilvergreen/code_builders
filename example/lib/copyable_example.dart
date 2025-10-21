import 'package:example/.code_builders/copyable/annotations.dart';

// ============================================================================
// Example 1: Basic Copyable Class
// ============================================================================

@Copyable()
class Address {
  final String street;
  final String city;
  final int zipCode;

  const Address({
    required this.street,
    required this.city,
    required this.zipCode,
  });
}

// ============================================================================
// Example 2: Copyable with Field-Level Annotations
// ============================================================================

@Copyable(
  nullableStrategy: NullableStrategy.separateMethod,
  generateDocs: true,
)
class User {
  @CopyableField(immutable: true)
  final String id;

  final String name;

  @CopyableField(parameterName: 'userAge')
  final int? age;

  final String? email;

  final Address? address;

  @CopyableField(exclude: true)
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    this.age,
    this.email,
    this.address,
    required this.createdAt,
  });
}

// ============================================================================
// Example 3: Copyable with Deep Copy for Collections
// ============================================================================

@Copyable(
  nestedCopyStrategy: NestedCopyStrategy.deepIfAvailable,
)
class Profile {
  final String username;

  @CopyableField(
    deepCopy: true,
    customCopyExpression: 'tags?.map((e) => e).toList()',
  )
  final List<String>? tags;

  @CopyableField(
    parameterName: 'meta',
    customCopyExpression: 'metadata != null ? Map<String, dynamic>.from(metadata!) : null',
  )
  final Map<String, dynamic>? metadata;

  final String? bio;

  const Profile({
    required this.username,
    this.tags,
    this.metadata,
    this.bio,
  });
}

// ============================================================================
// Example 4: Mixin-Style Generation
// ============================================================================

@Copyable(
  style: GenerationStyle.mixin,
  nameSuffix: 'CopyMixin',
)
class Settings {
  final String theme;
  final bool notificationsEnabled;
  final int? fontSize;
  final String? language;

  const Settings({
    required this.theme,
    required this.notificationsEnabled,
    this.fontSize,
    this.language,
  });
}

// ============================================================================
// Example 5: Complex Nested Structure
// ============================================================================

@Copyable()
class Company {
  final String name;
  final Address headquarters;
  final List<String> departments;

  const Company({
    required this.name,
    required this.headquarters,
    required this.departments,
  });
}

@Copyable(
  nullableStrategy: NullableStrategy.separateMethod,
)
class Employee {
  @CopyableField(immutable: true)
  final String employeeId;

  final String firstName;
  final String lastName;

  @CopyableField(parameterName: 'dept')
  final String? department;

  final Company? company;

  @CopyableField(
    customCopyExpression: 'skills?.map((e) => e).toList()',
  )
  final List<String>? skills;

  @CopyableField(exclude: true)
  final DateTime hireDate;

  const Employee({
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    this.department,
    this.company,
    this.skills,
    required this.hireDate,
  });
}

// ============================================================================
// Main Function - Example Usage
// ============================================================================

void main() {
  print('Copyable Code Generator Example');
  print('=================================\n');

  // Example 1: Basic copyWith
  final address = Address(
    street: '123 Main St',
    city: 'Springfield',
    zipCode: 12345,
  );
  print('Original address: ${address.city}');
  // After generation: final newAddress = address.copyWith(city: 'Shelbyville');

  // Example 2: copyWith with immutable fields
  final user = User(
    id: 'user-001',
    name: 'Alice',
    age: 30,
    email: 'alice@example.com',
    address: address,
    createdAt: DateTime.now(),
  );
  print('Original user: ${user.name}, age ${user.age}');
  // After generation:
  // final updatedUser = user.copyWith(name: 'Alice Smith', userAge: 31);
  // final userWithoutEmail = user.copyWithNull(['email']);

  // Example 3: Profile with collections
  final profile = Profile(
    username: 'alice123',
    tags: ['developer', 'flutter', 'dart'],
    metadata: {'theme': 'dark', 'lastLogin': '2024-01-01'},
    bio: 'Software developer',
  );
  print('Original profile: ${profile.username}');
  // After generation:
  // final newProfile = profile.copyWith(
  //   tags: ['developer', 'flutter', 'dart', 'kotlin'],
  //   meta: {'theme': 'light'},
  // );

  print('\nRun `dart run build_runner build` to generate the copyWith methods!');
}
