part of dart_source_builder;

/// A read-only map that manages access to [PackageManager] instances for all
/// packages in the package graph.
///
/// [PackageManagers] provides a convenient way to access package information
/// and library elements for any package in the build environment. It lazily
/// creates and caches [PackageManager] instances as they are requested.
///
/// ## Usage
///
/// ```dart
/// // Access a specific package
/// PackageManager? myPackage = packageManagers['my_package'];
///
/// // Access the current package being built
/// PackageManager current = packageManagers.current;
///
/// // Get library elements from a package
/// List<LibraryElement> models = await current.getLibraryElements(['models/**']);
/// ```
///
/// The class extends [UnmodifiableMapBase] to provide read-only map access
/// while maintaining an internal cache of package managers.
class PackageManagers extends UnmodifiableMapBase<String, PackageManager> {
  final PackageGraph _graph;
  final BuildStep _buildStep;
  final Map<String, PackageManager> _map = {};

  /// Returns the list of package names that have been cached.
  ///
  /// Note that this only includes packages that have been accessed through the
  /// index operator, not all packages in the graph.
  @override
  List<String> get keys => _map.keys.toList();

  /// Gets the [PackageManager] for the specified package name.
  ///
  /// If the package manager doesn't exist in the cache, it will be created and
  /// cached for future use. Returns `null` if the package is not found in the
  /// package graph.
  ///
  /// [key]: The name of the package to retrieve.
  ///
  /// Returns the [PackageManager] for the package, or `null` if not found.
  PackageManager? operator [](covariant String key) => _map[key] ?? _addPackage(key);

  /// Creates a new [PackageManagers] instance.
  ///
  /// [graph]: The package graph containing all packages in the build environment.
  /// [_buildStep]: The current build step, used to access the resolver.
  PackageManagers(PackageGraph graph, BuildStep _buildStep)
      : _graph = graph,
        _buildStep = _buildStep;

  PackageManager? _current;

  /// Gets the [PackageManager] for the current package being built.
  ///
  /// This is a convenient shortcut for accessing the package manager of the
  /// package that is currently being built. The value is cached after first access.
  ///
  /// Throws a [StateError] if the pubspec.yaml cannot be found.
  PackageManager get current => _current ??= this[packageName]!;

  /// Gets the name of the current package by reading its pubspec.yaml file.
  ///
  /// Reads the `pubspec.yaml` file in the current directory to extract the
  /// package name. This is a static method that can be called independently.
  ///
  /// Throws a [StateError] if the pubspec.yaml file is not found in the
  /// current directory.
  ///
  /// Returns the package name as a string.
  static String get packageName {
    var pubspecPath = p.join(p.current, 'pubspec.yaml');
    var pubspec = File(pubspecPath);
    if (!pubspec.existsSync()) {
      throw StateError('Unable to generate package graph, no `$pubspecPath` found.');
    }
    YamlMap rootPubspec = loadYaml(pubspec.readAsStringSync());
    String rootPackageName = rootPubspec['name'];
    return rootPackageName;
  }

  /// Creates and caches a [PackageManager] for the specified package.
  ///
  /// Looks up the package in the package graph and creates a new package manager
  /// if found. The manager is then cached for future access.
  ///
  /// [packageName]: The name of the package to add.
  ///
  /// Returns the newly created [PackageManager], or `null` if the package
  /// is not found in the package graph.
  PackageManager? _addPackage(String packageName) {
    PackageManager manager;
    PackageNode? node = _graph.allPackages[packageName];
    if (node == null) return null;
    manager = PackageManager._(node, _buildStep);
    return _map.putIfAbsent(packageName, () => manager);
  }
}

/// Manages library elements and file information for a single package.
///
/// [PackageManager] provides efficient access to analyzed library elements
/// within a package. It scans the package's `lib/` directory, resolves all
/// library files, and caches the [LibraryElement] instances for fast access.
///
/// ## Features
///
/// - **Lazy initialization**: The package is only scanned when first accessed
/// - **Caching**: All library elements are cached to avoid repeated analysis
/// - **Glob filtering**: Query libraries using glob patterns
/// - **Path utilities**: Convert between different path representations
///
/// ## Usage
///
/// ```dart
/// PackageManager manager = packageManagers['my_package']!;
///
/// // Get all library elements
/// List<LibraryElement> all = await manager.getLibraryElements();
///
/// // Get specific libraries using glob patterns
/// List<LibraryElement> models = await manager.getLibraryElements(['models/**']);
/// List<LibraryElement> services = await manager.getLibraryElements(['services/**']);
///
/// // Get library by asset ID
/// LibraryElement? lib = manager.getLibraryElementFromAssetId(assetId);
/// ```
///
/// ## Performance
///
/// The first call to any method that requires library information triggers
/// package initialization, which:
/// - Recursively lists all files in the `lib/` directory
/// - Resolves each Dart library file
/// - Caches the [LibraryElement] instances
///
/// Subsequent calls use the cached data and are very fast.
class PackageManager {
  /// The package node from the package graph.
  final PackageNode node;

  final BuildStep _buildStep;

  /// Gets the resolver from the build step for analyzing libraries.
  Resolver get _resolver => _buildStep.resolver;

  /// Path context for the package's lib directory.
  final p.Context _libContext;

  /// Cache of all resolved library elements in this package.
  final Map<AssetId, LibraryElement> _cachedLibraryElements = {};

  /// Provides read-only access to the cached library elements.
  ///
  /// This map contains all library files that have been successfully resolved
  /// in the package's `lib/` directory, keyed by their [AssetId].
  Map<AssetId, LibraryElement> get cachedLibraryElements => _cachedLibraryElements;

  /// Completer used to ensure initialization only happens once.
  Completer<void> _initialization = Completer<void>();

  /// Flag indicating whether initialization is in progress.
  bool _initializing = false;

  /// Creates a new [PackageManager] for the specified package node.
  ///
  /// This is a private constructor used by [PackageManagers]. The path context
  /// is initialized to the package's `lib/` directory.
  ///
  /// [node]: The package node from the package graph.
  /// [_buildStep]: The current build step for accessing the resolver.
  PackageManager._(this.node, this._buildStep) : _libContext = p.Context(current: p.join(node.path, 'lib'));

  /// Initializes the package manager by scanning and resolving all library files.
  ///
  /// This method:
  /// 1. Lists all files in the package's `lib/` directory recursively
  /// 2. Converts file paths to [AssetId] instances
  /// 3. Resolves each library file to get its [LibraryElement]
  /// 4. Caches all successfully resolved libraries
  ///
  /// The initialization only happens once. If another call is made while
  /// initialization is in progress, it waits for the current initialization
  /// to complete. Subsequent calls return immediately.
  ///
  /// **Error Handling:**
  /// - Silently ignores non-library files (e.g., part files)
  /// - Silently ignores missing assets
  ///
  /// This is called automatically by methods that need library information.
  Future<void> _init() async {
    if (_initializing) return await _initialization.future;
    _initializing = true;
    // print('-' * 50 + 'INIT [${node.name}]' + '${node.path}/lib' + '-' * 50);
    Directory directory = Directory('${node.path}/lib');
    List<FileSystemEntity> fileSystemEntities = directory.listSync(recursive: true);
    List<File> files = fileSystemEntities.whereType<File>().toList();
    List<AssetId> assetIds = [];
    for (File file in files) {
      String relPath = p.relative(file.path, from: node.path);
      AssetId assetId = AssetId(node.name, relPath);
      assetIds.add(assetId);
    }
    await Future.forEach(assetIds, (AssetId assetId) async {
      try {
        LibraryElement libraryElement = await _resolver.libraryFor(assetId);
        _cachedLibraryElements.putIfAbsent(assetId, () => libraryElement);
      } on NonLibraryAssetException catch (ex) {
      } on AssetNotFoundException catch (ex) {}
    });
    _initialization.complete();
  }

  /// Gets a list of library asset IDs that match the specified glob patterns.
  ///
  /// This method filters the cached library elements to return only those whose
  /// paths (relative to the `lib/` directory) match at least one of the provided
  /// glob patterns.
  ///
  /// **Parameters:**
  ///
  /// [globPaths]: Optional list of glob patterns to filter libraries. Defaults to
  /// `['**']` which matches all libraries. Backslashes are automatically converted
  /// to forward slashes for cross-platform compatibility.
  ///
  /// **Examples:**
  /// ```dart
  /// // Get all library asset IDs
  /// List<AssetId> all = await manager.getLibAssetIds();
  ///
  /// // Get only model libraries
  /// List<AssetId> models = await manager.getLibAssetIds(['models/**']);
  ///
  /// // Get multiple specific patterns
  /// List<AssetId> specific = await manager.getLibAssetIds([
  ///   'models/**',
  ///   'services/**',
  ///   'utils/**.dart'
  /// ]);
  /// ```
  ///
  /// Returns a list of [AssetId] instances for matching libraries. If no libraries
  /// match the patterns, returns an empty list.
  Future<List<AssetId>> getLibAssetIds([List<String> globPaths = const ['**']]) async {
    await _init();
    List<Glob> globs = globPaths.map((globPath) => Glob(globPath.replaceAll('\\', '/'), context: _libContext)).toList();
    Set<AssetId> allGlobsAssetIds = Set();
    for (Glob glob in globs) {
      for (AssetId assetId in _cachedLibraryElements.keys) {
        if (glob.matches(_pathFromLib(assetId))) allGlobsAssetIds.add(assetId);
      }
    }
    return allGlobsAssetIds.toList();
  }

  /// Gets a list of [LibraryElement] instances that match the specified glob patterns.
  ///
  /// This is a convenience method that combines [getLibAssetIds] with library
  /// element lookup. It retrieves the asset IDs matching the glob patterns, then
  /// returns their corresponding [LibraryElement] instances from the cache.
  ///
  /// **Parameters:**
  ///
  /// [globPaths]: Optional list of glob patterns to filter libraries. Defaults to
  /// `['**']` which matches all libraries.
  ///
  /// **Examples:**
  /// ```dart
  /// // Get all library elements
  /// List<LibraryElement> all = await manager.getLibraryElements();
  ///
  /// // Get only service libraries
  /// List<LibraryElement> services = await manager.getLibraryElements(['services/**']);
  ///
  /// // Analyze specific libraries
  /// List<LibraryElement> toAnalyze = await manager.getLibraryElements(['models/**']);
  /// for (var library in toAnalyze) {
  ///   for (var element in library.topLevelElements) {
  ///     print('Found: ${element.name}');
  ///   }
  /// }
  /// ```
  ///
  /// Returns a list of [LibraryElement] instances. Libraries that are not found
  /// in the cache (unlikely, but possible) are skipped. If no libraries match
  /// the patterns, returns an empty list.
  Future<List<LibraryElement>> getLibraryElements([List<String> globPaths = const ['**']]) async {
    List<LibraryElement> libraryElements = [];
    List<AssetId> assetIds = await getLibAssetIds(globPaths);
    for (AssetId assetId in assetIds) {
      LibraryElement? cachedLibraryElement = _cachedLibraryElements[assetId];
      if (cachedLibraryElement != null) {
        libraryElements.add(cachedLibraryElement);
      }
    }
    return libraryElements;
  }

  /// Gets the [LibraryElement] for a specific [AssetId].
  ///
  /// This is a direct lookup into the cache. The library must have been resolved
  /// during initialization for this method to return a non-null value.
  ///
  /// **Parameters:**
  ///
  /// [assetId]: The asset ID of the library to retrieve.
  ///
  /// **Example:**
  /// ```dart
  /// AssetId myLibId = AssetId('my_package', 'lib/models/user.dart');
  /// LibraryElement? userLib = manager.getLibraryElementFromAssetId(myLibId);
  /// if (userLib != null) {
  ///   // Analyze the library
  /// }
  /// ```
  ///
  /// Returns the [LibraryElement] if found in the cache, or `null` if the asset
  /// ID doesn't correspond to a cached library (e.g., the file is not a library,
  /// doesn't exist, or is from a different package).
  LibraryElement? getLibraryElementFromAssetId(AssetId assetId) => _cachedLibraryElements[assetId];

  /// Converts an asset ID to a path relative to the package root.
  ///
  /// Takes an [AssetId] and returns its path starting from the package directory.
  /// For example, an asset with path `lib/models/user.dart` would return
  /// `lib/models/user.dart` on Windows or `lib/models/user.dart` on Unix.
  ///
  /// **Parameters:**
  ///
  /// [assetId]: The asset ID to convert.
  /// [withFile]: If `true` (default), includes the filename. If `false`, returns
  /// only the directory path.
  ///
  /// **Example:**
  /// ```dart
  /// // With file: 'lib\models\user.dart' (on Windows)
  /// String fullPath = manager._pathFromRoot(assetId);
  ///
  /// // Without file: 'lib\models' (on Windows)
  /// String dirPath = manager._pathFromRoot(assetId, false);
  /// ```
  ///
  /// Returns the path as a string with platform-appropriate separators.
  String _pathFromRoot(AssetId assetId, [bool withFile = true]) {
    String path = p.joinAll(p.split(assetId.path));
    if (!withFile) path = p.joinAll(p.split(path).withoutLast());
    return path;
  }

  /// Converts an asset ID to a path relative to the package's `lib/` directory.
  ///
  /// Takes an [AssetId] and returns its path without the `lib/` prefix.
  /// For example, an asset with path `lib/models/user.dart` would return
  /// `models/user.dart`.
  ///
  /// This is useful for glob pattern matching, as glob patterns are typically
  /// specified relative to the lib directory.
  ///
  /// **Parameters:**
  ///
  /// [assetId]: The asset ID to convert.
  /// [withFile]: If `true` (default), includes the filename. If `false`, returns
  /// only the directory path relative to lib.
  ///
  /// **Example:**
  /// ```dart
  /// // With file: 'models\user.dart' (on Windows)
  /// String relPath = manager._pathFromLib(assetId);
  ///
  /// // Without file: 'models' (on Windows)
  /// String dirPath = manager._pathFromLib(assetId, false);
  /// ```
  ///
  /// Returns the path as a string with platform-appropriate separators.
  String _pathFromLib(AssetId assetId, [bool withFile = true]) {
    String path = p.joinAll(p.split(assetId.path).withoutFirst());
    if (!withFile) path = p.joinAll(p.split(path).withoutLast());
    return path;
  }

  /// Converts an asset ID to an absolute file system path.
  ///
  /// Takes an [AssetId] and returns the full absolute path to the file on the
  /// file system. This combines the package's lib directory absolute path with
  /// the asset's path relative to lib.
  ///
  /// For example, if the package is at `/home/user/mypackage` and the asset
  /// is `lib/models/user.dart`, this would return `/home/user/mypackage/lib/models/user.dart`.
  ///
  /// **Parameters:**
  ///
  /// [assetId]: The asset ID to convert.
  /// [withFile]: If `true` (default), includes the filename. If `false`, returns
  /// only the absolute directory path.
  ///
  /// **Example:**
  /// ```dart
  /// // With file: 'C:\projects\mypackage\lib\models\user.dart' (on Windows)
  /// String absPath = manager._pathAbsolute(assetId);
  ///
  /// // Without file: 'C:\projects\mypackage\lib\models' (on Windows)
  /// String absDirPath = manager._pathAbsolute(assetId, false);
  /// ```
  ///
  /// Returns the absolute path as a string with platform-appropriate separators.
  String _pathAbsolute(AssetId assetId, [bool withFile = true]) {
    String path = p.join(_libContext.current, _pathFromLib(assetId));
    if (!withFile) path = p.joinAll(p.split(path).withoutLast());
    return path;
  }
}
