part of dart_source_builder;

class PackageManagers extends UnmodifiableMapBase<String, PackageManager> {
  final PackageGraph _graph;
  final BuildStep _buildStep;
  final Map<String, PackageManager> _map = {};

  @override
  List<String> get keys => _map.keys.toList();

  PackageManager? operator [](covariant String key) => _map[key] ?? _addPackage(key);

  PackageManagers(PackageGraph graph, BuildStep _buildStep) :
        _graph = graph,
        _buildStep = _buildStep;

  PackageManager? _current;

  PackageManager get current => _current ??= this[packageName]!;

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

  PackageManager? _addPackage(String packageName) {
    PackageManager manager;
    PackageNode? node = _graph.allPackages[packageName];
    if (node == null) return null;
    manager = PackageManager._(node, _buildStep);
    return _map.putIfAbsent(packageName, () => manager);
  }
}

class PackageManager {
  final PackageNode node;
  final BuildStep _buildStep;
  Resolver get _resolver => _buildStep.resolver;
  final p.Context _libContext;
  final Map<AssetId, LibraryElement> _cachedLibraryElements = {};
  Map<AssetId, LibraryElement> get cachedLibraryElements => _cachedLibraryElements;
  Completer<void> _initialization = Completer<void>();
  bool _initializing = false;

  PackageManager._(this.node, this._buildStep) : _libContext = p.Context(current: p.join(node.path, 'lib'));

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
      }
      on NonLibraryAssetException catch (ex) {
      }

      on AssetNotFoundException catch (ex) {
      }
    });
    _initialization.complete();
  }

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

  LibraryElement? getLibraryElementFromAssetId(AssetId assetId) => _cachedLibraryElements[assetId];

  String _pathFromRoot(AssetId assetId, [bool withFile = true]) {
    String path = p.joinAll(p.split(assetId.path));
    if (!withFile) path = p.joinAll(p.split(path).withoutLast());
    return path;
  }

  String _pathFromLib(AssetId assetId, [bool withFile = true]) {
    String path = p.joinAll(p.split(assetId.path).withoutFirst());
    if (!withFile) path = p.joinAll(p.split(path).withoutLast());
    return path;
  }

  String _pathAbsolute(AssetId assetId, [bool withFile = true]) {
    String path = p.join(_libContext.current, _pathFromLib(assetId));
    if (!withFile) path = p.joinAll(p.split(path).withoutLast());
    return path;
  }
}
