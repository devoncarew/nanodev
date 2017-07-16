
library search;

import 'dart:async';
import 'dart:html' hide File;

import 'commands.dart';
import 'elements.dart';
import 'files.dart';
import 'ide.dart';

// TODO: Search participants: search in files, jump to a file, jump to a symbol, perform a command
// TODO: What do about lots of similar matches? Like index.html from several folders and projects
// TODO: So, you can have an exact match in several different locations
// TODO: And less likely, an exact match from different search participants
// TODO: Each participant is a kind ('command'). each match has what part matches, the full word, the quality of the match, and anything else to display (args, …)

// TODO: symbol search

class Search extends DElement {
  StreamController _cancelController = new StreamController.broadcast();
  SearchArea _searchArea;

  InputElement get _input => element.shadowRoot.querySelector('#input');

  String lastValue;
  SearchResults  _results;

  List<SearchParticipant> participants = [];

  Search() : super('cde-search') {
    _init();
  }

  Search.from(Element element) : super.from(element) {
    _init();
  }

  void _init() {
    element.on['cancel'].listen((_) => _handleCancel());
    _input.onFocus.listen((_) => _handleFocus());
    _input.onInput.listen((_) => _handleSearchChanged());
    _input.onKeyPress.listen(_handleKeyEvent);

    _searchArea = new SearchArea.from(
        element.shadowRoot.querySelector('cde-search-area'));

    participants.add(new FileNameSearchParticipant());
    participants.add(new CommandSearchParticipant(commandManager));
    participants.add(new FileContentSearchParticipant());
  }

  void focus() {
    element.focus();
    _input.focus();
    _searchArea.show = true;
  }

  String get currentValue => _input.value;

  void clear() {
    _input.value = '';
    _results = null;
  }

  Stream get onCancel => _cancelController.stream;

  void _handleFocus() {
    if (lastValue != null) {
      _input.value = lastValue;
      _input.select();
    }
  }

  void _handleSearchChanged() {
    _performSearch();
  }

  void _handleCancel() {
    lastValue = currentValue;
    clear();
    _cancelController.add(null);
    _searchArea.show = false;
  }

  void _performSearch() {
    String query = currentValue.trim();

    _results = new SearchResults();

    if (query.isNotEmpty) {
      for (SearchParticipant participant in participants) {
        List<SearchResult> r = participant.performSearch(query);

        if (r.isNotEmpty) {
          r.sort();
          _results.categories.add(new SearchCategory(participant.name, r));
        }
      }

      _results.categories.sort();
    }

    // TODO: visualize results
    print(_results);
  }

  void _handleKeyEvent(KeyboardEvent e) {
    // TODO: enter, tab
    if (e.keyCode == KeyCode.ENTER) {
      e.preventDefault();
      _fire();
    }
  }

  void _fire() {
    if (_results != null) {
      if (_results.categories.isNotEmpty) {
        SearchCategory category = _results.categories.first;
        if (category.results.isNotEmpty) {
          SearchResult result = category.results.first;
          result.selected();
          _handleCancel();
        }
      }
    }
  }
}

/**
 * `cde-search-area`
 */
class SearchArea extends DElement {
  SearchArea() : super('cde-search-area');
  SearchArea.from(Element element) : super.from(element);

  bool get show => hasAttr('show');
  set show(bool value) => toggleAttr('show', value);
}

abstract class SearchParticipant {
  final String name;

  SearchParticipant(this.name);

  List<SearchResult> performSearch(String phrase);
}

class SearchResults {
  final List<SearchCategory> categories = [];

  SearchResults();

  String toString() => categories.isEmpty ?
      "empty" : categories.map((c) => c.toString()).join(', ');
}

class SearchCategory implements Comparable<SearchCategory> {
  final String name;
  List<SearchResult> results = [];

  SearchCategory(this.name, [List<SearchResult> results]) {
    if (results != null) {
      this.results = results;
    }
  }

  num get quality => results.isEmpty ? 0.0 : results.first.quality;

  int compareTo(SearchCategory other) => other.quality.compareTo(quality);

  String toString() {
    if (results.length == 1) {
      return "${name}: 1 match ('${results.first}')";
    } else {
      return '${name}: ${results.length} matches';
    }
  }
}

abstract class SearchResult implements Comparable<SearchResult> {
  final num quality;

  SearchResult(this.quality);

  String get text;

  void selected();

  int compareTo(SearchResult other) => other.quality.compareTo(quality);

  String toString() => text;
}

class FileNameSearchParticipant extends SearchParticipant {
  FileNameSearchParticipant() : super('file names');

  List<SearchResult> performSearch(String phrase) {
    phrase = phrase.toLowerCase();

    Function _match = (File file) {
      // TODO: toLowerCase()
      return file.name.contains(phrase);
    };

    var results = workspace.allFiles.where(_match).map((File file) {
      num quality = phrase == file.name ? 1.0 : file.name.startsWith(phrase) ? 0.7 : 0.5;
      return new FileSearchResult(file, quality);
    });

    return results.toList();
  }
}

class FileSearchResult extends SearchResult {
  final File file;

  FileSearchResult(this.file, num quality) : super(quality);

  String get text => file.name;

  void selected() {
    ide.openFile(file);
  }
}

class FileContentSearchParticipant extends SearchParticipant {
  FileContentSearchParticipant() : super('file contents');

  List<SearchResult> performSearch(String phrase) {
    // Super short matches are disallowed.
    if (phrase.length <= 2) return [];

    RegExp regex = new RegExp(phrase, caseSensitive: false);

    Function _match = (File file) => regex.hasMatch(file.contents);

    var results = workspace.allFiles.where(_match).expand((File file) {
      return regex.allMatches(file.contents).map((Match match) {
        return new FileContentsSearchResult(file, match.start, phrase);
      });
    });

    return results.toList();
  }
}

class FileContentsSearchResult extends SearchResult {
  final File file;
  final int pos;
  final String text;

  FileContentsSearchResult(this.file, this.pos, this.text) : super(0.5);

  void selected() {
    ide.openFile(file, pos: pos);
  }
}

class CommandSearchParticipant extends SearchParticipant {
  final CommandManager commandManager;

  CommandSearchParticipant(this.commandManager) : super('commands');

  List<SearchResult> performSearch(String phrase) {
    phrase = phrase.toLowerCase();

    var r = commandManager.commands.where((c) => c.id.contains(phrase)).map((command) {
      String name = command.id;
      num quality = phrase == name ? 1.0 : name.startsWith(phrase) ? 0.7 : 0.5;
      return new CommandSearchResult(command, quality);
    });

    return r.toList();
  }
}

class CommandSearchResult extends SearchResult {
  final Command command;

  CommandSearchResult(this.command, num quality) : super(quality);

  String get text => command.id;

  void selected() {
    // TODO: handle any args
    Action action = command.createAction(null, []);
    action.execute();
  }
}
