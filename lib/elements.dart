
library elements;

import 'dart:html';

class DElement {
  final Element element;

  DElement(String tag) : element = new Element.tag(tag);
  DElement.from(this.element);

  bool hasAttr(String name) => element.attributes.containsKey(name);

  void toggleAttr(String name, bool value) {
    value ? element.setAttribute(name, '') : element.attributes.remove(name);
  }

  String getAttr(String name) => element.getAttribute(name);

  void setAttr(String name, String value) => element.setAttribute(name, value);

  String clearAttr(String name) => element.attributes.remove(name);

  void dispose() {
    if (element.parent.children.contains(element)) {
      try {
        element.parent.children.remove(element);
      } catch (e) {
        print('foo');
      }
    }
  }

  String toString() => element.toString();
}
