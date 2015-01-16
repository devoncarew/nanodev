
import 'dart:html';

import 'package:nanodev/nanodev.dart';

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
  NanoDev nanodev = new NanoDev();
  nanodev.start();
}
