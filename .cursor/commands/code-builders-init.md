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

**If `build.yaml` already exists:**
- Check if it contains a `targets` section with either `$default` or the package name as a key
- If either exists, leave the file unchanged
- If neither exists, add the `targets` section with `$default`

**If `build.yaml` does not exist:**
Create a `build.yaml` file in the package root directory with the following content:

```yaml
targets:
  $default: {}
```

**Note:** The default target can be specified using either `$default` or the package name (e.g., if your package is `my_package`, you can use `my_package: {}` instead of `$default: {}`).

### 2. Mason Configuration

**If `mason.yaml` already exists:**
- Check if it contains a `code_builder` brick configuration with the specified git URL, ref, and path
- If the `code_builder` brick is properly configured, leave the file unchanged
- If the `code_builder` brick is missing or incorrectly configured, add or update it

**If `mason.yaml` does not exist:**
Create a `mason.yaml` file in the package root directory with the following content:

```yaml
bricks:
  code_builder:
    git:
      url: https://github.com/rksilvergreen/code_builders.git
      ref: v0.2.2
      path: mason/code_builder
```

### 3. Package Dependencies

Update the `pubspec.yaml` file by adding the following dependencies to the `dev_dependencies` section:

```yaml
dev_dependencies:
  build_runner: ^2.10.0
  code_builders:
    git:
      url: https://github.com/rksilvergreen/code_builders.git
      ref: v0.2.2
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