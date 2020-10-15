import 'dart:collection';

import 'package:Birb/ast/ast_node.dart';

class Scope {

  Scope(this.global) {
    variableDefinitions = ListQueue();
    functionDefinitions = ListQueue();
  }

  ASTNode owner;
  ListQueue<ASTNode> variableDefinitions;
  ListQueue<ASTNode> functionDefinitions;
  bool global;

  Scope copy() {
    final Scope scope = Scope(global);

    variableDefinitions.forEach((element) {
      scope.variableDefinitions.add(element.copy());
    });

    functionDefinitions.forEach((element) {
      scope.functionDefinitions.add(element.copy());
    });

    return scope;
  }
}
