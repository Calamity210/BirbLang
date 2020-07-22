import 'AST.dart';

class Scope {
  AST owner;
  List variableDefinitions;
  List functionDefinitions;
  bool global;
}

Scope initScope(bool global) {
  var scope = Scope();
  scope.variableDefinitions = [];
  scope.functionDefinitions = [];
  scope.global = global;

  return scope;
}

