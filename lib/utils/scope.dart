import 'dart:collection';

import 'package:Birb/ast/ast_node.dart';

class Scope {
  ASTNode owner;
  ListQueue<ASTNode> variableDefinitions;
  ListQueue<ASTNode> functionDefinitions;
  bool global;

  Scope copy() {
    final Scope scope = Scope();

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
  final scope = Scope()
    ..variableDefinitions = ListQueue()
    ..functionDefinitions = ListQueue()
    ..global = global;

  return scope;
}