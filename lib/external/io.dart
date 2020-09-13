import 'dart:io';

import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/runtime/standards.dart';
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/scope.dart';

void registerIO(Runtime runtime) {
  registerGlobalFunction(runtime, 'exit', funcExit);
  registerGlobalFunction(runtime, 'free', funcFree);
}

ASTNode funcExit(Runtime runtime, ASTNode self, List<ASTNode> args) {
  runtimeExpectArgs(args, [ASTType.AST_INT]);

  final exitAST = args[0];

  return IntNode()..intVal = exit(exitAST.intVal);
}

ASTNode funcFree(Runtime runtime, ASTNode self, List<ASTNode> args) {
  final Scope scope = getScope(runtime, self);

  args.forEach((arg) {
    if (arg is! VariableNode)
      return;

    scope.variableDefinitions.removeWhere((varDef) => varDef.variableName == arg.variableName);
  });

  return INITIALIZED_NOOP;
}