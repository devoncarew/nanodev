
library nanodev;

import 'dart:async';
import 'dart:html' hide File;

import 'commands.dart';
import 'elements.dart';
import 'editors.dart';
import 'files.dart';
import 'ide.dart';
import 'keys.dart';
import 'search.dart';
import 'settings.dart';

NanoDev app;

FilesView filesView;
EditorArea editorArea;
Keys keys;
Settings settings;
Search search;

class NanoDev implements IDE {
  NanoDev() {
    app = this;
    ide = this;
    keys = new Keys(commandManager);

    editorArea = new EditorArea(querySelector('editor-area'));
    settings = new Settings(editorArea);

    createWorkspace();

    var fab = querySelector('cde-toolbar cde-fab');
    if (fab != null) fab.onClick.listen((_) => handleNewProject());

    var button = querySelector('cde-icon-button[icon=settings]');
    button.onClick.listen((_) => handleSettings());

    search = new Search.from(querySelector('cde-search'));
    search.onCancel.listen((_) => editorArea.focus());

    setupCommands();
  }

  void start() {
    populateFilesView();

    filesView.onActiveFile.listen((file) {
      editorArea.openFile(file);
    });

    editorArea.onActiveFile.listen((file) => filesView.select(file));
  }

  void setupCommands() {
    keys.bind('ctrl-s', 'file-save');
    // TODO: This is handled by the browser.
    keys.bind('ctrl-w', 'file-close');
    keys.bind('macctrl-w', 'file-close');
    keys.bind('ctrl-,', 'open-settings');

    keys.bind('ctrl-f', 'editor-find');
    keys.bind('ctrl-l', 'editor-goto-line');

    keys.bind('ctrl-\\', 'global-search');

    keys.bind('shift-ctrl-[', 'editor-prev-tab');
    keys.bind('shift-ctrl-]', 'editor-next-tab');

    _addCommand('global-search', () => search.focus());

    _addEditorCommand('file-save', (editor) => editor.save());
    _addEditorCommand('file-close', (editor) => editor.close());
    _addEditorCommand('editor-find', (editor) => editor.toggleFind());
    _addEditorCommand('editor-goto-line', (editor) => editor.toggleGotoLine());

    _addCommand('open-settings', () => editorArea.openFile(settings.settingsFile));
  }

  void handleNewProject() {
    // TODO:

    print('handleNewProject');
  }

  void handleSettings() {
    commandManager.executeCommand(null, 'open-settings');
  }

  void populateFilesView() {
    filesView = new FilesView(querySelector('files-view'));
    workspace.children.forEach((c) => _populateFilesView(c, 0));
  }

  void _populateFilesView(Resource r, int indent) {
    FileItem item = new FileItem();
    item.name = r.name;
    item.path = r.path;
    item.indent = indent;
    filesView.add(item);

    if (r.name == 'pubspec.yaml') {
      item.meta = 'nanodev';
    } else if (r.name == 'bower.json') {
      item.meta = 'nanodev';
    }

    if (r is Container) {
      item.container = true;
      item.open = true;
      r.children.forEach((c) => _populateFilesView(c, indent + 1));
    }
  }

  void openFile(File file, {int pos}) {
    Editor editor = editorArea.openFile(file);
    editor.gotoChar(pos);
  }
}

void createWorkspace() {
  Project project = new Project('nanodev', workspace);

  Folder lib = new Folder('lib', project);
  new File('commands.dart', lib);
  new File('editors.dart', lib);
  new File('files.dart', lib);
  new File('outline.dart', lib);
  new File('nanodev.dart', lib);

  Folder web = new Folder('web', project);
  new File('main.dart', web);
  new File('index.html', web);
  new File('styles.css', web);

  //new File('.bowerrc', project);
  new File('bower.json', project);
  new File('pubspec.lock', project);
  new File('pubspec.yaml', project);
  new File('readme.md', project);

  _populate(project);

  project = new Project('bar_project', workspace);
}

void _populate(Resource resource) {
  if (resource is Container) {
    resource.children.forEach(_populate);
  } else {
    File f = resource;
    String path = f.path;
    Uri uri = Uri.base.resolve(path);
    HttpRequest.getString(uri.toString()).then((content) {
      f.contents = content;
    }).catchError((e) {
      uri = Uri.base.resolve(path.substring('nanodev/'.length));
      return HttpRequest.getString(uri.toString()).then((content) {
        f.contents = content;
      }).catchError((e) {
        f.contents = """
  Some sample contents.
  More contents.
  """;
      });
    });
  }
}

class FilesView extends DElement {
  StreamController _activeFileController = new StreamController.broadcast();

  FilesView(Element element) : super.from(element) {
    element.onClick.listen((event) {
      Element target = event.target;
      if (target.tagName == 'CDE-FILE-ITEM') {
        FileItem item = new FileItem.from(target);
        if (!item.container) {
          //select(item);
          _activeFileController.add(item.file);
        }
      }
    });
  }

  void add(FileItem item) {
    element.children.add(item.element);
  }

  void select(File file) {
    String path = file == null ? null : file.path;
    var items = element.children.map((e) => new FileItem.from(e));
    for (FileItem item in items) {
      item.selected = path == null ? false : item.path == path;
    }
  }

  Stream<File> get onActiveFile => _activeFileController.stream;
}

class FileItem extends DElement {
  FileItem() : super('cde-file-item');
  FileItem.from(Element element) : super.from(element);

  File get file => workspace.restore(path);

  String get name => getAttr('name');
  set name(String value) => setAttr('name', value);

  String get meta => getAttr('meta');
  set meta(String value) => setAttr('meta', value);

  String get path => getAttr('path');
  set path(String value) => setAttr('path', value);

  bool get open => hasAttr('open');
  set open(bool value) => toggleAttr('open', value);

  bool get container => hasAttr('container');
  set container(bool value) => toggleAttr('container', value);

  bool get selected => hasAttr('selected');
  set selected(bool value) => toggleAttr('selected', value);

  //int get indent => element.attributes['indent'];
  set indent(int value) {
    element.style.paddingLeft = '${value * 22}px';
    setAttr('indent', value.toString());
  }
}

void _addEditorCommand(String id, Function fn) {
  commandManager.addCommand(Command.create(id, () {
    Editor editor = editorArea.activeEditor;
    if (editor != null) fn(editor);
  }));
}

void _addCommand(String id, Function fn) {
  commandManager.addCommand(Command.create(id, fn));
}
