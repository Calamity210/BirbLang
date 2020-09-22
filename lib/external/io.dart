import 'dart:io';

import 'package:Birb/lexer/lexer.dart';
import 'package:Birb/parser/parser.dart';
import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/runtime/standards.dart';
import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/scope.dart';

void registerIO(Runtime runtime) {
  registerGlobalFunction(runtime, 'exit', funcExit);
  registerGlobalFunction(runtime, 'free', funcFree);
  registerGlobalFutureFunction(runtime, 'execute', funcExecute);
}

Future<ASTNode> funcExecute(Runtime runtime, ASTNode self, List<ASTNode> args) async {
  runtimeExpectArgs(args, [ASTType.AST_STRING]);

  final Lexer lexer = initLexer(args[0].stringValue);
  final Parser parser = initParser(lexer);
  final ASTNode node = parse(parser);
  await visit(runtime, node);

  return AnyNode();
}

ASTNode funcExit(Runtime runtime, ASTNode self, List<ASTNode> args) {
  runtimeExpectArgs(args, [ASTType.AST_INT]);

  final exitAST = args[0];

  exit(exitAST.intVal);
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