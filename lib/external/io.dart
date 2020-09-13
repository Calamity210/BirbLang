import 'dart:io';

import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/runtime/standards.dart';
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/scope.dart';

void registerIO(Runtime runtime) {
  registerGlobalFunction(runtime, 'exit', funcExit);
  registerGlobalFunction(runtime, 'free', funcFree);
  registerGlobalVariable(runtime, 'cwd',
      StringNode()..stringValue = Directory.current.absolute.path.toString());
  registerGlobalFutureFunction(runtime, 'system', funcSystem);
}

ASTNode funcExit(Runtime runtime, ASTNode self, List<ASTNode> args) {
  runtimeExpectArgs(args, [ASTType.AST_INT]);

  final exitAST = args[0];

  exit(exitAST.intVal);
}

ASTNode funcFree(Runtime runtime, ASTNode self, List<ASTNode> args) {
  final Scope scope = getScope(runtime, self);

  args.forEach((arg) {
    if (arg is! VariableNode) return;

    scope.variableDefinitions
        .removeWhere((varDef) => varDef.variableName == arg.variableName);
  });

  return INITIALIZED_NOOP;
}

Future<MapNode> funcSystem(
    Runtime runtime, ASTNode self, List<ASTNode> args) async {
  runtimeExpectArgs(args, [ASTType.AST_STRING, ASTType.AST_LIST]);

  Map<String, dynamic> result = {
    'errorCode': null,
    'stdout': null,
    'stderr': null
  };

  MapNode res = MapNode();

  final ProcessResult pr = await Process.run(args[0].stringValue,
      args[1].listElements.map((e) => e.toString()).toList());

  result['errorCode'] = pr.exitCode;
  result['stdout'] = pr.stdout;
  result['sterr'] = pr.stderr;

  res.map = result;

  return res;
}
