
library files;

final Workspace workspace = new Workspace();

class Workspace extends Container {
  Workspace() : super('', null);

  String get path => '';

  Resource restore(String path) {
    if (path == null) return null;

    Container parent = this;
    Resource result = null;

    if (path.startsWith('/')) path = path.substring(1);

    for (String name in path.split('/')) {
      if (parent == null) return null;
      result = parent.children.firstWhere((r) => r.name == name,
          orElse: () => null);
      parent = result is Container ? result : null;
    }

    return result;
  }

  List<File> get allFiles {
    List<File> result = [];

    Function _traverse;
    _traverse = (Container c) {
      for (var child in c.children) {
        if (child is File) {
          result.add(child);
        } else {
          _traverse(child as Container);
        }
      }
    };

    _traverse(this);

    return result;
  }
}

class Project extends Container {
  Project(String name, Workspace workspace) : super(name, workspace);
}

abstract class Container extends Resource {
  List<Resource> children = [];

  Container(String name, Container parent) : super(name, parent);
}

class Folder extends Container {
  Folder(String name, Container parent) : super(name, parent);
}

class File extends Resource {
  String contents = '';

  File(String name, Container parent) : super(name, parent);
}

abstract class Resource {
  final String name;
  final Container parent;

  Resource(this.name, this.parent) {
    if (parent != null) {
      parent.children.add(this);
    }
  }

  String get path => parent == null ? '/${name}' : '${parent.path}/${name}';

  String get projectRelativePath {
    if (this is Project) {
      return '/';
    } else {
      return parent is Project ? name : '${parent.projectRelativePath}/${name}';
    }
  }

  void dispose() {
    if (parent != null) {
      parent.children.remove(this);
    }
  }

  operator==(other) => other is Resource && path == other.path;

  String toString() => name;
}
