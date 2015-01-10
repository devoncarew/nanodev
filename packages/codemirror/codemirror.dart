// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library codemirror;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'src/js_utils.dart';

// TODO: code completion (hint/show-hint.js)

// TODO: displaying errors

// TODO: find, replace

/**
 * A parameter type into the [CodeMirror.addCommand] method.
 */
typedef void CommandHandler(CodeMirror editor);

/**
 * A wrapper around the CodeMirror editor.
 */
class CodeMirror extends ProxyHolder {
  static final List<String> THEMES = const [
    '3024-day',
    '3024-night',
    'ambiance-mobile',
    'ambiance',
    'base16-dark',
    'base16-light',
    'blackboard',
    'cobalt',
    'eclipse',
    'elegant',
    'erlang-dark',
    'lesser-dark',
    'mbo',
    'mdn-like',
    'midnight',
    'monokai',
    'neat',
    'neo',
    'night',
    'paraiso-dark',
    'paraiso-light',
    'pastel-on-dark',
    'rubyblue',
    'solarized',
    'the-matrix',
    'tomorrow-night-bright',
    'tomorrow-night-eighties',
    'twilight',
    'vibrant-ink',
    'xq-dark',
    'xq-light',
    'zenburn'
  ];

  static final List<String> KEY_MAPS = const [
    'default',
    'emacs',
    'sublime',
    'vim',
  ];

  static JsObject get _cm => context['CodeMirror'];

  static List<String> get MODES => keys(_cm['modes'])
      .where((modeName) => modeName != 'null').toList();

  static List<String> get MIME_MODES => keys(_cm['mimeModes']);

  static List<String> get COMMANDS => keys(_cm['commands']);

  static ModeInfo findModeByExtension(String ext)
      => new ModeInfo(_cm.callMethod('findModeByExtension', [ext]));

  static ModeInfo findModeByMime(String mime)
      => new ModeInfo(_cm.callMethod('findModeByMIME', [mime]));

  static ModeInfo findModeByName(String name)
      => new ModeInfo(_cm.callMethod('findModeByName', [name]));

  /**
   * Registers a helper value with the given name in the given namespace (type).
   * This is used to define functionality that may be looked up by mode. Will
   * create (if it doesn't already exist) a property on the CodeMirror object
   * for the given type, pointing to an object that maps names to values. I.e.
   * after doing CodeMirror.registerHelper("hint", "foo", myFoo), the value
   * CodeMirror.hint.foo will point to myFoo.
   */
  static void registerHelper(String type, String name, dynamic value) {
    // TODO: value may be a Function? always a function?
    _cm.callMethod('registerHelper', [type, name, value]);
  }

//  /**
//   * Acts like registerHelper, but also registers this helper as 'global',
//   * meaning that it will be included by getHelpers whenever the given predicate
//   * returns true when called with the local mode and editor.
//   */
//  static void registerGlobalHelper(String type, String name, Function predicate,
//      dynamic value) {
//    // predicate: fn(mode, CodeMirror)
//    // TODO: value may be a Function? always a function?
//
//  }

  static JsObject _createFromElement(Element element, Map options) {
    if (options == null) {
      return new JsObject(_cm, [element]);
    } else {
      return new JsObject(_cm, [element, jsify(options)]);
    }
  }

  Doc _doc;

  /**
   * Create a new CodeMirror editor in the given element. See
   * http://codemirror.net/doc/manual.html#config for valid options values.
   */
  CodeMirror.fromElement(Element element, {Map options}) :
      super(_createFromElement(element, options));

  /**
   * Create a new CodeMirror editor from the given JsObject.
   */
  CodeMirror.fromJsObject(JsObject object) : super(object);

  /**
   * Fires every time the content of the editor is changed.
   */
  Stream get onChange => onEvent('change', true);

  /**
   * Will be fired when the cursor or selection moves, or any change is made to
   * the editor content.
   */
  Stream get onCursorActivity => onEvent('cursorActivity');

  /**
   * Fired when a mouse is clicked. You can preventDefault the event to signal
   * that CodeMirror should do no further handling.
   */
  Stream<MouseEvent> get onMouseDown => onEvent('mousedown', true);

  /**
   * Fired when a mouse is double-clicked. You can preventDefault the event to
   * signal that CodeMirror should do no further handling.
   */
  Stream<MouseEvent> get onDoubleClick => onEvent('dblclick', true);

  //Stream<MouseEvent> get onContextMenu => onEvent('contextmenu', true);

  /**
   * Retrieve the currently active document from an editor.
   */
  Doc getDoc() {
    if (_doc == null) {
      _doc = new Doc.fromProxy(call('getDoc'));
    }
    return _doc;
  }

  /**
   * Attach a new document to the editor.
   */
  void swapDoc(Doc doc) {
    _doc = doc;
    callArg('swapDoc', doc.jsProxy);
  }

  /**
   * Retrieves the current value of the given option for this editor instance.
   */
  dynamic getOption(String option) => callArg('getOption', option);

  /**
   * Change the configuration of the editor. option should the name of an
   * option, and value should be a valid value for that option.
   */
  void setOption(String option, var value) =>
      callArgs('setOption', [option, value]);

  String getTheme() => getOption('theme');

  void setTheme(String theme) => setOption('theme', theme);

  String getMode() => getOption('mode');

  void setMode(String mode) => setOption('mode', mode);

  /**
   * Return the current key map.
   */
  String getKeyMap() => getOption('keyMap');

  /**
   * Valid options are `default`, `vim`, `emacs`, and `sublime`.
   */
  void setKeyMap(String value) => setOption('keyMap', value);

  /**
   * Whether to show line numbers to the left of the editor.
   */
  bool getLineNumbers() => getOption('lineNumbers');

  /**
   * Whether to show line numbers to the left of the editor.
   */
  void setLineNumbers(bool value) => setOption('lineNumbers', value);

  /**
   * Get the content of line n.
   */
  String getLine(int n) => callArg('getLine', n);

  /**
   * Whether, when indenting, the first N*tabSize spaces should be replaced by N
   * tabs. Default is false.
   */
  bool getIndentWithTabs() => getOption('indentWithTabs');

  /**
   * Whether, when indenting, the first N*tabSize spaces should be replaced by N
   * tabs.
   */
  void setIndentWithTabs(bool value) => setOption('indentWithTabs', value);

  /**
   * Whether editing is disabled.
   */
  bool getReadOnly() =>
      getOption('readOnly') == true ||
      getOption('readOnly') == 'true' ||
      getOption('readOnly') == 'nocursor';

  /**
   * This disables editing of the editor content by the user.
   */
  void setReadOnly(bool value, [bool noCursor = false]) {
    if (value) {
      if (noCursor) {
        setOption('readOnly', 'nocursor');
      } else {
        setOption('readOnly', value);
      }
    } else {
      setOption('readOnly', value);
    }
  }

  /**
   * The width of a tab character. Defaults to 4.
   */
  int getTabSize() => getOption('tabSize');

  /**
   * The width of a tab character.
   */
  void setTabSize(int value) => setOption('tabSize', value);

  /**
   * How many spaces a block (whatever that means in the edited language) should
   * be indented. The default is 2.
   */
  int getIndentUnit() => getOption('indentUnit');

  /**
   * How many spaces a block (whatever that means in the edited language) should
   * be indented.
   */
  void setIndentUnit(int value) => setOption('indentUnit', value);

  /**
   * If your code does something to change the size of the editor element
   * (window resizes are already listened for), or unhides it, you should
   * probably follow up by calling this method to ensure CodeMirror is still
   * looking as intended.
   */
  void refresh() => call('refresh');

  /**
   * Give the editor focus.
   */
  void focus() => call('focus');

  /**
   * Retrieve one end of the primary selection. [start] is a an optional string
   * indicating which end of the selection to return. It may be "from", "to",
   * "head" (the side of the selection that moves when you press shift+arrow),
   * or "anchor" (the fixed side of the selection). Omitting the argument is the
   * same as passing "head". A {line, ch} object will be returned.
   */
  Position getCursor([String start]) => new Position.fromProxy(
        start == null ? call('getCursor') : callArg('getCursor', start));

  /**
   * Add a new custom command to CodeMirror.
   */
  void addCommand(String name, CommandHandler callback) {
    _cm['commands'][name] = (_) {
      callback(this);
    };
  }

  /**
   * Sets the gutter marker for the given gutter (identified by its CSS class,
   * see the gutters option) to the given value. Value can be either null, to
   * clear the marker, or a DOM element, to set it. The DOM element will be
   * shown in the specified gutter next to the specified line.
   */
  void setGutterMarker(int line, String gutterID, Element value) {
    callArgs('setGutterMarker', [line, gutterID, value]);
  }

  /**
   * Remove all gutter markers in the gutter with the given ID.
   */
  void clearGutter(String gutterID) {
    callArg('clearGutter', gutterID);
  }

  /**
   * Puts node, which should be an absolutely positioned DOM node, into the
   * editor, positioned right below the given {line, ch} position. When
   * scrollIntoView is true, the editor will ensure that the entire node is
   * visible (if possible). To remove the widget again, simply use DOM methods
   * (move it somewhere else, or call removeChild on its parent).
   */
  void addWidget(Position pos, Element node, [bool scrollIntoView = false]) {
    callArgs('addWidget', [pos.toProxy(), node, scrollIntoView]);
  }

  /**
   * Adds a line widget, an element shown below a line, spanning the whole of the
   * editor's width, and moving the lines below it downwards. line should be
   * either an integer or a line handle, and node should be a DOM node, which will
   * be displayed below the given line. options, when given, should be an object
   * that configures the behavior of the widget.
   */
  LineWidget addLineWidget(int line, Element node) {
    return new LineWidget(callArgs('addLineWidget', [line, node]));
  }
}

// TODO: Doc.markText

// TODO: Doc.setBookmark

// TODO: Doc.findMarks

// TODO: Doc.findMarksAt

// TODO: Doc.getAllMarks

/**
 * Each editor is associated with an instance of [Doc], its document. A document
 * represents the editor content, plus a selection, an undo history, and a mode.
 * A document can only be associated with a single editor at a time. You can
 * create new documents by calling the
 * `CodeMirror.Doc(text, mode, firstLineNumber)` constructor. The last two
 * arguments are optional and can be used to set a mode for the document and
 * make it start at a line number other than 0, respectively.
 */
class Doc extends ProxyHolder {
  static JsObject _create(String text, String mode, int firstLineNumber) {
    if (firstLineNumber == null) {
      return new JsObject(context['CodeMirror']['Doc'], [text, mode]);
    } else {
      return new JsObject(context['CodeMirror']['Doc'], [text, mode, firstLineNumber]);
    }
  }

  Doc(String text, [String mode, int firstLineNumber]) :
    super(_create(text, mode, firstLineNumber));

  Doc.fromProxy(JsObject proxy) : super(proxy);

  String getValue() => call('getValue');

  void setValue(String value) => callArg('setValue', value);

  /**
   * Get the number of lines in the editor.
   */
  int lineCount() => call('lineCount');

  /**
   * Get the first line of the editor. This will usually be zero but for linked
   * sub-views, or documents instantiated with a non-zero first line, it might
   * return other values.
   */
  int firstCount() => call('firstCount');

  /**
   * Get the last line of the editor. This will usually be doc.lineCount() - 1,
   * but for linked sub-views, it might return other values.
   */
  int lastCount() => call('lastCount');

  /**
   * Get the content of line n.
   */
  String getLine(int n) => callArg('getLine', n);

  /**
   * Get the currently selected code. Optionally pass a line separator to put
   * between the lines in the output. When multiple selections are present, they
   * are concatenated with instances of [lineSep] in between.
   */
  String getSelection([String lineSep]) => callArg('getSelection', lineSep);

  /**
   * Set a single selection range. anchor and head should be {line, ch} objects.
   * head defaults to anchor when not given. These options are supported:
   *
   * `scroll`: determines whether the selection head should be scrolled into
   * view. Defaults to true.
   *
   * `origin`: detemines whether the selection history event may be merged with
   * the previous one. When an origin starts with the character +, and the last
   * recorded selection had the same origin and was similar (close in time, both
   * collapsed or both non-collapsed), the new one will replace the old one.
   * When it starts with *, it will always replace the previous event (if that
   * had the same origin). Built-in motion uses the "+move" origin.
   *
   * `bias`: determine the direction into which the selection endpoints should
   * be adjusted when they fall inside an atomic range. Can be either -1
   * (backward) or 1 (forward). When not given, the bias will be based on the
   * relative position of the old selection—the editor will try to move further
   * away from that, to prevent getting stuck.
   */
  void setSelection(Position anchor, {Position head, Map options}) {
    callArgs('setSelection',
        [anchor.toProxy(), head == null ? null : head.toProxy(), options]);
  }

  /**
   * Set the editor content as 'clean', a flag that it will retain until it is
   * edited, and which will be set again when such an edit is undone again.
   * Useful to track whether the content needs to be saved. This function is
   * deprecated in favor of changeGeneration, which allows multiple subsystems
   * to track different notions of cleanness without interfering.
   */
  void markClean() => call('markClean');

  /**
   * Returns a number that can later be passed to [isClean] to test whether any
   * edits were made (and not undone) in the meantime. If closeEvent is true,
   * the current history event will be 'closed', meaning it can't be combined
   * with further changes (rapid typing or deleting events are typically
   * combined).
   */
  int changeGeneration([bool closeEvent]) {
    return closeEvent == null ?
        call('changeGeneration') : callArg('changeGeneration', closeEvent);
  }

  /**
   * Returns whether the document is currently clean, not modified since
   * initialization or the last call to [markClean] if no argument is passed, or
   * since the matching call to [changeGeneration] if a generation value is
   * given.
   */
  bool isClean([int generation]) {
    return generation == null ? call('isClean') : callArg('isClean', generation);
  }

  /**
   * Retrieve one end of the primary selection. start is a an optional string
   * indicating which end of the selection to return. It may be "from", "to",
   * "head" (the side of the selection that moves when you press shift+arrow),
   * or "anchor" (the fixed side of the selection). Omitting the argument is the
   * same as passing "head". A {line, ch} object will be returned.
   */
  Position getCursor([String start]) => new Position.fromProxy(
        start == null ? call('getCursor') : callArg('getCursor', start));

  /**
   * Set the cursor position. You can either pass a single {line, ch} object, or
   * the line and the character as two separate parameters. Will replace all
   * selections with a single, empty selection at the given position. The
   * supported options are the same as for setSelection.
   */
  void setCursor(Position pos, {Map options}) {
    callArgs('setCursor', [pos.toProxy(), options]);
  }

  /**
   * Get the text between the given points in the editor, which should be
   * {line, ch} objects. An optional third argument can be given to indicate the
   * line separator string to use (defaults to "\n").
   */
  String getRange(Position from, Position to) {
    return callArgs('getRange', [from.toProxy(), to.toProxy()]);
  }

  /**
   * Calculates and returns a `Position` object for a zero-based index who's
   * value is relative to the start of the editor's text. If the index is out of
   * range of the text then the returned object is clipped to start or end of
   * the text respectively.
   */
  Position posFromIndex(int index) =>
      new Position.fromProxy(callArg('posFromIndex', index));

  /**
   * The reverse of [posFromIndex].
   */
  int indexFromPos(Position pos) => callArg('indexFromPos', pos.toProxy());

  /**
   * Fired whenever a change occurs to the document. `changeObj` has a similar
   * type as the object passed to the editor's "change" event.
   */
  Stream get onChange => onEvent('change', true);
}

/**
 * Both `line` and `ch` are 0-based.
 *
 * `{line, ch}`
 */
class Position {
  final int line;
  final int ch;

  Position(this.line, this.ch);

  Position.fromProxy(var obj) : line = obj['line'], ch = obj['ch'];

  JsObject toProxy() => jsify({'line': line, 'ch': ch});

  operator==(other) => other is Position &&
      line == other.line && ch == other.ch;

  String toString() => '[${line}:${ch}]';
}

class ModeInfo extends ProxyHolder {
  factory ModeInfo(JsObject proxy) =>
      proxy == null ? null : new ModeInfo._(proxy);

  ModeInfo._(JsObject proxy) : super(proxy);

  /// The mode's human readable, display name.
  String get name => jsProxy['name'];

  String get mime => jsProxy['mime'];

  List<String> get mimes =>
      jsProxy.hasProperty('mimes') ? jsProxy['mimes']: [mime];

  /// The mode's id.
  String get mode => jsProxy['mode'];

  /// The mode's file extension.
  List<String> get ext => jsProxy['ext'];

  /// The mode's other file extensions.
  List<String> get alias =>
      jsProxy.hasProperty('alias') ? jsProxy['alias']: [];
}

/**
 * A source span from a start position ([head]) to an end position ([anchor]);
 */
class Span {
  final Position head;
  final Position anchor;

  Span(this.head, this.anchor);

  Span.fromProxy(var obj) :
      head = new Position.fromProxy(obj['head']),
      anchor = new Position.fromProxy(obj['anchor']);

  operator==(other) => other is Span &&
      head == other.head && anchor == other.anchor;

  String toString() => '${head}=>${anchor}]';
}

/**
 * An object that represents a marker.
 */
class TextMarker extends ProxyHolder {
  TextMarker(JsObject jsProxy): super(jsProxy);

  /**
   * Removes the mark.
   */
  void clear() => call('clear');

  /**
   * Returns a {from, to} object (both holding document positions), indicating
   * the current position of the marked range, or undefined if the marker is no
   * longer in the document.
   */
  dynamic find() => call('find');

  /**
   * Call if you've done something that might change the size of the marker (for
   * example changing the content of a replacedWith node), and want to cheaply
   * update the display.
   */
  void changed() => call('changed');
}

/**
 * See [CodeMirror.addLineWidget].
 */
class LineWidget extends ProxyHolder {
  LineWidget(JsObject jsProxy): super(jsProxy);

  /**
   * Removes the widget.
   */
  void clear() => call('clear');

  /**
   * Call this if you made some change to the widget's DOM node that might
   * affect its height. It'll force CodeMirror to update the height of the line
   * that contains the widget.
   */
  void changed() => call('changed');
}

/**
 * A parent class for objects that can hold references to JavaScript objects.
 * It has convenience methods for invoking methods on the JavaScript proxy,
 * a method to add event listeners to the proxy, and a [dispose] method.
 * `dispose` only needs to be called if event listeners were added to an object.
 */
abstract class ProxyHolder {
  final JsObject jsProxy;
  final Map<String, JsEventListener> _events = {};

  ProxyHolder(this.jsProxy);

  dynamic call(String methodName) => jsProxy.callMethod(methodName);

  dynamic callArg(String methodName, var arg) =>
      jsProxy.callMethod(methodName, [arg]);

  dynamic callArgs(String methodName, List args) =>
      jsProxy.callMethod(methodName, args);

  Stream onEvent(String eventName, [bool twoArgs = false]) {
    if (!_events.containsKey(eventName)) {
      _events[eventName] = new JsEventListener(jsProxy, eventName,
          cvtEvent: (twoArgs ? (e) => e : null), twoArgs: twoArgs);
    }
    return _events[eventName].stream;
  }

  /**
   * This method should be called if any events listeners were added to the
   * object.
   */
  void dispose() {
    if (_events.isNotEmpty) {
      for (JsEventListener event in _events.values) {
        event.dispose();
      }
    }
  }
}
