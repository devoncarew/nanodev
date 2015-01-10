
library settings;

import 'editors.dart';
import 'files.dart';

// TODO:

class Settings {
  final EditorArea editorArea;
  File settingsFile;

  Settings(this.editorArea) {
    // TODO:
    settingsFile = new SettingsFile(this);
  }
}

class SettingsFile implements File {
  final Settings settings;

  SettingsFile(this.settings);

  String _contents = _template;

  String get contents => _contents;

  void set contents(String value) {
    _contents = value;

    _parseTheme();
  }

  void dispose() { }

  String get name => 'global.editorconfig';

  Container get parent => null;

  String get path => '**/${name}';

  String get projectRelativePath => name;

  void _parseTheme() {
    String line = _contents.split('\n').firstWhere(
        (l) => l.startsWith('app-theme'), orElse: () => null);

    if (line != null) {
      try {
        line = line.substring(line.indexOf('=') + 1).trim();
        settings.editorArea.setTheme(line);
      } catch (e) {

      }
    }
  }
}

final String _template = """

# application configuration
enable-dart-analysis = true

# keybindings
key-ctrl-[ = prev-editor
key-ctrl-] = next-editor

# theme (3024-day, elegant, monokai)
app-theme = elegant

# Unix-style newlines with a newline ending every file
[*]
end_of_line = lf
insert_final_newline = true

# 4 space indentation
[*.py]
indent_style = space
indent_size = 4

# Tab indentation (no size specified)
[*.js]
indent_style = tab

# Indentation override for all JS under lib directory
[lib/**.js]
indent_style = space
indent_size = 2

# Matches the exact files either package.json or .travis.yml
[{package.json,.travis.yml}]
indent_style = space
indent_size = 2
""";
