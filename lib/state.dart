
/**
 * A library for storing non-semantic user state, like UI component positions.
 */
library state;

import 'dart:convert' show JSON;
import 'dart:html';

// TODO: Make it easier to store rich data.

abstract class State {
  dynamic operator[](String key);
  void operator[]=(String key, dynamic value);
}

class HtmlState implements State {
  final String id;
  Map<String, dynamic> _values = {};

  HtmlState(this.id) {
    if (window.localStorage.containsKey(id)) {
      _values = JSON.decode(window.localStorage[id]);
    }
  }

  dynamic operator[](String key) => _values[key];

  void operator[]=(String key, dynamic value) {
    _values[key] = value;
    window.localStorage[id] = JSON.encode(_values);
  }
}
