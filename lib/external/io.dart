import 'dart:io';

import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/runtime/standards.dart';
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/scope.dart';

void registerIO(Runtime runtime) {
  registerGlobalFunction(runtime, 'exit', funcExit);
  registerGlobalFunction(runtime, 'free', funcFree);
  registerGlobalFunction(runtime, 'getCwd', funcGetCwd);

  registerGlobalVariable(runtime, 'Process', processClass(runtime));
}

ASTNode funcExit(Runtime runtime, ASTNode self, List<ASTNode> args) {
  runtimeExpectArgs(args, [ASTType.AST_INT]);

  final exitAST = args[0];

  exit(exitAST.intVal);
}

StringNode funcGetCwd(Runtime runtime, ASTNode self, List<ASTNode> args) {
  return StringNode()..stringValue = Directory.current.absolute.path.toString();
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

ASTNode processClass(Runtime runtime) {
  final astObj = ClassNode();

  final FuncDefNode run = FuncDefNode();
  run.funcName = 'run';
  run.futureFuncPointer = processRun;

  astObj.classChildren.add(run);

  return astObj;
}

/// Process Functions

Future<ASTNode> processRun(
    Runtime runtime, ASTNode self, List<ASTNode> args) async {
  runtimeExpectArgs(
      args, [ASTType.AST_STRING, ASTType.AST_LIST, ASTType.AST_BOOL]);

  final ClassNode res = ClassNode();

  final bool shell = args[2].boolVal ?? false;

  final ProcessResult pr = await Process.run(args[0].stringValue,
      args[1].listElements.map((e) => e.toString()).toList(),
      runInShell: shell);

  final IntNode exitCode = IntNode();
  exitCode.intVal = pr.exitCode;
  exitCode.variableValue = exitCode;

  res.classChildren.add(exitCode);

  return res;
}

//  runtimeExpectArgs(
//     args, [ASTType.AST_STRING, ASTType.AST_LIST, ASTType.AST_BOOL]);

// Map<String, dynamic> result = {
//   'errorCode': null,
//   'stdout': null,
//   'stderr': null
// };

// MapNode res = MapNode();
// bool shell = args[2].boolVal ?? false;

// final ProcessResult pr = await Process.run(args[0].stringValue,
//     args[1].listElements.map((e) => e.toString()).toList(),
//     runInShell: shell);

// result['errorCode'] = pr.exitCode.toString();
// result['stdout'] = pr.stdout.toString();
// result['sterr'] = pr.stderr.toString();

// res.map = result;

// return res;
