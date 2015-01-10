
import 'dart:html';

import 'package:picodev/picodev.dart';

void main() {
  // TODO: We need a more rigorous way to determine when polymer has been
  // upgraded.
  bool unresolved = document.body.attributes.containsKey('unresolved');

  if (!unresolved) {
    _init();
  } else {
    document.addEventListener('polymer-ready', (e) => _init());
  }
}

void _init() {
  PicoDev picodev = new PicoDev();
  picodev.start();
}
