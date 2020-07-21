import 'dart:convert';
import 'dart:io';

import 'AST.dart';
import 'builtin.dart';
import 'data_type.dart';
import 'dynamic_list.dart';
import 'scope.dart';
import 'token.dart';

class Runtime {
  Scope scope;
  DynamicList listMethods;
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

AST listAddFPtr(Runtime runtime, AST self, DynamicList args) {
  for (var i = 0; i < args.size; i++) {
    dynamicListAppend(self.listChildren, args.items[i]);
  }

  return self;
}

AST listRemoveFptr(Runtime runtime, AST self, DynamicList args) {
  runtimeExpectArgs(args, [ASTType.AST_INT]);

  AST ast_int = args.items[0];

  if (ast_int.intVal > self.listChildren.size) {
    print('Index out of range');
    exit(1);
  }

  dynamicListRemove(
      self.listChildren, self.listChildren.items[ast_int.intVal], null);

  return self;
}

void collectAndSweepGarbage(
    Runtime runtime, DynamicList old_def_list, Scope scope) {
  if (scope == runtime.scope) {
    return;
  }

  var garbage = initDynamicList(0);

  for (var i = 0; i < scope.variableDefinitions.size; i++) {
    AST newDef = scope.variableDefinitions.items[i];
    var exists = false;

    for (var j = 0; j < old_def_list.size; j++) {
      AST oldDef = old_def_list.items[j];

      if (oldDef == newDef) {
        exists = true;
      }
    }

    if (!exists) {
      dynamicListAppend(garbage, newDef);
    }
  }

  for (var i = 0; i < garbage.size; i++) {
    dynamicListRemove(scope.variableDefinitions, garbage.items[i], null);
  }
}

AST runtimeFuncCall(Runtime runtime, AST fcall, AST fdef) {
  if (fcall.funcCallArgs.size != fdef.funcDefArgs.size) {
    print(
      'Error: [Line ${fcall.lineNum}] ${fdef.funcName} Expected ${fdef.funcDefArgs.size} arguments but found ${fcall.funcCallArgs.size} arguments\n',
    );

    exit(1);
  }

  var funcDefBodyScope = fdef.funcDefBody.scope;

  for (var i = funcDefBodyScope.variableDefinitions.size - 1; i > 0; i--) {
    dynamicListRemove(funcDefBodyScope.variableDefinitions,
        funcDefBodyScope.variableDefinitions.items[i], null);

    funcDefBodyScope.variableDefinitions.size = 0;
  }

  for (var x = 0; x < fcall.funcCallArgs.size; x++) {
    AST astArg = fcall.funcCallArgs.items[x];

    if (x > fdef.funcDefArgs.size - 1) {
      print('Error: [Line ${astArg.lineNum}] Too many arguments\n');
      exit(1);
      break;
    }

    AST astFDefArg = fdef.funcDefArgs.items[x];
    var argName = astFDefArg.variableName;

    var newVariableDef = initAST(ASTType.AST_VARIABLE_DEFINITION);
    newVariableDef.variableType = astFDefArg.variableType;

    if (astArg.type == ASTType.AST_VARIABLE) {
      var vdef = getVarDefByName(
          runtime, getScope(runtime, astArg), astArg.variableName);

      if (vdef != null) {
        newVariableDef.variableValue = vdef.variableValue;
      }
    }

    newVariableDef.variableValue ??= runtimeVisit(runtime, astArg);

    newVariableDef.variableName = argName;

    dynamicListAppend(funcDefBodyScope.variableDefinitions, newVariableDef);
  }

  return runtimeVisit(runtime, fdef.funcDefBody);
}

AST runtimeRegisterGlobalFunction(Runtime runtime, String fname, AstFPtr fptr) {
  var fdef = initAST(ASTType.AST_FUNC_DEFINITION);
  fdef.funcName = fname;
  fdef.fptr = fptr;
  dynamicListAppend(runtime.scope.functionDefinitions, fdef);
  return fdef;
}

AST runtimeRegisterGlobalVariable(Runtime runtime, String vname, String vval) {
  var vdef = initAST(ASTType.AST_VARIABLE_DEFINITION);
  vdef.variableName = vname;
  vdef.variableType = initAST(ASTType.AST_STRING);
  vdef.variableValue = initAST(ASTType.AST_STRING);
  vdef.variableValue.stringValue = vval;
  dynamicListAppend(runtime.scope.variableDefinitions, vdef);
  return vdef;
}

Runtime initRuntime() {
  var runtime = Runtime();
  runtime.scope = initScope(true);
  runtime.listMethods = initDynamicList(0);

  INITIALIZED_NOOP = initAST(ASTType.AST_NOOP);

  initBuiltins(runtime);

  var LIST_ADD_FUNCTION_DEFINITION = initAST(ASTType.AST_FUNC_DEFINITION);
  LIST_ADD_FUNCTION_DEFINITION.funcName = 'add';
  LIST_ADD_FUNCTION_DEFINITION.fptr = listAddFPtr;
  dynamicListAppend(runtime.listMethods, LIST_ADD_FUNCTION_DEFINITION);

  var LIST_REMOVE_FUNCTION_DEFINITION = initAST(ASTType.AST_FUNC_DEFINITION);
  LIST_REMOVE_FUNCTION_DEFINITION.funcName = 'remove';
  LIST_REMOVE_FUNCTION_DEFINITION.fptr = listRemoveFptr;
  dynamicListAppend(runtime.listMethods, LIST_REMOVE_FUNCTION_DEFINITION);

  return runtime;
}

AST runtimeVisit(Runtime runtime, AST node) {
  if (node == null) {
    return null;
  }

  switch (node.type) {
    case ASTType.AST_OBJECT:
      return runtimeVisitObject(runtime, node);
    case ASTType.AST_ENUM:
      return runtimeVisitEnum(runtime, node);
    case ASTType.AST_VARIABLE:
      return runtimeVisitVariable(runtime, node);
    case ASTType.AST_VARIABLE_DEFINITION:
      return runtimeVisitVarDef(runtime, node);
    case ASTType.AST_VARIABLE_ASSIGNMENT:
      return runtimeVisitVarAssignment(runtime, node);
    case ASTType.AST_VARIABLE_MODIFIER:
      return runtimeVisitVarMod(runtime, node);
    case ASTType.AST_FUNC_DEFINITION:
      return runtimeVisitFuncDef(runtime, node);
    case ASTType.AST_FUNC_CALL:
      return runtimeVisitFuncCall(runtime, node);
    case ASTType.AST_NULL:
      return runtimeVisitNull(runtime, node);
    case ASTType.AST_STRING:
      return runtimeVisitString(runtime, node);
    case ASTType.AST_DOUBLE:
      return runtimeVisitDouble(runtime, node);
    case ASTType.AST_LIST:
      return runtimeVisitList(runtime, node);
    case ASTType.AST_BOOL:
      return runtimeVisitBool(runtime, node);
    case ASTType.AST_INT:
      return runtimeVisitInt(runtime, node);
    case ASTType.AST_COMPOUND:
      return runtimeVisitCompound(runtime, node);
    case ASTType.AST_TYPE:
      return runtimeVisitType(runtime, node);
    case ASTType.AST_BINARYOP:
      return runtimeVisitBinaryOp(runtime, node);
    case ASTType.AST_UNARYOP:
      return runtimeVisitUnaryOp(runtime, node);
    case ASTType.AST_NOOP:
      return runtimeVisitNoop(runtime, node);
    case ASTType.AST_BREAK:
      return runtimeVisitBreak(runtime, node);
    case ASTType.AST_RETURN:
      return runtimeVisitReturn(runtime, node);
    case ASTType.AST_CONTINUE:
      return runtimeVisitContinue(runtime, node);
    case ASTType.AST_TERNARY:
      return runtimeVisitTernary(runtime, node);
    case ASTType.AST_IF:
      return runtimeVisitIf(runtime, node);
    case ASTType.AST_WHILE:
      return runtimeVisitWhile(runtime, node);
    case ASTType.AST_FOR:
      return runtimeVisitFor(runtime, node);
    case ASTType.AST_ATTRIBUTE_ACCESS:
      return runtimeVisitAttAccess(runtime, node);
    case ASTType.AST_LIST_ACCESS:
      return runtimeVisitListAccess(runtime, node);
    case ASTType.AST_NEW:
      return runtimeVisitNew(runtime, node);
    case ASTType.AST_ITERATE:
      return runtimeVisitIterate(runtime, node);
    case ASTType.AST_ASSERT:
      return runtimeVisitAssert(runtime, node);
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

AST getVarDefByName(Runtime runtime, Scope scope, String varName) {
  if (scope.owner != null) {
    if (varName == 'nest') {
      if (scope.owner.parent != null) {
        return scope.owner.parent;
      }

      return scope.owner;
    }
  }

  for (var i = 0; i < scope.variableDefinitions.size; i++) {
    var varDef = scope.variableDefinitions.items[i] as AST;

    if (varDef.variableName == varName) {
      return varDef;
    }
  }

  return null;
}

AST runtimeVisitVariable(Runtime runtime, AST node) {
  var localScope = node.scope;
  var globalScope = runtime.scope;

  if (node.objectChildren != null && node.objectChildren.size > 0) {
    for (var i = 0; i < node.objectChildren.size; i++) {
      var objectVarDef = node.objectChildren.items[i] as AST;

      if (objectVarDef.type != ASTType.AST_VARIABLE_DEFINITION) {
        continue;
      }

      if (objectVarDef.variableName == node.variableName) {
        if (objectVarDef.variableValue == null) {
          return objectVarDef;
        }

        var value = runtimeVisit(runtime, objectVarDef.variableValue);
        value.typeValue = objectVarDef.variableType.typeValue;

        return value;
      }
    }
  } else if (node.enumChildren != null && node.enumChildren.size > 0) {
    for (var i = 0; i < node.enumChildren.size; i++) {
      var variable = node.enumChildren.items[i] as AST;

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
    var varDef = getVarDefByName(runtime, localScope, node.variableName);

    if (varDef != null) {
      if (varDef.type != ASTType.AST_VARIABLE_DEFINITION) {
        return varDef;
      }

      var value = runtimeVisit(runtime, node);
      value.typeValue = varDef.variableType.typeValue;

      return value;
    }

    for (var i = 0; i < localScope.functionDefinitions.size; i++) {
      var funcDef = localScope.functionDefinitions.items[i] as AST;

      if (funcDef.funcName == node.variableName) {
        return funcDef;
      }
    }
  }

  if (!node.isObjectChild && globalScope != null) {
    var varDef = getVarDefByName(runtime, globalScope, node.variableName);

    if (varDef != null) {
      if (varDef.type != ASTType.AST_VARIABLE_DEFINITION) {
        return varDef;
      }

      var value = runtimeVisit(runtime, varDef.variableValue);
      value.typeValue = varDef.variableType.typeValue;

      return value;
    }

    for (var i = 0; i < globalScope.functionDefinitions.size; i++) {
      var funcDef = globalScope.functionDefinitions.items[i] as AST;

      if (funcDef.funcName == node.variableName) {
        return funcDef;
      }
    }
  }

  print(
      'Error: [Line ${node.lineNum}] Undefined variable `${node.variableName}`.');
  exit(1);
}

AST runtimeVisitVarDef(Runtime runtime, AST node) {
  if (node.scope == runtime.scope) {
    var varDefGlobal =
        getVarDefByName(runtime, runtime.scope, node.variableName);

    if (varDefGlobal != null) {
      multipleVariableDefinitionsError(node.lineNum, node.variableName);
    }
  }

  if (node.scope != null) {
    var varDefLocal = getVarDefByName(runtime, node.scope, node.variableName);

    if (varDefLocal != null) {
      multipleVariableDefinitionsError(node.lineNum, node.variableName);
    }
  }

  if (node.savedFuncCall != null) {
    node.variableValue = runtimeVisit(runtime, node.savedFuncCall);
  } else {
    if (node.variableValue != null) {
      if (node.variableValue.type == ASTType.AST_FUNC_CALL) {
        node.savedFuncCall = node.variableValue;
      }

      node.variableValue = runtimeVisit(runtime, node.variableValue);
    } else {
      node.variableValue = initAST(ASTType.AST_NULL);
    }
  }
  dynamicListAppend(getScope(runtime, node).variableDefinitions, node);

  return node.variableValue ?? node;
}

AST runtimeVisitVarAssignment(Runtime runtime, AST node) {
  AST value;

  var left = node.variableAssignmentLeft;
  var localScope = node.scope;
  var globalScope = runtime.scope;

  if (node.objectChildren != null && node.objectChildren.size > 0) {
    for (var i = 0; i < node.objectChildren.size; i++) {
      var objectVarDef = node.objectChildren.items[i] as AST;

      if (objectVarDef.type != ASTType.AST_VARIABLE_DEFINITION) {
        continue;
      }

      if (objectVarDef.variableName == left.variableName) {
        var value = runtimeVisit(runtime, node.variableValue);

        if (value.type == ASTType.AST_DOUBLE) {
          value.intVal = value.doubleValue.toInt();
        }

        objectVarDef.variableValue = value;
        return value;
      }
    }
  }

  if (localScope != null) {
    var varDef = getVarDefByName(runtime, localScope, left.variableName);

    if (varDef != null) {
      var value = runtimeVisit(runtime, node.variableValue);
      if (value.type == ASTType.AST_DOUBLE) {
        value.intVal = value.doubleValue.toInt();
      }

      varDef.variableValue = value;
      return value;
    }
  }

  if (globalScope != null) {
    var varDef = getVarDefByName(runtime, globalScope, left.variableName);

    if (varDef != null) {
      var value = runtimeVisit(runtime, node.variableValue);

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

AST runtimeVisitVarMod(Runtime runtime, AST node) {
  AST value;

  var left = node.binaryOpLeft;
  var varScope = getScope(runtime, node);

  for (int i = 0; i < varScope.variableDefinitions.size; i++) {
    var astVarDef = varScope.variableDefinitions.items[i] as AST;

    if (node.objectChildren != null) {
      for (int i = 0; i < node.objectChildren.size; i++) {
        var objectVarDef = node.objectChildren.items[i] as AST;

        if (objectVarDef.type != ASTType.AST_VARIABLE_DEFINITION) continue;

        if (objectVarDef.variableName == left.variableName) {
          astVarDef = objectVarDef;
          break;
        }
      }
    }

    if (astVarDef.variableName == left.variableName) {
      value = runtimeVisit(runtime, node);

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

AST runtimeVisitFuncDef(Runtime runtime, AST node) {
  var scope = getScope(runtime, node);
  dynamicListAppend(scope.functionDefinitions, node);

  return node;
}

AST runtimeFuncLookup(Runtime runtime, Scope scope, AST node) {
  AST funcDef;

  var visitedExpr = runtimeVisit(runtime, node.funcCallExpression);

  if (visitedExpr.type == ASTType.AST_FUNC_DEFINITION) funcDef = visitedExpr;

  if (funcDef == null) return null;

  if (funcDef.fptr != null) {
    var visitedFptrArgs = initDynamicList(0);

    for (int i = 0; i < node.funcCallArgs.size; i++) {
      var astArg = node.funcCallArgs.items[i] as AST;
      AST visited;

      if (astArg.type == ASTType.AST_VARIABLE) {
        var vDef = getVarDefByName(
            runtime, getScope(runtime, astArg), astArg.variableName);

        if (vDef != null) visited = vDef.variableValue;
      }

      visited = visited ?? runtimeVisit(runtime, astArg);
      dynamicListAppend(visitedFptrArgs, visited);
    }

    var ret =
        runtimeVisit(runtime, funcDef.fptr(runtime, funcDef, visitedFptrArgs));

    return ret;
  }

  if (funcDef.funcDefBody != null)
    return runtimeFuncCall(runtime, node, funcDef);
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

    var callArgs = initDynamicList(0);
    dynamicListAppend(callArgs, finalRes);

    for (int i = 0; i < funcDef.compChildren.size; i++) {
      var compChild = funcDef.compChildren.items[i] as AST;

      AST res;

      if (compChild.type == ASTType.AST_FUNC_DEFINITION) {
        if (i == 0)
          node.funcCallArgs = node.funcCallArgs;
        else
          node.funcCallArgs = callArgs;

        res = runtimeFuncCall(runtime, node, compChild);
      } else {
        var fCall = initAST(ASTType.AST_FUNC_CALL);
        fCall.funcCallExpression = compChild;

        if (i == 0)
          fCall.funcCallArgs = node.funcCallArgs;
        else
          fCall.funcCallArgs = callArgs;

        res = runtimeFuncLookup(runtime, scope, fCall);
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

AST runtimeVisitFuncCall(Runtime runtime, AST node) {
  if (node.scope != null) {
    var localScopeFuncDef = runtimeFuncLookup(runtime, node.scope, node);

    if (localScopeFuncDef != null) return localScopeFuncDef;
  }

  var globalScopeFuncDef = runtimeFuncLookup(runtime, runtime.scope, node);
  if (globalScopeFuncDef != null) return globalScopeFuncDef;

  print('Error: [Line ${node.lineNum}] Undefined method `?`');
  exit(1);

  // To silence the analyzer
  return null;
}

AST runtimeVisitNull(Runtime runtime, AST node) {
  return node;
}

AST runtimeVisitString(Runtime runtime, AST node) {
  return node;
}

AST runtimeVisitDouble(Runtime runtime, AST node) {
  return node;
}

AST runtimeVisitObject(Runtime runtime, AST node) {
  return node;
}

AST runtimeVisitEnum(Runtime runtime, AST node) {
  return node;
}

AST runtimeVisitList(Runtime runtime, AST node) {
  node.funcDefinitions = runtime.listMethods;
  return node;
}

AST runtimeVisitBool(Runtime runtime, AST node) {
  return node;
}

AST runtimeVisitInt(Runtime runtime, AST node) {
  return node;
}

AST runtimeVisitCompound(Runtime runtime, AST node) {
  var scope = getScope(runtime, node);
  var oldDefList = initDynamicList(0);

  for (int i = 0; i < scope.variableDefinitions.size; i++) {
    var varDef = scope.variableDefinitions.items[i] as AST;
    dynamicListAppend(oldDefList, varDef);
  }

  for (int i = 0; i < node.compoundValue.size; i++) {
    var child = node.compoundValue.items[i] as AST;

    if (child == null) continue;

    var visited = runtimeVisit(runtime, child);
    if (visited != null) {
      if (visited.type == ASTType.AST_RETURN) {
        if (visited.returnValue != null) {
          var retVal = runtimeVisit(runtime, visited.returnValue);

          collectAndSweepGarbage(runtime, oldDefList, scope);
          return retVal;
        } else {
          collectAndSweepGarbage(runtime, oldDefList, scope);
          return null;
        }
      } else if (visited.type == ASTType.AST_BREAK ||
          visited.type == ASTType.AST_CONTINUE) {
        return visited;
      }
    }
  }

  collectAndSweepGarbage(runtime, oldDefList, scope);
  return node;
}

AST runtimeVisitType(Runtime runtime, AST node) {
  return node;
}

AST runtimeVisitAttAccess(Runtime runtime, AST node) {
  if (node.objectChildren != null)
    node.binaryOpLeft.objectChildren = node.objectChildren;

  var left = runtimeVisit(runtime, node.binaryOpLeft);

  if (left.type == ASTType.AST_LIST || left.type == ASTType.AST_STRING) {
    if (node.binaryOpRight.type == ASTType.AST_VARIABLE) {
      if (node.binaryOpRight.variableName == 'length') {
        var intAST = initAST(ASTType.AST_INT);

        if (left.type == ASTType.AST_LIST)
          intAST.intVal = left.listChildren.size;
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
        astList.listChildren = initDynamicList(0);

        for (String binary in binarys)
          dynamicListAppend(astList.listChildren, binary);

        return astList;
      } else if (node.binaryOpRight.variableName == 'toOct') {
        var str = left.stringValue;
        var octS = str.codeUnits.map((e) => e.toRadixString(8));

        var astList = initAST(ASTType.AST_LIST);
        astList.listChildren = initDynamicList(0);

        for (String oct in octS) dynamicListAppend(astList.listChildren, oct);

        return astList;
      } else if (node.binaryOpRight.variableName == 'toHex') {
        var str = left.stringValue;
        var hexS = str.codeUnits.map((e) => e.toRadixString(16));

        var astList = initAST(ASTType.AST_LIST);
        astList.listChildren = initDynamicList(0);

        for (String hex in hexS) dynamicListAppend(astList.listChildren, hex);

        return astList;
      } else if (node.binaryOpRight.variableName == 'toDec') {
        var str = left.stringValue;
        var astList = initAST(ASTType.AST_LIST);
        astList.listChildren = initDynamicList(0);

        var decimals = str.codeUnits;
        for (int decimal in decimals)
          dynamicListAppend(astList.listChildren, decimal);

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
        for (int i = 0; i < left.funcDefinitions.size; i++) {
          var fDef = left.funcDefinitions.items[i] as AST;

          if (fDef.funcName == funcCallName) {
            if (fDef.fptr != null) {
              var visitedFptrArgs = initDynamicList(0);

              for (int j = 0; j < node.binaryOpRight.funcCallArgs.size; j++) {
                var astArg = node.binaryOpRight.funcCallArgs.items[j] as AST;
                var visited = runtimeVisit(runtime, astArg);
                dynamicListAppend(visitedFptrArgs, visited);
              }

              return runtimeVisit(
                  runtime, fDef.fptr(runtime, left, visitedFptrArgs));
            }
          }
        }
      }

      if (left.objectChildren != null) {
        for (int i = 0; i < left.objectChildren.size; i++) {
          var objChild = left.objectChildren.items[i] as AST;

          if (objChild.type == ASTType.AST_FUNC_DEFINITION) if (objChild
                  .funcName ==
              funcCallName)
            return runtimeFuncCall(runtime, node.binaryOpRight, objChild);
        }
      }
    }
  }

  node.scope = getScope(runtime, left);

  var newAST = runtimeVisit(runtime, node.binaryOpRight);

  return runtimeVisit(runtime, newAST);
}

AST runtimeVisitListAccess(Runtime runtime, AST node) {
  var left = runtimeVisit(runtime, node.binaryOpLeft);

  if (left.type == ASTType.AST_LIST)
    return left.listChildren
        .items[runtimeVisit(runtime, node.listAccessPointer).intVal];

  print('List Access left value is not iterable.');
  exit(1);

  // Silence the analyzer
  return null;
}

AST runtimeVisitBinaryOp(Runtime runtime, AST node) {
  AST retVal;
  var left = runtimeVisit(runtime, node.binaryOpLeft);
  var right = node.binaryOpRight;

  if (node.binaryOperator.type == TokenType.TOKEN_DOT) {
    String accessName;

    if (right.type == ASTType.AST_VARIABLE) accessName = right.variableName;

    if (right.type == ASTType.AST_BINARYOP)
      right = runtimeVisit(runtime, right);

    if (left.type == ASTType.AST_OBJECT) {
      for (int i = 0; i < left.objectChildren.size; i++) {
        var child = runtimeVisit(runtime, left.objectChildren.items[i] as AST);

        if (child.type == ASTType.AST_VARIABLE_DEFINITION &&
            child.type == ASTType.AST_VARIABLE_ASSIGNMENT) {
          child.variableValue = runtimeVisit(runtime, right.variableValue);
          return child.variableValue;
        }

        if (child.type == ASTType.AST_VARIABLE_DEFINITION) {
          if (child.variableName == accessName) {
            if (child.variableValue != null)
              return runtimeVisit(runtime, child.variableValue);
            else
              return child;
          }
        } else if (child.type == ASTType.AST_FUNC_DEFINITION) {
          if (child.funcName == accessName) {
            for (int j = 0; j < right.funcCallArgs.size; j++) {
              var astArg = right.funcCallArgs.items[j] as AST;

              if (j > child.funcDefArgs.size - 1) {
                print(
                    'Error: [Line ${astArg.lineNum}] Too many arguments for function `$accessName`');
                break;
              }

              var astFDefArg = child.funcDefArgs.items[j];
              String argName = astFDefArg.variableName;

              var newVarDef = initAST(ASTType.AST_VARIABLE_DEFINITION);
              newVarDef.variableValue = runtimeVisit(runtime, astArg);
              newVarDef.variableName = argName;

              dynamicListAppend(
                  getScope(runtime, child.funcDefBody).variableDefinitions,
                  newVarDef);
            }

            return runtimeVisit(runtime, child.funcDefBody);
          }
        }
      }
    }
  }

  right = runtimeVisit(runtime, right);

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

          retVal.boolValue = left.objectChildren.size == 0;

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

          retVal.boolValue = left.objectChildren.size != 0;

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

AST runtimeVisitUnaryOp(Runtime runtime, AST node) {
  AST right = runtimeVisit(runtime, node.unaryOpRight);

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

AST runtimeVisitNoop(Runtime runtime, AST node) {
  return node;
}

AST runtimeVisitBreak(Runtime runtime, AST node) {
  return node;
}

AST runtimeVisitContinue(Runtime runtime, AST node) {
  return node;
}

AST runtimeVisitReturn(Runtime runtime, AST node) {
  return node;
}

AST runtimeVisitIf(Runtime runtime, AST node) {
  if (node.ifExpression == null) {
    print('Error: [Line ${node.lineNum}] If expression can\'t be empty');
    exit(1);
    return null;
  }

  if (boolEval(runtimeVisit(runtime, node.ifExpression))) {
    runtimeVisit(runtime, node.ifBody);
  } else {
    if (node.ifElse != null) return runtimeVisit(runtime, node.ifElse);

    if (node.elseBody != null) return runtimeVisit(runtime, node.elseBody);
  }

  return node;
}

AST runtimeVisitTernary(Runtime runtime, AST node) {
  return boolEval(runtimeVisit(runtime, node.ternaryExpression))
      ? runtimeVisit(runtime, node.ternaryBody)
      : runtimeVisit(runtime, node.ternaryElseBody);
}

AST runtimeVisitWhile(Runtime runtime, AST node) {
  while (boolEval(runtimeVisit(runtime, node.whileExpression))) {
    var visited = runtimeVisit(runtime, node.whileBody);

    if (visited.type == ASTType.AST_BREAK) break;
    if (visited.type == ASTType.AST_CONTINUE) continue;
  }

  return node;
}

AST runtimeVisitFor(Runtime runtime, AST node) {
  runtimeVisit(runtime, node.forInitStatement);

  while (boolEval(runtimeVisit(runtime, node.forConditionStatement))) {
    var visited = runtimeVisit(runtime, node.forBody);

    if (visited.type == ASTType.AST_BREAK) break;
    if (visited.type == ASTType.AST_CONTINUE) continue;

    runtimeVisit(runtime, node.forChangeStatement);
  }

  return node;
}

AST runtimeVisitNew(Runtime runtime, AST node) {
  return astCopy(runtimeVisit(runtime, node.newValue));
}

AST runtimeVisitIterate(Runtime runtime, AST node) {
  var scope = getScope(runtime, node);
  var astIterable = runtimeVisit(runtime, node.iterateIterable);

  AST fDef;

  if (node.iterateFunction.type == ASTType.AST_FUNC_DEFINITION)
    fDef = node.iterateFunction;

  if (fDef == null) {
    for (int i = 0; i < scope.functionDefinitions.size; i++) {
      fDef = scope.functionDefinitions.items[i] as AST;

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
  var iterableVarName = (fDef.funcDefArgs.items[0] as AST).variableName;

  int i = 0;

  for (int j = fdefBodyScope.variableDefinitions.size - 1; j > 0; j--) {
    dynamicListRemove(fdefBodyScope.variableDefinitions,
        fdefBodyScope.variableDefinitions.items[j], null);
  }

  AST indexVar;

  if (fDef.funcDefArgs.size > 1) {
    indexVar = initAST(ASTType.AST_VARIABLE_DEFINITION);
    indexVar.variableValue = initAST(ASTType.AST_INT);
    indexVar.variableValue.intVal = i;
    indexVar.variableName = (fDef.funcDefArgs.items[0] as AST).variableName;

    dynamicListAppend(fdefBodyScope.variableDefinitions, indexVar);
  }

  if (astIterable.type == ASTType.AST_STRING) {
    var newVarDef = initAST(ASTType.AST_VARIABLE_DEFINITION);
    newVarDef.variableValue = initAST(ASTType.AST_STRING);
    newVarDef.variableValue.stringValue = astIterable.stringValue[i];
    newVarDef.variableName = iterableVarName;

    dynamicListAppend(fdefBodyScope.variableDefinitions, newVarDef);

    for (; i < astIterable.stringValue.length; i++) {
      newVarDef.variableValue.stringValue = astIterable.stringValue[i];

      if (indexVar != null) indexVar.variableValue.intVal = i;

      runtimeVisit(runtime, fDef.funcDefBody);
    }
  } else if (astIterable.type == ASTType.AST_LIST) {
    var newVarDef = initAST(ASTType.AST_VARIABLE_DEFINITION);
    newVarDef.variableValue =
        runtimeVisit(runtime, astIterable.listChildren.items[i]);
    newVarDef.variableName = iterableVarName;

    dynamicListAppend(fdefBodyScope.variableDefinitions, newVarDef);

    for (; i < astIterable.listChildren.size; i++) {
      newVarDef.variableValue =
          runtimeVisit(runtime, (astIterable.listChildren.items[i] as AST));

      if (indexVar != null) indexVar.variableValue.intVal = i;

      runtimeVisit(runtime, fDef.funcDefBody);
    }
  }

  return INITIALIZED_NOOP;
}

AST runtimeVisitAssert(Runtime runtime, AST node) {
  if (!boolEval(runtimeVisit(runtime, node.assertExpression))) {
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

void runtimeExpectArgs(DynamicList inArgs, List<ASTType> args) {
  if (inArgs.size < args.length) {
    print(
        '${inArgs.size} argument(s) were provided, while ${args.length} were expected');
    exit(1);
  }

  for (int i = 0; i < args.length; i++) {
    if (args[i] == ASTType.AST_ANY) continue;

    var ast = inArgs.items[i] as AST;

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
