import 'package:Birb/utils/ast/ast_node.dart';

class Scope {
  ASTNode owner;
  List<ASTNode> variableDefinitions;
  List<ASTNode> functionDefinitions;
  bool global;

  Scope copy() {
    Scope scope = Scope();

    variableDefinitions.forEach((element) {
      scope.variableDefinitions.add(element.copy());
    });

    functionDefinitions.forEach((element) {
      scope.functionDefinitions.add(element.copy());
    });

    return scope;
  }
}

Scope initScope(bool global) {
  var scope = Scope()
    ..variableDefinitions = []
    ..functionDefinitions = []
    ..global = global;

  return scope;
}