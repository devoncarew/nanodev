
library editors;

import 'dart:async';
import 'dart:html' hide File;

import 'package:codemirror/codemirror.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as p;

import 'elements.dart';
import 'files.dart';
import 'outline.dart';

Outline outline;

class EditorArea extends DElement {
  StreamController _activeFileController = new StreamController.broadcast();

  TabBar tabBar;
  CodeMirror codeMirror;
  Doc _originalDoc;
  List<Editor> editors = [];
  List<Editor> _lastActiveEditors = [];

  Editor activeEditor;

  EditorArea(Element element) : super.from(element) {
    var e = element.shadowRoot.querySelector('cde-tabbar');
    tabBar = new TabBar.from(e);
    tabBar.element.on['activate'].listen((event) {
      Element target = event.target;
      if (target.tagName == 'CDE-TAB') {
        TabItem item = new TabItem.from(target);
        Editor editor = _editorFor(item.path);
        _activateEditor(editor);
      }
    });
    tabBar.element.on['close'].listen((event) {
      Element target = event.target;
      if (target.tagName == 'CDE-TAB') {
        TabItem item = new TabItem.from(target);
        Editor editor = _editorFor(item.path);
        editor.close();
      }
    });

    Map options = {
      'mode':  'htmlmixed',
      'theme': 'elegant' // '3024-day', 'elegant', 'monokai'
    };

    codeMirror = new CodeMirror.fromElement(_editorParent, options: options);
    codeMirror.setReadOnly(true, true);
    _originalDoc = codeMirror.getDoc();

    outline = new Outline.from(element.shadowRoot.querySelector('cde-outline'));

    onActiveFile.listen((f) {
      outline.summary = f == null ? '' : f.name;
      _updateCursorLocation();
    });

    codeMirror.onCursorActivity.listen((_) => _updateCursorLocation());
  }

  void _activateEditor(Editor editor) {
    if (activeEditor == editor) return;

    if (activeEditor != null) {
      activeEditor.deactivate();
    }

    activeEditor = editor;

    if (activeEditor != null) {
      editor.activate();
      _lastActiveEditors.remove(editor);
      _lastActiveEditors.add(editor);
    } else {
      codeMirror.setReadOnly(true, true);
      codeMirror.swapDoc(_originalDoc);
    }

    _activeFileController.add(activeEditor == null ? null : activeEditor.file);
  }

  Editor openFile(File file) {
    for (Editor editor in editors) {
      if (editor.file == file) {
        _activateEditor(editor);
        return editor;
      }
    }

    TabItem tab = new TabItem();
    tab.name = file.name;
    tab.path = file.path;
    tab.tooltip = file.path;
    tabBar.add(tab);
    Editor editor = new Editor(this, tab, file);
    editors.add(editor);
    _lastActiveEditors.add(editor);
    _activateEditor(editor);
    return editor;
  }

  List<File> getOpenFiles() => editors.map((e) => e.file).toList();

  Stream<File> get onActiveFile => _activeFileController.stream;

  Iterable<TabItem> get _tabs =>
      tabBar.element.children.map((e) => new TabItem.from(e));

  Editor _editorFor(String path) {
    return editors.firstWhere((e) => e.file.path == path, orElse: () => null);
  }

  Element get _editorParent => element.shadowRoot.querySelector('#codemirror');

  void _updateCursorLocation() {
    if (activeEditor == null) {
      outline.line = '';
      outline.column = '';
    } else {
      Position from = codeMirror.getCursor('from');
      Position to = codeMirror.getCursor('to');

      if (from == to) {
        outline.line = '${from.line + 1}';
        outline.column = '${from.ch + 1}';
      } else {
        int lines = to.line - from.line + 1;
        int chars = codeMirror.getDoc().getSelection().length;

        if (to.ch == 0) lines--;

        outline.line = '${lines} ${_pluralize("line", lines)}';
        outline.column = '${chars} ${_pluralize("charactor", chars)}';
      }
    }
  }

  void setTheme(String theme) => codeMirror.setTheme(theme);

  void focus() => codeMirror.focus();
}

class Editor {
  static final Map _extMap = {
      'md': 'markdown',
      'lock': 'javascript',
      'editorconfig': 'properties'};

  final EditorArea editorArea;
  final TabItem tab;
  final File file;

  Doc _doc;

  InlineDialog _gotoLineDialog;

  Editor(this.editorArea, this.tab, this.file) {
    String ext = p.extension(file.name).toLowerCase();
    if (ext.startsWith('.')) ext = ext.substring(1);
    String mode = _extMap[ext];

    if (mode == null) {
      if (CodeMirror.MODES.contains(ext)) {
        mode = ext;
      }
    }

    if (mode == null) {
      int len = mime.defaultMagicNumbersMaxLength;
      if (len > file.contents.length) {
        len = file.contents.length;
      }
      List<int> bytes = file.contents.substring(0, len).codeUnits;
      mode = mime.lookupMimeType(file.name, headerBytes: bytes);
    }

    _doc = new Doc(file.contents, mode);
    _doc.onChange.listen((_) => _updateDirty());
  }

  CodeMirror get codeMirror => editorArea.codeMirror;

  String get name => file.name;

  bool get dirty => !_doc.isClean();

  void activate() {
    // TODO: can this be called on the Doc?
    if (codeMirror.getReadOnly()) codeMirror.setReadOnly(false);

    tab.active = true;
    codeMirror.swapDoc(_doc);
    codeMirror.focus();
  }

  void save() {
    if (!dirty) return;

    file.contents = _doc.getValue();
    _doc.markClean();
    _updateDirty();
  }

  void deactivate() {
    tab.active = false;
  }

  void _updateDirty() {
    tab.dirty = dirty;
  }

  void close() {
    // TODO: handle file == dirty

    editorArea.editors.remove(this);

    List activeEditors = editorArea._lastActiveEditors;
    activeEditors.remove(this);

    if (activeEditors.isEmpty) {
      editorArea._activateEditor(null);
    } else {
      editorArea._activateEditor(activeEditors.last);
    }

    editorArea.tabBar.remove(tab);
  }

  void toggleFind() {
    // TODO:

    print('find');
  }

  void toggleGotoLine() {
    if (_gotoLineDialog == null) {
      _gotoLineDialog = new InlineDialog();
      editorArea._editorParent.children.add(_gotoLineDialog.element);
      _gotoLineDialog.focus();
      StreamSubscription sub;
      sub = _gotoLineDialog.onCancel.listen((_) {
        sub.cancel();
        toggleGotoLine();
      });
    } else {
      _gotoLineDialog.dispose();
      _gotoLineDialog = null;
      editorArea.focus();
    }
  }

  void gotoChar(int pos) {
    if (this == editorArea.activeEditor) {
      // TODO:
      print('todo: goto position ${pos}');
      //editorArea.codeMirror.
    } else {
      // TODO:

    }
  }
}

class TabItem extends DElement {
  TabItem() : super('cde-tab');
  TabItem.from(Element element) : super.from(element);

  String get name => getAttr('name');
  set name(String value) => setAttr('name', value);

  String get path => getAttr('path');
  set path(String value) => setAttr('path', value);

  String get tooltip => getAttr('tooltip');
  set tooltip(String value) => setAttr('tooltip', value);

  bool get dirty => hasAttr('dirty');
  set dirty(bool value) => toggleAttr('dirty', value);

  bool get active => hasAttr('active');
  set active(bool value) => toggleAttr('active', value);
}

/**
 * `cde-tabbar`
 */
class TabBar extends DElement {
  TabBar.from(Element element) : super.from(element);

  void add(TabItem tab) {
    element.children.add(tab.element);
  }

  void remove(TabItem tab) {
    element.children.remove(tab.element);
  }
}

/**
 * `cde-inline-dialog`
 */
class InlineDialog extends DElement {
  InputElement get _input => element.shadowRoot.querySelector('#input');

  InlineDialog() : super('cde-inline-dialog');
  InlineDialog.from(Element element) : super.from(element);

  focus() => _input.focus();

  Stream get onCancel => element.on['cancel'];
}

String _pluralize(String word, int count) => count == 1 ? word : '${word}s';
