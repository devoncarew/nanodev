
import 'dart:io';

import 'package:grinder/grinder.dart';

final Directory BUILD_DIR = new Directory('build');

void main(List<String> args) {
  task('init', defaultInit);
  task('build', build, ['init']);
  task('deploy', deploy, ['build']);
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

/// Prepare the app for deployment.
void deploy(GrinderContext context) {
  context.log('execute: `appcfg.py --email=<email> --oauth2 update build/web`');
}

String _printSize(File file) => '${(file.lengthSync() + 1023) ~/ 1024}k';
