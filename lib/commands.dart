
library commands;

import 'dart:async';

final CommandManager commandManager = new CommandManager();

/**
 * TODO:
 */
abstract class Command {
  static Command create(String id, Function fn) {
    return new _SimpleCommand(id, fn);
  }

  final String id;
  final String description;
  final String argsDescription;

  List<CommandArgument> _args;

  Command(this.id, {this.description, this.argsDescription}) {
    _args = _parseArgs(argsDescription);
  }

  List<CommandArgument> get args => _args;

  // TODO: doc
  Action createAction(Context context, List<String> args);

  List<CommandArgument> _parseArgs(String desc) {
    if (desc == null) return [];

    bool optional = false;

    // Convert '%s %s [%i %s]' into 'string string num (optional) string (optional)'.
    return desc.split(' ').map((str) {
      if (str.startsWith('[')) {
        str = str.substring(1);
        optional = true;
      }

      if (str.endsWith(']')) {
        str = str.substring(0, str.length - 1);
      }

      return new CommandArgument(str == '%s', optional);
    }).toList();
  }

  String toString() => id;
}

class CommandArgument {
  final bool isString;
  final bool optional;

  CommandArgument(this.isString, [this.optional = false]);

  bool get isNum => !isString;

  String toString() =>
      (isString ? 'string' : 'num') + (optional ? ' (optional)' : '');
}

// TODO: perhaps also have a CommandProvider class?

/**
 * TODO:
 */
class CommandManager {
  final List<Command> _commands = [];
  //ActionExecutor _actionExecutor;

  CommandManager();

  List<Command> get commands => _commands;

  void bind(String command, Function fn) =>
      addCommand(Command.create(command, fn));

  void addCommand(Command command) => _commands.add(command);

  Command getCommand(String id) {
    return _commands.firstWhere(
        (command) => command.id == id, orElse: () => null);
  }

  Future executeCommand(Context context, String id, [List<String> args = const []]) {
    Command command = getCommand(id);

    if (command != null) {
      Action action = command.createAction(context, args);
      //return _actionExecutor.perform(action);
      return new Future.value(action.execute());
    } else {
      print("command '${id}' not found");
      return new Future.value();
    }
  }
}

class _SimpleCommand extends Command {
  final Function fn;

  _SimpleCommand(String id, this.fn) : super(id);

  Action createAction(Context context, List<String> args) {
    return new SimpleAction(id, fn);
  }
}

class Context {

}

class SimpleAction extends Action {
  final Function fn;

  SimpleAction(String description, this.fn) : super(description);

  void execute() {
    fn();
  }
}

/**
 * TODO:
 */
abstract class Action {
  final String name;

  Action(this.name);

  /**
   * Perform the action. This method can return [Future] or `null`. If it
   * returns a `Future`, the action will not be considered to be complete
   * until the `Future` has completed.
   */
  dynamic execute();

  bool get canUndo => false;

  /**
   * Roll back the action. This method can return [Future] or `null`. If it
   * returns a `Future`, the action will not be considered to be undone
   * until the `Future` has completed.
   */
  dynamic undo() => null;

  String toString() => name;
}
