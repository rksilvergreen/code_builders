# Code Builders Initialization Command

This command sets up the complete code builders infrastructure for the current package, including configuration files, dependencies, and directory structure.

## What This Command Does

- Creates required configuration files (`build.yaml`, `mason.yaml`)
- Updates package dependencies in `pubspec.yaml`
- Creates the `_code_builders` directory structure
- Validates existing configurations and updates them if needed

## Prerequisites

- Ensure you are in the package root directory (same level as the `lib` folder)
- Verify the target package structure is correct

## Setup Steps

### 1. Build Configuration

Create a `build.yaml` file in the package root directory with the following content:

```yaml
targets:
  $default: {}
```

### 2. Mason Configuration

Create a `mason.yaml` file in the package root directory with the following content:

```yaml
bricks:
  code_builder:
    path: ../../../dart_libraries/code_builder/mason/code_builder
```

### 3. Package Dependencies

Update the `pubspec.yaml` file by adding the following dependencies to the `dev_dependencies` section:

```yaml
dev_dependencies:
  build_runner: ^2.10.0
  code_builders:
    path: ../../../dart_libraries/code_builder
```

### 4. Code Builders Directory

Create a `_code_builders` folder within the `lib` directory to house generated code builder implementations.

## Validation

- Verify that all existing configuration files contain the exact specifications listed above
- Ensure file paths are correct relative to the package structure
- Confirm that all required directories exist and are properly configured
- Validate that dependency versions are compatible and up-to-date

## Error Handling

If any configuration files already exist with different content, update them to match the specified requirements rather than creating duplicates.