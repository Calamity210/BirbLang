import 'package:Birb/utils/ast/ast_node.dart';

class Scope {
  ASTNode owner;
  List variableDefinitions;
  List functionDefinitions;
  bool global;
}

Scope initScope(bool global) {
  var scope = Scope()
    ..variableDefinitions = []
    ..functionDefinitions = []
    ..global = global;

  return scope;
}
