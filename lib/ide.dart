
library ide;

import 'files.dart';

IDE ide;

abstract class IDE {
  void openFile(File file, {int pos});
}
