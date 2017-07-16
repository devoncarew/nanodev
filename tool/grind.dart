import 'dart:io';

import 'package:grinder/grinder.dart';

final Directory BUILD_DIR = new Directory('build');

void main(List<String> args) => grind(args);

@Task('build the `web/index.html` entrypoint')
void build(GrinderContext context) {
  Pub.build(directories: ['web']);

  File outFile = joinFile(BUILD_DIR, ['web', 'main.dart.js']);
  context.log('${outFile.path} compiled to ${_printSize(outFile)}');

  // Delete the build/web/packages directory.
  deleteEntity(getDir('build/web/packages'));

  // Reify the symlinks: cp -R -L packages build/web/packages
  run('cp', arguments: ['-R', '-L', 'packages', 'build/web/packages']);
}

@Task('prepare the app for deployment')
@Depends(build)
void deploy(GrinderContext context) {
  context.log('execute: `appcfg.py --email=<email> --oauth2 update build/web`');
}

@Task('clean')
clean() => defaultClean();

String _printSize(File file) => '${(file.lengthSync() + 1023) ~/ 1024}k';
