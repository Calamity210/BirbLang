import 'AST.dart';
import 'dynamic_list.dart';

class Scope {
  AST owner;
  DynamicList variableDefinitions;
  DynamicList functionDefinitions;
  bool global;
}

Scope initScope(bool global) {
  var scope = Scope();
  scope.variableDefinitions = initDynamicList(0);
  scope.functionDefinitions = initDynamicList(0);
  scope.global = global;

  return scope;
}

