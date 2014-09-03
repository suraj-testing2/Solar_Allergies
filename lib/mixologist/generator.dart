part of streamy.mixologist;

/// Generated mixed in code according to the provided [config]. Uses
/// [fs] to access the file system.
Future<String> mix(Config config, FileSystem fs) {
  Map mixins = {};
  // Walk paths and locate mixins
  return forEachAsync(config.paths, (String path) =>
    forEachAsync(
      config.mixins.where((name) => !mixins.containsKey(name)),
      (String name) {
        var mixinPath = '${path}/${name}.dart';
        return fs.exists(mixinPath).then((bool exists) {
          if (exists) {
            return fs.read(mixinPath).pipe(new MixinReader())
              .then((Mixin mixin) {
                mixins[name] = mixin;
              });
          }
        });
      }
    )
  ).then((_) {
    // Validate that every mixin needed has been loaded.
    var missing = config.mixins
        .where((mixin) => !mixins.containsKey(mixin));
    if (missing.isNotEmpty) {
      throw new Exception('Could not find mixins: ${missing.join(", ")}');
    }

    List<Mixin> mixinList =
        config.mixins.map((mixin) => mixins[mixin]).toList();

    var codeLines = <String>[
      '// Generated by the Streamy Mixologist.',
      '// Mixins: ${config.mixins.join(",")}'
      '',
      'library ${config.libraryName};', ''
    ]
      ..addAll(writeImports(unifyImports(mixinList)))
      ..add('')
      ..addAll(new LinearizedTarget(
          config.className, '', 'Object', mixinList).linearize())
      ..add('');
    return codeLines.join('\n');
  });
}