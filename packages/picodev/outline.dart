
library outline;

import 'dart:html';

import 'elements.dart';

class Outline extends DElement {
  Outline() : super('cde-outline');
  Outline.from(Element element) : super.from(element);

  String get summary => getAttr('summary');
  set summary(String value) => setAttr('summary', value);

  String get line => getAttr('line');
  set line(String value) => setAttr('line', value);

  String get column => getAttr('column');
  set column(String value) => setAttr('column', value);
}
