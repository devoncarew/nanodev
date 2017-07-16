
library util;

import 'dart:html';

final bool _isMac = window.navigator.appVersion.toLowerCase().contains('macintosh');

bool isMac() => _isMac;
