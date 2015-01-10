
import 'dart:io';

import 'package:ghpages_generator/ghpages_generator.dart' as ghpages;
import 'package:grinder/grinder.dart';

final Directory BUILD_DIR = new Directory('build');

void main(List<String> args) {
  task('init', defaultInit);
  task('build', build, ['init']);
  task('gh-pages', copyGhPages, ['build']);
  task('clean', defaultClean);

  startGrinder(args);
}

/// Build the `web/index.html` entrypoint.
void build(GrinderContext context) {
  Pub.build(context, directories: ['web']);

  File outFile = joinFile(BUILD_DIR, ['web', 'main.dart.js']);
  context.log('${outFile.path} compiled to ${_printSize(outFile)}');

  // Delete the build/web/packages directory.
  deleteEntity(getDir('build/web/packages'));

  // Reify the symlinks: cp -R -L packages build/web/packages
  runProcess(context, 'cp',
      arguments: ['-R', '-L', 'packages', 'build/web/packages']);
}

/// Generate a new version of gh-pages.
void copyGhPages(GrinderContext context) {
  context.log('Copying build/web to the `gh-pages` branch');

  new ghpages.Generator(rootDir: getDir('.').absolute.path)
      ..templateDir = getDir('build/web').absolute.path
      ..generate();

  context.log('You now need to `git push origin gh-pages`.');
}

String _printSize(File file) => '${(file.lengthSync() + 1023) ~/ 1024}k';
