import 'dart:convert';
import 'dart:io';

import 'AST.dart';
import 'builtin.dart';
import 'data_type.dart';
import 'scope.dart';
import 'token.dart';

class Runtime {
  Scope scope;
  List listMethods;
  List mapMethods;
  String stdoutBuffer;
}

Scope getScope(Runtime runtime, AST node) {
  if (node.scope == null) {
    return runtime.scope;
  }

  return node.scope;
}

void multipleVariableDefinitionsError(int lineNum, String variableName) {
  print('[Line $lineNum] variable `$variableName` is already defined');
  exit(1);
}

AST listAddFPtr(Runtime runtime, AST self, List args) {
  for (int i = 0; i < args.length; i++) {
    self.listChildren.add(args[i]);
  }

  return self;
}

AST listRemoveFptr(Runtime runtime, AST self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_INT]);

  AST ast_int = args[0];

  if (ast_int.intVal > self.listChildren.length) {
    print('Index out of range');
    exit(1);
  }

  self.listChildren.remove(self.listChildren[ast_int.intVal]);

  return self;
}

AST mapAddFPtr(Runtime runtime, AST self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING, ASTType.AST_ANY]);

  self.map[args[0]] = args[1];

  return self;
}

AST mapRemoveFptr(Runtime runtime, AST self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING]);

  AST astString = args[0];

  if (!self.map.containsKey(astString.stringValue)) {
    print('Map does not contain `${astString.stringValue}`');
    exit(1);
  }

  self.map.remove(astString.stringValue);

  return self;
}

void collectAndSweepGarbage(Runtime runtime, List old_def_list, Scope scope) {
  if (scope == runtime.scope) {
    return;
  }

  var garbage = [];

  for (int i = 0; i < scope.variableDefinitions.length; i++) {
    AST newDef = scope.variableDefinitions[i];
    var exists = false;

    for (int j = 0; j < old_def_list.length; j++) {
      AST oldDef = old_def_list[j];

      if (oldDef == newDef) {
        exists = true;
      }
    }

    if (!exists) {
      garbage.add(newDef);
    }
  }

  for (int i = 0; i < garbage.length; i++) {
    scope.variableDefinitions.remove(garbage[i]);
  }
}

Future<AST> runtimeFuncCall(Runtime runtime, AST fcall, AST fdef) async {
  if (fcall.funcCallArgs.length != fdef.funcDefArgs.length) {
    print(
      'Error: [Line ${fcall.lineNum}] ${fdef.funcName} Expected ${fdef.funcDefArgs.length} arguments but found ${fcall.funcCallArgs.length} arguments\n',
    );

    exit(1);
  }

  var funcDefBodyScope = fdef.funcDefBody.scope;

  for (int i = funcDefBodyScope.variableDefinitions.length - 1; i > 0; i--) {
    funcDefBodyScope.variableDefinitions
        .add(funcDefBodyScope.variableDefinitions[i]);

    funcDefBodyScope.variableDefinitions.length = 0;
  }

  for (int x = 0; x < fcall.funcCallArgs.length; x++) {
    AST astArg = fcall.funcCallArgs[x];

    if (x > fdef.funcDefArgs.length - 1) {
      print('Error: [Line ${astArg.lineNum}] Too many arguments\n');
      exit(1);
      break;
    }

    AST astFDefArg = fdef.funcDefArgs[x];
    var argName = astFDefArg.variableName;

    var newVariableDef = initAST(ASTType.AST_VARIABLE_DEFINITION);
    newVariableDef.variableType = astFDefArg.variableType;

    if (astArg.type == ASTType.AST_VARIABLE) {
      var vdef = await getVarDefByName(
          runtime, getScope(runtime, astArg), astArg.variableName);

      if (vdef != null) {
        newVariableDef.variableValue = vdef.variableValue;
      }
    }

    newVariableDef.variableValue ??= await visit(runtime, astArg);

    newVariableDef.variableName = argName;

    funcDefBodyScope.variableDefinitions.add(newVariableDef);
  }

  return await visit(runtime, fdef.funcDefBody);
}

AST runtimeRegisterGlobalFunction(Runtime runtime, String fname, AstFPtr fptr) {
  var fdef = initAST(ASTType.AST_FUNC_DEFINITION);
  fdef.funcName = fname;
  fdef.fptr = fptr;
  runtime.scope.functionDefinitions.add(fdef);
  return fdef;
}

AST runtimeRegisterGlobalFutureFunction(
    Runtime runtime, String fname, FutAstFPtr fptr) {
  var fdef = initAST(ASTType.AST_FUNC_DEFINITION);
  fdef.funcName = fname;
  fdef.futureptr = fptr;
  runtime.scope.functionDefinitions.add(fdef);
  return fdef;
}

AST runtimeRegisterGlobalVariable(Runtime runtime, String vname, String vval) {
  var vdef = initAST(ASTType.AST_VARIABLE_DEFINITION);
  vdef.variableName = vname;
  vdef.variableType = initAST(ASTType.AST_STRING);
  vdef.variableValue = initAST(ASTType.AST_STRING);
  vdef.variableValue.stringValue = vval;
  runtime.scope.variableDefinitions.add(vdef);
  return vdef;
}

Runtime initRuntime() {
  var runtime = Runtime();
  runtime.scope = initScope(true);
  runtime.listMethods = [];
  runtime.mapMethods = [];

  INITIALIZED_NOOP = initAST(ASTType.AST_NOOP);

  initBuiltins(runtime);

  var LIST_ADD_FUNCTION_DEFINITION = initAST(ASTType.AST_FUNC_DEFINITION);
  LIST_ADD_FUNCTION_DEFINITION.funcName = 'add';
  LIST_ADD_FUNCTION_DEFINITION.fptr = listAddFPtr;
  runtime.listMethods.add(LIST_ADD_FUNCTION_DEFINITION);

  var LIST_REMOVE_FUNCTION_DEFINITION = initAST(ASTType.AST_FUNC_DEFINITION);
  LIST_REMOVE_FUNCTION_DEFINITION.funcName = 'remove';
  LIST_REMOVE_FUNCTION_DEFINITION.fptr = listRemoveFptr;
  runtime.listMethods.add(LIST_REMOVE_FUNCTION_DEFINITION);

  var MAP_ADD_FUNCTION_DEFINITION = initAST(ASTType.AST_FUNC_DEFINITION);
  MAP_ADD_FUNCTION_DEFINITION.funcName = 'add';
  MAP_ADD_FUNCTION_DEFINITION.fptr = mapAddFPtr;
  runtime.mapMethods.add(MAP_ADD_FUNCTION_DEFINITION);

  var MAP_REMOVE_FUNCTION_DEFINITION = initAST(ASTType.AST_FUNC_DEFINITION);
  MAP_REMOVE_FUNCTION_DEFINITION.funcName = 'remove';
  MAP_REMOVE_FUNCTION_DEFINITION.fptr = mapAddFPtr;
  runtime.mapMethods.add(MAP_REMOVE_FUNCTION_DEFINITION);

  return runtime;
}

Future<AST> visit(Runtime runtime, AST node) async {
  if (node == null) {
    return null;
  }

  switch (node.type) {
    case ASTType.AST_OBJECT:
      return node;
    case ASTType.AST_ENUM:
      return node;
    case ASTType.AST_VARIABLE:
      return await visitVariable(runtime, node);
    case ASTType.AST_VARIABLE_DEFINITION:
      return await visitVarDef(runtime, node);
    case ASTType.AST_VARIABLE_ASSIGNMENT:
      return await visitVarAssignment(runtime, node);
    case ASTType.AST_VARIABLE_MODIFIER:
      return await visitVarMod(runtime, node);
    case ASTType.AST_FUNC_DEFINITION:
      return await visitFuncDef(runtime, node);
    case ASTType.AST_FUNC_CALL:
      return await visitFuncCall(runtime, node);
    case ASTType.AST_NULL:
      return node;
    case ASTType.AST_STRING:
      return node;
    case ASTType.AST_DOUBLE:
      return node;
    case ASTType.AST_LIST:
      return node;
    case ASTType.AST_MAP:
      return node;
    case ASTType.AST_BOOL:
      return node;
    case ASTType.AST_INT:
      return node;
    case ASTType.AST_COMPOUND:
      return await visitCompound(runtime, node);
    case ASTType.AST_TYPE:
      return node;
    case ASTType.AST_BINARYOP:
      return await visitBinaryOp(runtime, node);
    case ASTType.AST_UNARYOP:
      return await visitUnaryOp(runtime, node);
    case ASTType.AST_NOOP:
      return node;
    case ASTType.AST_BREAK:
      return node;
    case ASTType.AST_RETURN:
      return node;
    case ASTType.AST_CONTINUE:
      return node;
    case ASTType.AST_TERNARY:
      return await visitTernary(runtime, node);
    case ASTType.AST_IF:
      return await visitIf(runtime, node);
    case ASTType.AST_WHILE:
      return await visitWhile(runtime, node);
    case ASTType.AST_FOR:
      return await visitFor(runtime, node);
    case ASTType.AST_ATTRIBUTE_ACCESS:
      return await visitAttAccess(runtime, node);
    case ASTType.AST_LIST_ACCESS:
      return await visitListAccess(runtime, node);
    case ASTType.AST_NEW:
      return await visitNew(runtime, node);
    case ASTType.AST_ITERATE:
      return await visitIterate(runtime, node);
    case ASTType.AST_ASSERT:
      return await visitAssert(runtime, node);
    default:
      print('Uncaught statement ${node.type}');
      exit(1);
  }
}

bool boolEval(AST node) {
  switch (node.type) {
    case ASTType.AST_INT:
      return node.intVal > 0;
    case ASTType.AST_DOUBLE:
      return node.doubleValue > 0;
    case ASTType.AST_BOOL:
      return node.boolValue;
    case ASTType.AST_STRING:
      return node.stringValue.isNotEmpty;
    default:
      return false;
  }
}

Future<AST> getVarDefByName(
    Runtime runtime, Scope scope, String varName) async {
  if (scope.owner != null) {
    if (varName == 'nest') {
      if (scope.owner.parent != null) {
        return scope.owner.parent;
      }

      return scope.owner;
    }
  }

  for (int i = 0; i < scope.variableDefinitions.length; i++) {
    AST varDef = scope.variableDefinitions[i];

    if (varDef.variableName == varName) {
      return varDef;
    }
  }

  return null;
}

Future<AST> visitVariable(Runtime runtime, AST node) async {
  var localScope = node.scope;
  var globalScope = runtime.scope;

  if (node.objectChildren != null && node.objectChildren.isNotEmpty) {
    for (int i = 0; i < node.objectChildren.length; i++) {
      AST objectVarDef = node.objectChildren[i];

      if (objectVarDef.type != ASTType.AST_VARIABLE_DEFINITION) {
        continue;
      }

      if (objectVarDef.variableName == node.variableName) {
        if (objectVarDef.variableValue == null) {
          return objectVarDef;
        }

        var value = await visit(runtime, objectVarDef.variableValue);
        value.typeValue = objectVarDef.variableType.typeValue;

        return value;
      }
    }
  } else if (node.enumChildren != null && node.enumChildren.isNotEmpty) {
    for (int i = 0; i < node.enumChildren.length; i++) {
      AST variable = node.enumChildren[i];

      if (variable.variableName == node.variableName) {
        if (variable.ast != null) {
          return variable.ast;
        } else {
          var intAST = initAST(ASTType.AST_INT);
          intAST.intVal = i;
          variable.ast = intAST;

          return variable.ast;
        }
      }
    }
  }

  if (localScope != null) {
    var varDef = await getVarDefByName(runtime, localScope, node.variableName);

    if (varDef != null) {
      if (varDef.type != ASTType.AST_VARIABLE_DEFINITION) {
        return varDef;
      }

      var value = await visit(runtime, node);
      value.typeValue = varDef.variableType.typeValue;

      return value;
    }

    for (int i = 0; i < localScope.functionDefinitions.length; i++) {
      AST funcDef = localScope.functionDefinitions[i];

      if (funcDef.funcName == node.variableName) {
        return funcDef;
      }
    }
  }

  if (!node.isObjectChild && globalScope != null) {
    var varDef = await getVarDefByName(runtime, globalScope, node.variableName);

    if (varDef != null) {
      if (varDef.type != ASTType.AST_VARIABLE_DEFINITION) {
        return varDef;
      }

      var value = await visit(runtime, varDef.variableValue);
      value.typeValue = varDef.variableType.typeValue;

      return value;
    }

    for (int i = 0; i < globalScope.functionDefinitions.length; i++) {
      AST funcDef = globalScope.functionDefinitions[i];

      if (funcDef.funcName == node.variableName) {
        return funcDef;
      }
    }
  }

  print(
      'Error: [Line ${node.lineNum}] Undefined variable `${node.variableName}`.');
  exit(1);
}

Future<AST> visitVarDef(Runtime runtime, AST node) async {
  if (node.scope == runtime.scope) {
    var varDefGlobal =
        await getVarDefByName(runtime, runtime.scope, node.variableName);

    if (varDefGlobal != null) {
      multipleVariableDefinitionsError(node.lineNum, node.variableName);
    }
  }

  if (node.scope != null) {
    var varDefLocal =
        await getVarDefByName(runtime, node.scope, node.variableName);

    if (varDefLocal != null) {
      multipleVariableDefinitionsError(node.lineNum, node.variableName);
    }
  }

  if (node.savedFuncCall != null) {
    node.variableValue = await visit(runtime, node.savedFuncCall);
  } else {
    if (node.variableValue != null) {
      if (node.variableValue.type == ASTType.AST_FUNC_CALL) {
        node.savedFuncCall = node.variableValue;
      }

      node.variableValue = await visit(runtime, node.variableValue);
    } else {
      node.variableValue = initAST(ASTType.AST_NULL);
    }
  }
  getScope(runtime, node).variableDefinitions.add(node);

  return node.variableValue ?? node;
}

Future<AST> visitVarAssignment(Runtime runtime, AST node) async {
  var left = node.variableAssignmentLeft;
  var localScope = node.scope;
  var globalScope = runtime.scope;

  if (node.objectChildren != null && node.objectChildren.isNotEmpty) {
    for (int i = 0; i < node.objectChildren.length; i++) {
      AST objectVarDef = node.objectChildren[i];

      if (objectVarDef.type != ASTType.AST_VARIABLE_DEFINITION) {
        continue;
      }

      if (objectVarDef.variableName == left.variableName) {
        var value = await visit(runtime, node.variableValue);

        if (value.type == ASTType.AST_DOUBLE) {
          value.intVal = value.doubleValue.toInt();
        }

        objectVarDef.variableValue = value;
        return value;
      }
    }
  }

  if (localScope != null) {
    var varDef = await getVarDefByName(runtime, localScope, left.variableName);

    if (varDef != null) {
      var value = await visit(runtime, node.variableValue);
      if (value.type == ASTType.AST_DOUBLE) {
        value.intVal = value.doubleValue.toInt();
      }

      varDef.variableValue = value;
      return value;
    }
  }

  if (globalScope != null) {
    var varDef = await getVarDefByName(runtime, globalScope, left.variableName);

    if (varDef != null) {
      var value = await visit(runtime, node.variableValue);

      if (value.type == ASTType.AST_DOUBLE) {
        value.intVal = value.doubleValue.toInt();
      }
      varDef.variableValue = value;

      return value;
    }
  }

  print(
      "Error: [Line ${left.lineNum}] Can't set undefined variable ${left.variableName}");
}

Future<AST> visitVarMod(Runtime runtime, AST node) async {
  AST value;

  var left = node.binaryOpLeft;
  var varScope = getScope(runtime, node);

  for (int i = 0; i < varScope.variableDefinitions.length; i++) {
    AST astVarDef = varScope.variableDefinitions[i];

    if (node.objectChildren != null) {
      for (int i = 0; i < node.objectChildren.length; i++) {
        AST objectVarDef = node.objectChildren[i];

        if (objectVarDef.type != ASTType.AST_VARIABLE_DEFINITION) continue;

        if (objectVarDef.variableName == left.variableName) {
          astVarDef = objectVarDef;
          break;
        }
      }
    }

    if (astVarDef.variableName == left.variableName) {
      value = await visit(runtime, node.binaryOpRight);

      switch (node.binaryOperator.type) {
        case TokenType.TOKEN_PLUS_EQUAL:
          {
            if (astVarDef.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_INT) {
              astVarDef.variableValue.intVal +=
                  value.intVal ?? value.doubleValue.toInt();
              astVarDef.variableValue.doubleValue +=
                  astVarDef.variableValue.intVal;
              return astVarDef.variableValue;
            } else if (astVarDef.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_DOUBLE) {
              astVarDef.variableValue.doubleValue +=
                  value.doubleValue ?? value.intVal;
              astVarDef.variableValue.intVal +=
                  astVarDef.variableValue.doubleValue.toInt();
              return astVarDef.variableValue;
            }
          }
          break;

        case TokenType.TOKEN_SUB_EQUAL:
          {
            if (astVarDef.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_INT) {
              astVarDef.variableValue.intVal -=
                  value.intVal ?? value.doubleValue.toInt();
              astVarDef.variableValue.doubleValue -=
                  astVarDef.variableValue.intVal;
              return astVarDef.variableValue;
            } else if (astVarDef.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_DOUBLE) {
              astVarDef.variableValue.doubleValue -=
                  value.doubleValue ?? value.intVal;
              astVarDef.variableValue.intVal -=
                  astVarDef.variableValue.doubleValue.toInt();
              return astVarDef.variableValue;
            }
          }
          break;

        case TokenType.TOKEN_MUL_EQUAL:
          {
            if (astVarDef.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_INT) {
              astVarDef.variableValue.intVal *=
                  value.intVal ?? value.doubleValue.toInt();
              astVarDef.variableValue.doubleValue *=
                  astVarDef.variableValue.intVal;
              return astVarDef.variableValue;
            } else if (astVarDef.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_DOUBLE) {
              astVarDef.variableValue.doubleValue *=
                  value.doubleValue ?? value.intVal;
              astVarDef.variableValue.intVal *=
                  astVarDef.variableValue.doubleValue.toInt();
              return astVarDef.variableValue;
            }
          }
          break;

        default:
          print(
              'Error: [Line ${node.lineNum}] `${node.binaryOperator.value}` is not a valid operator');
          exit(1);
      }
    }
  }
  print(
      "Error: [Line ${node.lineNum}] Can't set undefined variable `${node.variableName}`");
  exit(1);
}

Future<AST> visitFuncDef(Runtime runtime, AST node) async {
  var scope = getScope(runtime, node);
  scope.functionDefinitions.add(node);

  return node;
}

Future<AST> runtimeFuncLookup(Runtime runtime, Scope scope, AST node) async {
  AST funcDef;

  var visitedExpr = await visit(runtime, node.funcCallExpression);

  if (visitedExpr.type == ASTType.AST_FUNC_DEFINITION)
    funcDef = await visitedExpr;

  if (funcDef == null) return null;

  if (funcDef.futureptr != null) {
    var visitedFptrArgs = [];

    for (int i = 0; i < node.funcCallArgs.length; i++) {
      AST astArg = node.funcCallArgs[i];
      AST visited;

      if (astArg.type == ASTType.AST_VARIABLE) {
        var vDef = await getVarDefByName(
            runtime, getScope(runtime, astArg), astArg.variableName);

        if (vDef != null) visited = vDef.variableValue;
      }

      visited = visited ?? await visit(runtime, astArg);
      await visitedFptrArgs.add(visited);
    }

    var ret = await visit(runtime,
        await funcDef.futureptr(runtime, funcDef, await visitedFptrArgs));

    return ret;
  }

  if (funcDef.fptr != null) {
    var visitedFptrArgs = [];

    for (int i = 0; i < node.funcCallArgs.length; i++) {
      AST astArg = node.funcCallArgs[i];
      AST visited;

      if (astArg.type == ASTType.AST_VARIABLE) {
        var vDef = await getVarDefByName(
            runtime, getScope(runtime, astArg), astArg.variableName);

        if (vDef != null) visited = vDef.variableValue;
      }

      visited = visited ?? await visit(runtime, astArg);
      await visitedFptrArgs.add(visited);
    }

    var ret = await visit(
        runtime, funcDef.fptr(runtime, funcDef, await visitedFptrArgs));

    return ret;
  }

  if (funcDef.funcDefBody != null)
    return await runtimeFuncCall(runtime, node, funcDef);
  else if (funcDef.compChildren != null) {
    var finalRes = initAST(ASTType.AST_NULL);
    var dataType = funcDef.funcDefType.typeValue.type;

    if (dataType == DATATYPE.DATA_TYPE_INT) {
      finalRes.type = ASTType.AST_INT;
      finalRes.intVal = 0;
    } else if (dataType == DATATYPE.DATA_TYPE_DOUBLE) {
      finalRes.type = ASTType.AST_DOUBLE;
      finalRes.doubleValue = 0;
    } else if (dataType == DATATYPE.DATA_TYPE_STRING) {
      finalRes.type = ASTType.AST_STRING;
      finalRes.stringValue = '';
    }

    var callArgs = [];
    callArgs.add(finalRes);

    for (int i = 0; i < funcDef.compChildren.length; i++) {
      AST compChild = funcDef.compChildren[i];

      AST res;

      if (compChild.type == ASTType.AST_FUNC_DEFINITION) {
        if (i == 0)
          node.funcCallArgs = node.funcCallArgs;
        else
          node.funcCallArgs = callArgs;

        res = await runtimeFuncCall(runtime, node, compChild);
      } else {
        var fCall = initAST(ASTType.AST_FUNC_CALL);
        fCall.funcCallExpression = compChild;

        if (i == 0)
          fCall.funcCallArgs = node.funcCallArgs;
        else
          fCall.funcCallArgs = callArgs;

        res = await runtimeFuncLookup(runtime, scope, fCall);
      }

      switch (res.type) {
        case ASTType.AST_INT:
          finalRes.intVal = res.intVal;
          break;
        case ASTType.AST_DOUBLE:
          finalRes.doubleValue = res.doubleValue;
          break;
        case ASTType.AST_STRING:
          finalRes.stringValue = res.stringValue;
          break;
        default:
          break;
      }
    }
    return finalRes;
  }
  return null;
}

Future<AST> visitFuncCall(Runtime runtime, AST node) async {
  if (node.scope != null) {
    var localScopeFuncDef = await runtimeFuncLookup(runtime, node.scope, node);

    if (localScopeFuncDef != null) return localScopeFuncDef;
  }

  var globalScopeFuncDef =
      await runtimeFuncLookup(runtime, runtime.scope, node);
  if (globalScopeFuncDef != null) return globalScopeFuncDef;

  print('Error: [Line ${node.lineNum}] Undefined method `?`');
  exit(1);

  // To silence the analyzer
  return null;
}

Future<AST> visitCompound(Runtime runtime, AST node) async {
  var scope = getScope(runtime, node);
  var oldDefList = [];

  for (int i = 0; i < scope.variableDefinitions.length; i++) {
    AST varDef = scope.variableDefinitions[i];
    oldDefList.add(varDef);
  }

  for (int i = 0; i < node.compoundValue.length; i++) {
    AST child = node.compoundValue[i];

    if (child == null) continue;

    var visited = await visit(runtime, child);
    if (visited != null) {
      if (visited.type == ASTType.AST_RETURN) {
        if (visited.returnValue != null) {
          var retVal = await visit(runtime, await visited.returnValue);

          collectAndSweepGarbage(runtime, oldDefList, scope);
          return retVal;
        } else {
          collectAndSweepGarbage(runtime, oldDefList, scope);
          return null;
        }
      } else if (visited.type == ASTType.AST_BREAK ||
          await visited.type == ASTType.AST_CONTINUE) {
        return await visited;
      }
    }
  }

  collectAndSweepGarbage(runtime, oldDefList, scope);
  return node;
}

Future<AST> visitAttAccess(Runtime runtime, AST node) async {
  if (node.objectChildren != null)
    node.binaryOpLeft.objectChildren = node.objectChildren;

  var left = await visit(runtime, node.binaryOpLeft);

  if (left.type == ASTType.AST_LIST || left.type == ASTType.AST_STRING) {
    if (node.binaryOpRight.type == ASTType.AST_VARIABLE) {
      if (node.binaryOpRight.variableName == 'length') {
        var intAST = initAST(ASTType.AST_INT);

        if (left.type == ASTType.AST_LIST)
          intAST.intVal = left.listChildren.length;
        else if (left.type == ASTType.AST_STRING)
          intAST.intVal = left.stringValue.length;

        return intAST;
      } else if (node.binaryOpRight.variableName == 'input') {
        var str = left.stringValue;
        print(str);
        var astString = initAST(ASTType.AST_STRING);
        astString.stringValue =
            stdin.readLineSync(encoding: Encoding.getByName('utf-8')).trim();

        return astString;
      } else if (node.binaryOpRight.variableName == 'toBinary') {
        var str = left.stringValue;
        var binarys = str.codeUnits.map((e) => e.toRadixString(2));

        var astList = initAST(ASTType.AST_LIST);
        astList.listChildren = [];

        for (String binary in binarys) astList.listChildren.add(binary);

        return astList;
      } else if (node.binaryOpRight.variableName == 'toOct') {
        var str = left.stringValue;
        var octS = str.codeUnits.map((e) => e.toRadixString(8));

        var astList = initAST(ASTType.AST_LIST);
        astList.listChildren = [];

        for (String oct in octS) astList.listChildren.add(oct);

        return astList;
      } else if (node.binaryOpRight.variableName == 'toHex') {
        var str = left.stringValue;
        var hexS = str.codeUnits.map((e) => e.toRadixString(16));

        var astList = initAST(ASTType.AST_LIST);
        astList.listChildren = [];

        for (String hex in hexS) astList.listChildren.add(hex);

        return astList;
      } else if (node.binaryOpRight.variableName == 'toDec') {
        var str = left.stringValue;
        var astList = initAST(ASTType.AST_LIST);
        astList.listChildren = [];

        var decimals = str.codeUnits;
        for (int decimal in decimals) astList.listChildren.add(decimal);

        return astList;
      }
    }
  } else if (left.type == ASTType.AST_OBJECT) {
    if (node.binaryOpRight.type == ASTType.AST_VARIABLE ||
        node.binaryOpRight.type == ASTType.AST_VARIABLE_ASSIGNMENT ||
        node.binaryOpRight.type == ASTType.AST_VARIABLE_MODIFIER ||
        node.binaryOpRight.type == ASTType.AST_ATTRIBUTE_ACCESS) {
      node.binaryOpRight.objectChildren = left.objectChildren;
      node.binaryOpRight.scope = left.scope;
      node.binaryOpRight.isObjectChild = true;
      node.objectChildren = left.objectChildren;
      node.scope = left.scope;
    }
  } else if (left.type == ASTType.AST_ENUM) {
    if (node.binaryOpRight.type == ASTType.AST_VARIABLE) {
      node.binaryOpRight.enumChildren = left.enumChildren;
      node.binaryOpRight.scope = left.scope;
      node.enumChildren = left.enumChildren;
      node.scope = left.scope;
    }
  }

  if (node.binaryOpRight.type == ASTType.AST_FUNC_CALL) {
    if (node.binaryOpRight.funcCallExpression.type == ASTType.AST_VARIABLE) {
      var funcCallName = node.binaryOpRight.funcCallExpression.variableName;

      if (left.funcDefinitions != null) {
        for (int i = 0; i < left.funcDefinitions.length; i++) {
          AST fDef = left.funcDefinitions[i];

          if (fDef.funcName == funcCallName) {
            if (fDef.fptr != null) {
              var visitedFptrArgs = [];

              for (int j = 0; j < node.binaryOpRight.funcCallArgs.length; j++) {
                AST astArg = node.binaryOpRight.funcCallArgs[j];
                var visited = await visit(runtime, astArg);
                await visitedFptrArgs.add(visited);
              }

              return await visit(
                  runtime, fDef.fptr(runtime, left, await visitedFptrArgs));
            }
          }
        }
      }

      if (left.objectChildren != null) {
        for (int i = 0; i < left.objectChildren.length; i++) {
          AST objChild = left.objectChildren[i];

          if (objChild.type == ASTType.AST_FUNC_DEFINITION) if (objChild
                  .funcName ==
              funcCallName)
            return await runtimeFuncCall(runtime, node.binaryOpRight, objChild);
        }
      }
    }
  }

  node.scope = getScope(runtime, left);

  var newAST = await visit(runtime, node.binaryOpRight);

  return await visit(runtime, newAST);
}

Future<AST> visitListAccess(Runtime runtime, AST node) async {
  var left = await visit(runtime, node.binaryOpLeft);
  AST ast = await visit(runtime, node.listAccessPointer);

  if (ast.type == ASTType.AST_STRING) {
    var key = ast.stringValue;
    if (left.type != ASTType.AST_MAP) {
      print('Error: [Line ${node.lineNum}] Expected a Map');
      exit(1);
    }

    if (left.map.containsKey(key))
      return left.map[key];
    else
      return null;
  } else {
    var index = ast.intVal;
    if (left.type == ASTType.AST_LIST) if (left.listChildren.isNotEmpty &&
        index < left.listChildren.length)
      return left.listChildren[index];
    else {
      print(
          'Error: Invalid list index: Valid range is: ${left.listChildren.isNotEmpty ? left.listChildren.length - 1 : 0}');

      exit(1);
    }
    print('List Access left value is not iterable.');
    exit(1);
  }
}

Future<AST> visitBinaryOp(Runtime runtime, AST node) async {
  AST retVal;
  var left = await visit(runtime, node.binaryOpLeft);
  var right = node.binaryOpRight;

  if (node.binaryOperator.type == TokenType.TOKEN_DOT) {
    String accessName;

    if (right.type == ASTType.AST_VARIABLE) accessName = right.variableName;

    if (right.type == ASTType.AST_BINARYOP) right = await visit(runtime, right);

    if (left.type == ASTType.AST_OBJECT) {
      for (int i = 0; i < left.objectChildren.length; i++) {
        var child = await visit(runtime, left.objectChildren[i] as AST);

        if (child.type == ASTType.AST_VARIABLE_DEFINITION &&
            child.type == ASTType.AST_VARIABLE_ASSIGNMENT) {
          child.variableValue = await visit(runtime, right.variableValue);
          return child.variableValue;
        }

        if (child.type == ASTType.AST_VARIABLE_DEFINITION) {
          if (child.variableName == accessName) {
            if (child.variableValue != null)
              return await visit(runtime, child.variableValue);
            else
              return child;
          }
        } else if (child.type == ASTType.AST_FUNC_DEFINITION) {
          if (child.funcName == accessName) {
            for (int j = 0; j < right.funcCallArgs.length; j++) {
              AST astArg = right.funcCallArgs[j];

              if (j > child.funcDefArgs.length - 1) {
                print(
                    'Error: [Line ${astArg.lineNum}] Too many arguments for function `$accessName`');
                break;
              }

              var astFDefArg = child.funcDefArgs[j];
              String argName = astFDefArg.variableName;

              var newVarDef = initAST(ASTType.AST_VARIABLE_DEFINITION);
              newVarDef.variableValue = await visit(runtime, astArg);
              newVarDef.variableName = argName;

              getScope(runtime, child.funcDefBody)
                  .variableDefinitions
                  .add(newVarDef);
            }

            return await visit(runtime, child.funcDefBody);
          }
        }
      }
    }
  }

  right = await visit(runtime, right);

  switch (node.binaryOperator.type) {
    case TokenType.TOKEN_PLUS:
      {
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_INT);

          retVal.intVal = left.intVal + right.intVal;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE &&
            right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.doubleValue + right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.intVal + right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.doubleValue + right.intVal;

          return retVal;
        }
        if (left.type == ASTType.AST_STRING &&
            right.type == ASTType.AST_STRING) {
          retVal = initAST(ASTType.AST_STRING);

          retVal.stringValue = left.stringValue + right.stringValue;

          return retVal;
        }

        if (left.type == ASTType.AST_STRING && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_STRING);

          retVal.stringValue = left.stringValue + right.intVal.toString();

          return retVal;
        }
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_STRING) {
          retVal = initAST(ASTType.AST_STRING);

          retVal.stringValue = left.intVal.toString() + right.stringValue;

          return retVal;
        }
        if (left.type == ASTType.AST_STRING &&
            right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_STRING);

          retVal.stringValue = left.stringValue + right.doubleValue.toString();

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE &&
            right.type == ASTType.AST_STRING) {
          retVal = initAST(ASTType.AST_STRING);

          retVal.stringValue = left.doubleValue.toString() + right.stringValue;

          return retVal;
        }
      }

      break;

    case TokenType.TOKEN_SUB:
      {
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_INT);

          retVal.intVal = left.intVal - right.intVal;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE &&
            right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.doubleValue - right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.intVal - right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.doubleValue - right.intVal;

          return retVal;
        }
      }
      break;

    case TokenType.TOKEN_MUL:
      {
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_INT);

          retVal.intVal = left.intVal * right.intVal;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE &&
            right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.doubleValue * right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.intVal * right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.doubleValue * right.intVal;

          return retVal;
        }
      }
      break;

    case TokenType.TOKEN_DIV:
      {
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.intVal / right.intVal;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE &&
            right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.doubleValue / right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.intVal / right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_DOUBLE);

          retVal.doubleValue = left.doubleValue / right.intVal;

          return retVal;
        }
      }
      break;

    case TokenType.TOKEN_AND:
      {
        if (left.type == ASTType.AST_BOOL && right.type == ASTType.AST_BOOL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.boolValue && right.boolValue;

          return retVal;
        }
      }
      break;

    case TokenType.TOKEN_OR:
      {
        if (left.type == ASTType.AST_BOOL && right.type == ASTType.AST_BOOL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.boolValue || right.boolValue;

          return retVal;
        }
      }
      break;

    case TokenType.TOKEN_LESS_THAN:
      {
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.intVal < right.intVal;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE &&
            right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.doubleValue < right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.intVal < right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.doubleValue < right.intVal;

          return retVal;
        }
      }
      break;

    case TokenType.TOKEN_GREATER_THAN:
      {
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.intVal > right.intVal;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE &&
            right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.doubleValue > right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.intVal > right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.doubleValue > right.intVal;

          return retVal;
        }
      }
      break;

    case TokenType.TOKEN_EQUALITY:
      {
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.intVal == right.intVal;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE &&
            right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.doubleValue == right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.intVal == right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_NULL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.intVal == 0 || left.intVal == null;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.doubleValue == right.intVal;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_NULL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.doubleValue == 0 || left.doubleValue == null;

          return retVal;
        }
        if (left.type == ASTType.AST_STRING &&
            right.type == ASTType.AST_STRING) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.stringValue == right.stringValue;

          return retVal;
        }

        if (left.type == ASTType.AST_STRING && right.type == ASTType.AST_NULL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.stringValue == null;

          return retVal;
        }
        if (left.type == ASTType.AST_OBJECT &&
            right.type == ASTType.AST_OBJECT) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.objectChildren == right.objectChildren;

          return retVal;
        }

        if (left.type == ASTType.AST_OBJECT && right.type == ASTType.AST_NULL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.objectChildren.isEmpty;

          return retVal;
        }

        if (left.type == ASTType.AST_NULL && right.type == ASTType.AST_NULL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = true;

          return retVal;
        }
      }
      break;
    case TokenType.TOKEN_NOT_EQUAL:
      {
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.intVal != right.intVal;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE &&
            right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.doubleValue != right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_DOUBLE) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.intVal != right.doubleValue;

          return retVal;
        }
        if (left.type == ASTType.AST_INT && right.type == ASTType.AST_NULL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.intVal != 0 || left.intVal != null;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_INT) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.doubleValue != right.intVal;

          return retVal;
        }
        if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_NULL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.doubleValue != 0 || left.doubleValue != null;

          return retVal;
        }
        if (left.type == ASTType.AST_STRING &&
            right.type == ASTType.AST_STRING) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.stringValue != right.stringValue;

          return retVal;
        }

        if (left.type == ASTType.AST_STRING && right.type == ASTType.AST_NULL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.stringValue != null;

          return retVal;
        }
        if (left.type == ASTType.AST_OBJECT &&
            right.type == ASTType.AST_OBJECT) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.objectChildren != right.objectChildren;

          return retVal;
        }

        if (left.type == ASTType.AST_OBJECT && right.type == ASTType.AST_NULL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.objectChildren.isNotEmpty;

          return retVal;
        }

        if (left.type == ASTType.AST_NULL && right.type == ASTType.AST_NULL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = false;

          return retVal;
        }
      }
      break;

    default:
      print(
          'Error: [Line ${node.lineNum}] `${node.binaryOperator.value}` is not a valid operator');
      exit(1);
  }

  return node;
}

Future<AST> visitUnaryOp(Runtime runtime, AST node) async {
  AST right = await visit(runtime, node.unaryOpRight);

  AST returnValue = INITIALIZED_NOOP;

  switch (node.unaryOperator.type) {
    case TokenType.TOKEN_SUB:
      {
        if (right.type == ASTType.AST_INT) {
          returnValue = initAST(ASTType.AST_INT);
          returnValue.intVal = -right.intVal;
        } else if (right.type == ASTType.AST_DOUBLE) {
          returnValue = initAST(ASTType.AST_DOUBLE);
          returnValue.doubleValue = -right.doubleValue;
        }
      }
      break;

    case TokenType.TOKEN_PLUS:
      {
        if (right.type == ASTType.AST_INT) {
          returnValue = initAST(ASTType.AST_INT);
          returnValue.intVal = right.intVal.abs();
        } else if (right.type == ASTType.AST_DOUBLE) {
          returnValue = initAST(ASTType.AST_DOUBLE);
          returnValue.doubleValue = right.doubleValue.abs();
        }
      }
      break;

    default:
      print(
          'Error: [Line ${node.lineNum}] `${node.unaryOperator.value}` is not a valid operator');
      exit(1);
  }

  return returnValue;
}

Future<AST> visitIf(Runtime runtime, AST node) async {
  if (node.ifExpression == null) {
    print('Error: [Line ${node.lineNum}] If expression can\'t be empty');
    exit(1);
    return null;
  }

  if (boolEval(await visit(runtime, node.ifExpression))) {
    await visit(runtime, node.ifBody);
  } else {
    if (node.ifElse != null) return await visit(runtime, node.ifElse);

    if (node.elseBody != null) return await visit(runtime, node.elseBody);
  }

  return node;
}

Future<AST> visitTernary(Runtime runtime, AST node) async {
  return boolEval(await visit(runtime, node.ternaryExpression))
      ? await visit(runtime, node.ternaryBody)
      : await visit(runtime, node.ternaryElseBody);
}

Future<AST> visitWhile(Runtime runtime, AST node) async {
  while (boolEval(await visit(runtime, node.whileExpression))) {
    var visited = await visit(runtime, node.whileBody);

    if (visited.type == ASTType.AST_BREAK) break;
    if (visited.type == ASTType.AST_CONTINUE) continue;
  }

  return node;
}

Future<AST> visitFor(Runtime runtime, AST node) async {
  await visit(runtime, node.forInitStatement);

  while (boolEval(await visit(runtime, node.forConditionStatement))) {
    var visited = await visit(runtime, node.forBody);

    if (visited.type == ASTType.AST_BREAK) break;
    if (visited.type == ASTType.AST_CONTINUE) continue;

    await visit(runtime, node.forChangeStatement);
  }

  return node;
}

Future<AST> visitNew(Runtime runtime, AST node) async {
  return astCopy(await visit(runtime, node.newValue));
}

Future<AST> visitIterate(Runtime runtime, AST node) async {
  var scope = getScope(runtime, node);
  var astIterable = await visit(runtime, node.iterateIterable);

  AST fDef;

  if (node.iterateFunction.type == ASTType.AST_FUNC_DEFINITION)
    fDef = node.iterateFunction;

  if (fDef == null) {
    for (int i = 0; i < scope.functionDefinitions.length; i++) {
      fDef = scope.functionDefinitions[i];

      if (fDef.funcName == node.iterateFunction.variableName) {
        if (fDef.fptr != null) {
          print('Error: Can not iterate with native method');
          exit(1);
        }

        break;
      }
    }
  }

  var fdefBodyScope = fDef.funcDefBody.scope;
  var iterableVarName = (fDef.funcDefArgs[0] as AST).variableName;

  int i = 0;

  for (int j = fdefBodyScope.variableDefinitions.length - 1; j > 0; j--) {
    fdefBodyScope.variableDefinitions
        .remove(fdefBodyScope.variableDefinitions[j]);
  }

  AST indexVar;

  if (fDef.funcDefArgs.length > 1) {
    indexVar = initAST(ASTType.AST_VARIABLE_DEFINITION);
    indexVar.variableValue = initAST(ASTType.AST_INT);
    indexVar.variableValue.intVal = i;
    indexVar.variableName = (fDef.funcDefArgs[0] as AST).variableName;

    fdefBodyScope.variableDefinitions.add(indexVar);
  }

  if (astIterable.type == ASTType.AST_STRING) {
    var newVarDef = initAST(ASTType.AST_VARIABLE_DEFINITION);
    newVarDef.variableValue = initAST(ASTType.AST_STRING);
    newVarDef.variableValue.stringValue = astIterable.stringValue[i];
    newVarDef.variableName = iterableVarName;

    fdefBodyScope.variableDefinitions.add(newVarDef);

    for (; i < astIterable.stringValue.length; i++) {
      newVarDef.variableValue.stringValue = astIterable.stringValue[i];

      if (indexVar != null) indexVar.variableValue.intVal = i;

      await visit(runtime, fDef.funcDefBody);
    }
  } else if (astIterable.type == ASTType.AST_LIST) {
    var newVarDef = initAST(ASTType.AST_VARIABLE_DEFINITION);
    newVarDef.variableValue = await visit(runtime, astIterable.listChildren[i]);
    newVarDef.variableName = iterableVarName;

    fdefBodyScope.variableDefinitions.add(newVarDef);

    for (; i < astIterable.listChildren.length; i++) {
      newVarDef.variableValue =
          await visit(runtime, (astIterable.listChildren[i] as AST));

      if (indexVar != null) indexVar.variableValue.intVal = i;

      await visit(runtime, fDef.funcDefBody);
    }
  }

  return INITIALIZED_NOOP;
}

Future<AST> visitAssert(Runtime runtime, AST node) async {
  if (!boolEval(await visit(runtime, node.assertExpression))) {
    String str;

    if (node.assertExpression.type == ASTType.AST_BINARYOP) {
      var left = astToString(node.assertExpression.binaryOpLeft);
      var right = astToString(node.assertExpression.binaryOpRight);
      str = 'ASSERT($left, $right)';

      print(str);
    } else {
      var val = astToString(node.assertExpression);
      str = val;
      print(val);
    }

    print('[Line ${node.lineNum}] Assert failed! $str');
    exit(1);
  }

  return INITIALIZED_NOOP;
}

void runtimeExpectArgs(List inArgs, List<ASTType> args) {
  if (inArgs.length < args.length) {
    print(
        '${inArgs.length} argument(s) were provided, while ${args.length} were expected');
    exit(1);
  }

  for (int i = 0; i < args.length; i++) {
    if (args[i] == ASTType.AST_ANY) continue;

    AST ast = inArgs[i];

    if (ast.type != args[i]) {
      print('Received argument of type ${ast.type}, but expected ${args[i]}');
      print('Got unexpected arguments, terminating');
      exit(1);
    }
  }
}

void runtimeBufferStdout(Runtime runtime, String buffer) {
  runtime.stdoutBuffer = buffer;
}
