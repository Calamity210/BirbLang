import 'dart:convert';
import 'dart:io';

import 'package:Birb/utils/exceptions.dart';

import 'AST.dart';
import 'data_type.dart';
import 'scope.dart';
import 'standards.dart';
import 'token.dart';

class Runtime {
  Scope scope;
  List listMethods;
  List mapMethods;
  String stdoutBuffer;
}

Runtime initRuntime() {
  var runtime = Runtime()
    ..scope = initScope(true)
    ..listMethods = []
    ..mapMethods = [];

  INITIALIZED_NOOP = initAST(ASTType.AST_NOOP);

  initStandards(runtime);

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

Scope getScope(Runtime runtime, AST node) {
  return node.scope ?? runtime.scope;
}

void multipleVariableDefinitionsError(int lineNum, String variableName) {
  throw MultipleVariableDefinitionsException(
      '[Line $lineNum] variable `$variableName` is already defined');
}

AST listAddFPtr(Runtime runtime, AST self, List args) {
  self.listElements.addAll(args);

  return self;
}

AST listRemoveFptr(Runtime runtime, AST self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_INT]);

  AST ast_int = args[0];

  if (ast_int.intVal > self.listElements.length) {
    throw RangeException('Index out of range');
  }

  self.listElements.remove(self.listElements[ast_int.intVal]);

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

  if (!self.map.containsKey(astString.stringValue))
    throw MapEntryNotFoundException(
        'Map does not contain `${astString.stringValue}`');

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

      if (oldDef == newDef) exists = true;
    }

    if (!exists) garbage.add(newDef);
  }

  for (int i = 0; i < garbage.length; i++)
    scope.variableDefinitions.remove(garbage[i]);
}

Future<AST> runtimeFuncCall(Runtime runtime, AST fCall, AST fDef) async {
  if (fCall.funcCallArgs.length != fDef.funcDefArgs.length)
    throw InvalidArgumentsException(
        'Error: [Line ${fCall.lineNum}] ${fDef.funcName} Expected ${fDef.funcDefArgs.length} arguments but found ${fCall.funcCallArgs.length} arguments\n');

  var funcDefBodyScope = fDef.funcDefBody.scope;

  for (int i = funcDefBodyScope.variableDefinitions.length - 1; i > 0; i--) {
    funcDefBodyScope.variableDefinitions
        .add(funcDefBodyScope.variableDefinitions[i]);

    funcDefBodyScope.variableDefinitions.length = 0;
  }

  for (int x = 0; x < fCall.funcCallArgs.length; x++) {
    AST astArg = fCall.funcCallArgs[x];

    if (x > fDef.funcDefArgs.length - 1)
      throw InvalidArgumentsException(
          'Error: [Line ${astArg.lineNum}] Too many arguments\n');

    AST astFDefArg = fDef.funcDefArgs[x];
    var argName = astFDefArg.variableName;

    var newVariableDef = initAST(ASTType.AST_VARIABLE_DEFINITION);
    newVariableDef.variableType = astFDefArg.variableType;

    if (astArg.type == ASTType.AST_VARIABLE) {
      var vdef = await getVarDefByName(
          runtime, getScope(runtime, astArg), astArg.variableName);

      if (vdef != null) newVariableDef.variableValue = vdef.variableValue;
    }

    newVariableDef.variableValue ??= await visit(runtime, astArg);
    newVariableDef.variableName = argName;

    funcDefBodyScope.variableDefinitions.add(newVariableDef);
  }

  return await visit(runtime, fDef.funcDefBody);
}

AST registerGlobalFunction(Runtime runtime, String fName, AstFuncPointer fptr) {
  var fDef = initAST(ASTType.AST_FUNC_DEFINITION);
  fDef.funcName = fName;
  fDef.fptr = fptr;
  runtime.scope.functionDefinitions.add(fDef);
  return fDef;
}

AST registerGlobalFutureFunction(
    Runtime runtime, String fName, AstFutureFuncPointer fptr) {
  var fDef = initAST(ASTType.AST_FUNC_DEFINITION)
    ..funcName = fName
    ..futureptr = fptr;
  runtime.scope.functionDefinitions.add(fDef);
  return fDef;
}

AST registerGlobalVariable(Runtime runtime, String vname, String vval) {
  var vdef = initAST(ASTType.AST_VARIABLE_DEFINITION)
    ..variableName = vname
    ..variableType = initAST(ASTType.AST_STRING)
    ..variableValue = initAST(ASTType.AST_STRING)
    ..variableValue.stringValue = vval;
  runtime.scope.variableDefinitions.add(vdef);
  return vdef;
}

AST registerFunction(Scope scope, String fName, AstFuncPointer fptr) {
  AST fDef = initAST(ASTType.AST_FUNC_DEFINITION);
  fDef.funcName = fName;
  fDef.fptr = fptr;
  scope.functionDefinitions.add(fDef);

  return fDef;
}

Future<AST> visit(Runtime runtime, AST node) async {
  if (node == null) {
    return null;
  }

  switch (node.type) {
    case ASTType.AST_CLASS:
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
    case ASTType.AST_STRING_BUFFER:
      return node;
    case ASTType.AST_DOUBLE:
      return node;
    case ASTType.AST_LIST:
      node.funcDefinitions = runtime.listMethods;
      return node;
    case ASTType.AST_MAP:
      node.funcDefinitions = runtime.mapMethods;
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
    case ASTType.AST_SWITCH:
      return await visitSwitch(runtime, node);
    case ASTType.AST_WHILE:
      return await visitWhile(runtime, node);
    case ASTType.AST_FOR:
      return await visitFor(runtime, node);
    case ASTType.AST_ATTRIBUTE_ACCESS:
      return await visitAttAccess(runtime, node);
    case ASTType.AST_LIST_ACCESS:
      return await visitListAccess(runtime, node);
    case ASTType.AST_ITERATE:
      return await visitIterate(runtime, node);
    case ASTType.AST_ASSERT:
      return await visitAssert(runtime, node);
    default:
      throw UncaughtStatementException('Uncaught statement ${node.type}');
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
    case ASTType.AST_MAP:
      return node.map.isNotEmpty;
    case ASTType.AST_LIST:
      return node.listElements.isNotEmpty;
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

  if (node.classChildren != null && node.classChildren.isNotEmpty) {
    for (int i = 0; i < node.classChildren.length; i++) {
      AST objectVarDef = node.classChildren[i];

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
  } else if (node.enumElements != null && node.enumElements.isNotEmpty) {
    for (int i = 0; i < node.enumElements.length; i++) {
      AST variable = node.enumElements[i];

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
      if (varDef.type != ASTType.AST_VARIABLE_DEFINITION) return varDef;

      var value = await visit(runtime, varDef.variableValue);
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

  if (!node.isClassChild && globalScope != null) {
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

  throw UndefinedVariableException(
      'Error: [Line ${node.lineNum}] Undefined variable `${node.variableName}`.');
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

  if (node.classChildren != null && node.classChildren.isNotEmpty) {
    for (int i = 0; i < node.classChildren.length; i++) {
      AST objectVarDef = node.classChildren[i];

      if (objectVarDef.type != ASTType.AST_VARIABLE_DEFINITION) {
        continue;
      }

      if (objectVarDef.variableName == left.variableName) {
        var value = await visit(runtime, node.variableValue);

        if (value.type == ASTType.AST_DOUBLE) {
          value.intVal = value.doubleValue.toInt();
        }
        if (objectVarDef.isFinal)
          throw ReassigningFinalVariableException(
              'Error [Line ${node.lineNum}] Cannot reassign final variable `${node.variableAssignmentLeft.variableName}`');

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
      if (varDef.isFinal)
        throw ReassigningFinalVariableException(
            'Error [Line ${node.lineNum}] Cannot reassign final variable `${node.variableAssignmentLeft.variableName}`');

      varDef.variableValue = value;
      return value;
    }
  }

  if (globalScope != null) {
    var varDef = await getVarDefByName(runtime, globalScope, left.variableName);

    if (varDef != null) {
      //TODO: Change to node variableAssignLeft variableValue if it breaks anything
      var value = await visit(runtime, node.variableValue);

      if (value == null) return null;
      if (value.type == ASTType.AST_DOUBLE) {
        value.intVal = value.doubleValue.toInt();
      }
      if (varDef.isFinal)
        throw ReassigningFinalVariableException(
            'Error [Line ${node.lineNum}] Cannot reassign final variable `${node.variableAssignmentLeft.variableName}`');

      varDef.variableValue = value;

      return value;
    }
  }

  throw SettingUndefinedVariableException(
      "Error: [Line ${left.lineNum}] Can't set undefined variable ${left.variableName}");
}

Future<AST> visitVarMod(Runtime runtime, AST node) async {
  AST value;

  var left = node.binaryOpLeft;
  var varScope = getScope(runtime, node);

  for (int i = 0; i < varScope.variableDefinitions.length; i++) {
    AST astVarDef = varScope.variableDefinitions[i];

    if (node.classChildren != null) {
      for (int i = 0; i < node.classChildren.length; i++) {
        AST objectVarDef = node.classChildren[i];

        if (objectVarDef.type != ASTType.AST_VARIABLE_DEFINITION) continue;

        if (objectVarDef.variableName == left.variableName) {
          astVarDef = objectVarDef;
          break;
        }
      }
    }

    if (left == null) {
      switch (node.binaryOperator.type) {
        case TokenType.TOKEN_PLUS_PLUS:
          {
            AST variable = await visitVariable(runtime, node.binaryOpRight);
            if (variable.type == ASTType.AST_INT)
              return variable..intVal += 1;
            else
              return variable..doubleValue += 1;
          }
          break;

        case TokenType.TOKEN_SUB_SUB:
          {
            AST variable = await visitVariable(runtime, node.binaryOpRight);
            if (variable.type == ASTType.AST_INT)
              return variable..intVal -= 1;
            else
              return variable..doubleValue -= 1;
          }
          break;
        case TokenType.TOKEN_MUL_MUL:
          {
            AST variable = await visitVariable(runtime, node.binaryOpRight);
            if (variable.type == ASTType.AST_INT)
              return variable..intVal *= variable.intVal;
            else
              return variable..doubleValue *= variable.doubleValue;
          }
          break;
        default:
          throw NoLeftValueException(
              'Error: [Line ${node.lineNum}] No left value provided');
      }
    }
    if (astVarDef.variableName == left.variableName) {
      value = await visit(runtime, node.binaryOpRight);

      switch (node.binaryOperator.type) {
        case TokenType.TOKEN_PLUS_PLUS:
          {
            AST variable = await visitVariable(runtime, left);
            if (variable.typeValue.type == DATATYPE.DATA_TYPE_INT) {
              return variable..intVal += 1;
            } else if (variable.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_DOUBLE) {
              return variable..doubleValue += 1;
            }
          }
          break;
        case TokenType.TOKEN_SUB_SUB:
          {
            AST variable = await visitVariable(runtime, left);

            if (variable.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_INT) {
              return variable..intVal -= 1;
            } else if (variable.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_DOUBLE) {
              return variable..doubleValue -= 1;
            }
          }
          break;
        case TokenType.TOKEN_MUL_MUL:
          {
            AST variable = await visitVariable(runtime, left);
            if (variable.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_INT) {
              return variable..intVal *= variable.intVal;
            } else if (variable.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_DOUBLE) {
              return variable..doubleValue *= variable.intVal;
            }
          }
          break;
        case TokenType.TOKEN_PLUS_EQUAL:
          {
            if (astVarDef.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_INT) {
              astVarDef.variableValue.intVal +=
                  value.intVal ?? value.doubleValue.toInt();

              astVarDef.variableValue.doubleValue +=
                  astVarDef.variableValue.intVal;
            } else if (astVarDef.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_DOUBLE) {
              astVarDef.variableValue.doubleValue +=
                  value.doubleValue ?? value.intVal;
              astVarDef.variableValue.intVal +=
                  astVarDef.variableValue.doubleValue.toInt();
            }
            return astVarDef.variableValue;
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
        case TokenType.TOKEN_DIV_EQUAL:
          {
            if (astVarDef.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_DOUBLE) {
              astVarDef.variableValue.doubleValue /=
                  value.doubleValue ?? value.intVal;
              return astVarDef.variableValue;
            }
          }
          break;

        case TokenType.TOKEN_MOD_EQUAL:
          {
            if (astVarDef.variableType.typeValue.type ==
                DATATYPE.DATA_TYPE_DOUBLE) {
              astVarDef.variableValue.intVal %=
                  value.doubleValue ?? value.intVal;
              return astVarDef.variableValue;
            }
          }
          break;

        default:
          throw InvalidOperatorException(
              'Error: [Line ${node.lineNum}] `${node.binaryOperator.value}` is not a valid operator');
      }
    }
  }
  throw SettingUndefinedVariableException(
      "Error: [Line ${node.lineNum}] Can't set undefined variable `${node.variableName}`");
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
    } else if (dataType == DATATYPE.DATA_TYPE_STRING_BUFFER) {
      finalRes.type = ASTType.AST_STRING_BUFFER;
      finalRes.stringBuffer = StringBuffer();
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

  throw UndefinedVariableException(
      'Error: [Line ${node.lineNum}] Undefined method `?`');
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

    AST visited = await visit(runtime, child);
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
  if (node.classChildren != null)
    node.binaryOpLeft.classChildren = node.classChildren;

  if (node.binaryOpRight != null &&
      node.binaryOpLeft.type == ASTType.AST_FUNC_CALL &&
      node.binaryOpRight.type == ASTType.AST_FUNC_CALL) {
    return visit(runtime, node.binaryOpLeft).then((value) async {
      return await visit(runtime, node.binaryOpRight.funcCallArgs[0]);
    });
  } else {
    var left = await visit(runtime, node.binaryOpLeft);

    if (left.type == ASTType.AST_LIST) {
      if (node.binaryOpRight.type == ASTType.AST_VARIABLE) {
        if (node.binaryOpRight.variableName == 'length') {
          var intAST = initAST(ASTType.AST_INT);

          intAST.intVal = left.listElements.length;

          return intAST;
        }
      }
    }
    if (left.type == ASTType.AST_STRING) {
      if (node.binaryOpRight.type == ASTType.AST_VARIABLE) {
        return visitStringProperties(node, left);
      } else if (node.binaryOpRight.type == ASTType.AST_FUNC_CALL) {
        return visitStringMethods(node, left);
      }
    }
    if (left.type == ASTType.AST_STRING_BUFFER) {
      if (node.binaryOpRight.type == ASTType.AST_FUNC_CALL) {
        return visitStrBufMethods(node, left);
      }
    } else if (left.type == ASTType.AST_CLASS) {
      if (node.binaryOpRight.type == ASTType.AST_VARIABLE ||
          node.binaryOpRight.type == ASTType.AST_VARIABLE_ASSIGNMENT ||
          node.binaryOpRight.type == ASTType.AST_VARIABLE_MODIFIER ||
          node.binaryOpRight.type == ASTType.AST_ATTRIBUTE_ACCESS) {
        node.binaryOpRight.classChildren = left.classChildren;
        node.binaryOpRight.scope = left.scope;
        node.binaryOpRight.isClassChild = true;
        node.classChildren = left.classChildren;
        node.scope = left.scope;
      } else if (node.binaryOpRight.type == ASTType.AST_LIST_ACCESS) {
        node.binaryOpRight.binaryOpLeft.classChildren = left.classChildren;
        node.binaryOpRight.binaryOpLeft.scope = left.scope;
        node.binaryOpRight.binaryOpLeft.isClassChild = true;
        node.binaryOpRight.classChildren = left.classChildren;
        node.binaryOpRight.scope = left.scope;
      }
    } else if (left.type == ASTType.AST_ENUM) {
      if (node.binaryOpRight.type == ASTType.AST_VARIABLE) {
        node.binaryOpRight.enumElements = left.enumElements;
        node.binaryOpRight.scope = left.scope;
        node.enumElements = left.enumElements;
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

                for (int j = 0;
                    j < node.binaryOpRight.funcCallArgs.length;
                    j++) {
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

        if (left.classChildren != null) {
          for (int i = 0; i < left.classChildren.length; i++) {
            AST objChild = left.classChildren[i];

            if (objChild.type == ASTType.AST_FUNC_DEFINITION) if (objChild
                    .funcName ==
                funcCallName)
              return await runtimeFuncCall(
                  runtime, node.binaryOpRight, objChild);
          }
        }
      }
    }

    node.scope = getScope(runtime, left);

    var newAST = await visit(runtime, node.binaryOpRight);

    return await visit(runtime, newAST);
  }
}

Future<AST> visitListAccess(Runtime runtime, AST node) async {
  var left = await visit(runtime, node.binaryOpLeft);
  AST ast = await visit(runtime, node.listAccessPointer);

  if (ast.type == ASTType.AST_STRING) {
    var key = ast.stringValue;
    if (left.type != ASTType.AST_MAP)
      throw UnexpectedTypeException(
          'Error: [Line ${node.lineNum}] Expected a Map');

    if (left.map.containsKey(key)) {
      if (left.map[key] is String) {
        AST mapValAST = initAST(ASTType.AST_STRING)
          ..stringValue = left.map[key];
        return mapValAST;
      }
      return left.map[key];
    } else
      return null;
  } else {
    var index = ast.intVal;
    if (left.type == ASTType.AST_LIST) if (left.listElements.isNotEmpty &&
        index < left.listElements.length) {
      if (left.listElements[index] is Map) {
        var type = initDataTypeAs(DATATYPE.DATA_TYPE_MAP);
        AST mapAst = initAST(ASTType.AST_MAP)
          ..typeValue = type
          ..scope = left.scope
          ..map = left.listElements[index];

        return mapAst;
      } else if (left.listElements[index] is String) {
        var type = initDataTypeAs(DATATYPE.DATA_TYPE_STRING);
        AST stringAst = initAST(ASTType.AST_STRING)
          ..typeValue = type
          ..scope = left.scope
          ..stringValue = left.listElements[index];

        return stringAst;
      }
      return left.listElements[index];
    } else {
      throw RangeException(
          'Error: Invalid list index: Valid range is: ${left.listElements.isNotEmpty ? left.listElements.length - 1 : 0}');
    }

    throw UnexpectedTypeException('List Access left value is not iterable.');
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

    if (left.type == ASTType.AST_CLASS) {
      for (int i = 0; i < left.classChildren.length; i++) {
        var child = await visit(runtime, left.classChildren[i] as AST);

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

              AST astFDefArg = child.funcDefArgs[j];
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
        if (left.type == ASTType.AST_CLASS && right.type == ASTType.AST_CLASS) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.classChildren == right.classChildren;

          return retVal;
        }

        if (left.type == ASTType.AST_CLASS && right.type == ASTType.AST_NULL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.classChildren.isEmpty;

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
        if (left.type == ASTType.AST_CLASS && right.type == ASTType.AST_CLASS) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.classChildren != right.classChildren;

          return retVal;
        }

        if (left.type == ASTType.AST_CLASS && right.type == ASTType.AST_NULL) {
          retVal = initAST(ASTType.AST_BOOL);

          retVal.boolValue = left.classChildren.isNotEmpty;

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
      throw InvalidOperatorException(
          'Error: [Line ${node.lineNum}] `${node.binaryOperator.value}` is not a valid operator');
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

    case TokenType.TOKEN_PLUS_PLUS:
      {
        AST variable = await visitVariable(runtime, node.unaryOpRight);
        if (variable.type == ASTType.AST_INT)
          return variable..intVal += 1;
        else
          return variable..doubleValue += 1;
      }
      break;

    case TokenType.TOKEN_SUB_SUB:
      {
        AST variable = await visitVariable(runtime, node.unaryOpRight);
        if (variable.type == ASTType.AST_INT)
          return variable..intVal -= 1;
        else
          return variable..doubleValue -= 1;
      }
      break;
    case TokenType.TOKEN_MUL_MUL:
      {
        AST variable = await visitVariable(runtime, node.unaryOpRight);
        if (variable.type == ASTType.AST_INT)
          return variable..intVal *= variable.intVal;
        else
          return variable..doubleValue *= variable.doubleValue;
      }
      break;
    case TokenType.TOKEN_NOT:
      {
        AST boolAST = initAST(ASTType.AST_BOOL);
        switch (node.unaryOpRight.type) {
          case ASTType.AST_VARIABLE:
            {
              boolAST.boolValue =
                  !boolEval(await visitVariable(runtime, node.unaryOpRight));
              return boolAST;
            }
            break;
          default:
            boolAST.boolValue = !boolEval(node.unaryOpRight);
            break;
        }
        break;
      }
      break;

    default:
      throw InvalidOperatorException(
          'Error: [Line ${node.lineNum}] `${node.unaryOperator.value}` is not a valid operator');
  }

  return returnValue;
}

Future<AST> visitIf(Runtime runtime, AST node) async {
  if (node.ifExpression == null)
    throw UnexpectedTypeException(
        'Error: [Line ${node.lineNum}] If expression can\'t be empty');

  if (node.ifExpression.type == ASTType.AST_UNARYOP) {
    if (boolEval(await visit(runtime, node.ifExpression.unaryOpRight)) ==
        false) {
      await visit(runtime, node.ifBody);
    } else {
      if (node.ifElse != null) return await visit(runtime, node.ifElse);

      if (node.elseBody != null) return await visit(runtime, node.elseBody);
    }
  } else {
    if (boolEval(await visit(runtime, node.ifExpression))) {
      await visit(runtime, node.ifBody);
    } else {
      if (node.ifElse != null) return await visit(runtime, node.ifElse);

      if (node.elseBody != null) return await visit(runtime, node.elseBody);
    }
  }
  return node;
}

Future<AST> visitSwitch(Runtime runtime, AST node) async {
  if (node.switchExpression == null)
    throw UnexpectedTypeException(
        'Error: [Line ${node.lineNum}] If expression can\'t be empty');

  AST caseAST = await visit(runtime, node.switchExpression);

  switch (caseAST.type) {
    case ASTType.AST_STRING:
      Iterable<AST> testCase = node.switchCases.keys
          .where((element) => element.stringValue == caseAST.stringValue);

      if (testCase != null && testCase.isNotEmpty) {
        return await visit(runtime, node.switchCases[testCase.first]);
      }
      return await visit(runtime, node.switchDefault);
    case ASTType.AST_INT:
      Iterable<AST> testCase = node.switchCases.keys
          .where((element) => element.intVal == caseAST.intVal);

      if (testCase != null && testCase.isNotEmpty) {
        return await visit(runtime, node.switchCases[testCase.first]);
      }
      return await visit(runtime, node.switchDefault);
    case ASTType.AST_DOUBLE:
      Iterable<AST> testCase = node.switchCases.keys
          .where((element) => element.doubleValue == caseAST.doubleValue);

      if (testCase != null && testCase.isNotEmpty) {
        return await visit(runtime, node.switchCases[testCase.first]);
      }
      return await visit(runtime, node.switchDefault);
    case ASTType.AST_MAP:
      Iterable<AST> testCase =
          node.switchCases.keys.where((element) => element.map == caseAST.map);

      if (testCase != null && testCase.isNotEmpty) {
        return await visit(runtime, node.switchCases[testCase.first]);
      }
      return await visit(runtime, node.switchDefault);
    case ASTType.AST_LIST:
      Iterable<AST> testCase = node.switchCases.keys
          .where((element) => element.listElements == caseAST.listElements);

      if (testCase != null && testCase.isNotEmpty) {
        return await visit(runtime, node.switchCases[testCase.first]);
      }
      return await visit(runtime, node.switchDefault);
    default:
      return await visit(runtime, node.switchDefault);
  }
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

Future<AST> visitIterate(Runtime runtime, AST node) async {
  var scope = getScope(runtime, node);
  AST astIterable = await visit(runtime, node.iterateIterable);

  AST fDef;

  if (node.iterateFunction.type == ASTType.AST_FUNC_DEFINITION)
    fDef = node.iterateFunction;

  if (fDef == null) {
    for (int i = 0; i < scope.functionDefinitions.length; i++) {
      fDef = scope.functionDefinitions[i];

      if (fDef.funcName == node.iterateFunction.variableName) {
        if (fDef.fptr != null)
          throw UnexpectedTypeException(
              'Error: Can not iterate with native method');
        break;
      }
    }
  }

  var fDefBodyScope = fDef.funcDefBody.scope;
  var iterableVarName = (fDef.funcDefArgs[0] as AST).variableName;

  int i = 0;

  for (int j = fDefBodyScope.variableDefinitions.length - 1; j > 0; j--) {
    fDefBodyScope.variableDefinitions
        .remove(fDefBodyScope.variableDefinitions[j]);
  }

  AST indexVar;

  if (fDef.funcDefArgs.length > 1) {
    indexVar = initAST(ASTType.AST_VARIABLE_DEFINITION);
    indexVar.variableValue = initAST(ASTType.AST_INT);
    indexVar.variableValue.intVal = i;
    indexVar.variableName = (fDef.funcDefArgs[0] as AST).variableName;

    fDefBodyScope.variableDefinitions.add(indexVar);
  }

  if (astIterable.type == ASTType.AST_STRING) {
    var newVarDef = initAST(ASTType.AST_VARIABLE_DEFINITION);
    newVarDef.variableValue = initAST(ASTType.AST_STRING);
    newVarDef.variableValue.stringValue = astIterable.stringValue[i];
    newVarDef.variableName = iterableVarName;

    fDefBodyScope.variableDefinitions.add(newVarDef);

    for (; i < astIterable.stringValue.length; i++) {
      newVarDef.variableValue.stringValue = astIterable.stringValue[i];

      if (indexVar != null) indexVar.variableValue.intVal = i;

      await visit(runtime, fDef.funcDefBody);
    }
  } else if (astIterable.type == ASTType.AST_LIST) {
    var newVarDef = initAST(ASTType.AST_VARIABLE_DEFINITION);
    newVarDef.variableValue = await visit(runtime, astIterable.listElements[i]);
    newVarDef.variableName = iterableVarName;

    fDefBodyScope.variableDefinitions.add(newVarDef);

    for (; i < astIterable.listElements.length; i++) {
      newVarDef.variableValue =
          await visit(runtime, (astIterable.listElements[i] as AST));

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

    throw AssertionException('Assert failed');
  }

  return INITIALIZED_NOOP;
}

void runtimeExpectArgs(List inArgs, List<ASTType> args) {
  if (inArgs.length < args.length)
    throw InvalidArgumentsException(
        '${inArgs.length} argument(s) were provided, while ${args.length} were expected');

  for (int i = 0; i < args.length; i++) {
    if (args[i] == ASTType.AST_ANY) continue;

    AST ast = inArgs[i];

    if (ast.type != args[i]) {
      print('Received argument of type ${ast.type}, but expected ${args[i]}');
      throw InvalidArgumentsException('Got unexpected arguments, terminating');
    }
  }
}

AST visitStringProperties(AST node, AST left) {
  switch (node.binaryOpRight.variableName) {
    case 'codeUnits':
      {
        String str = left.stringValue;
        AST astList = initAST(ASTType.AST_LIST);
        astList.listElements = str.codeUnits;

        return astList;
      }
      break;

    case 'isEmpty':
      {
        String str = left.stringValue;
        AST astList = initAST(ASTType.AST_BOOL);
        astList.boolValue = str.isEmpty;

        return astList;
      }
      break;

    case 'isNotEmpty':
      {
        String str = left.stringValue;
        AST astList = initAST(ASTType.AST_BOOL);
        astList.boolValue = str.isNotEmpty;

        return astList;
      }
      break;
    case 'input':
      {
        String str = left.stringValue;
        print(str);
        AST astString = initAST(ASTType.AST_STRING);
        astString.stringValue =
            stdin.readLineSync(encoding: Encoding.getByName('utf-8')).trim();

        return astString;
      }
      break;
    case 'length':
      {
        var intAST = initAST(ASTType.AST_INT);

        intAST.intVal = left.stringValue.length;

        return intAST;
      }
      break;
    case 'toBinary':
      {
        String str = left.stringValue;
        var binarys = str.codeUnits.map((e) => e.toRadixString(2));

        AST astList = initAST(ASTType.AST_LIST);
        astList.listElements = [];

        for (String binary in binarys) astList.listElements.add(binary);

        return astList;
      }
      break;
    case 'toOct':
      {
        String str = left.stringValue;
        var octS = str.codeUnits.map((e) => e.toRadixString(8));

        AST astList = initAST(ASTType.AST_LIST);
        astList.listElements = [];

        for (String oct in octS) astList.listElements.add(oct);

        return astList;
      }
      break;
    case 'toHex':
      {
        String str = left.stringValue;
        var hexS = str.codeUnits.map((e) => e.toRadixString(16));

        AST astList = initAST(ASTType.AST_LIST);
        astList.listElements = [];

        for (String hex in hexS) astList.listElements.add(hex);

        return astList;
      }
      break;
    case 'toDec':
      {
        String str = left.stringValue;
        AST astList = initAST(ASTType.AST_LIST);
        astList.listElements = [];

        var decimals = str.codeUnits;
        for (int decimal in decimals) astList.listElements.add(decimal);

        return astList;
      }
      break;

    default:
      throw NoSuchPropertyException(node.binaryOpRight.variableName, 'String');
  }
}

AST visitStringMethods(AST node, AST left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'codeUnitAt':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);

        AST index = node.binaryOpRight.funcCallArgs[0];

        String str = left.stringValue;
        AST ast = initAST(ASTType.AST_INT);
        ast.intVal = str.codeUnitAt(index.intVal);

        return ast;
      }
      break;
    case 'compareTo':
      {
        runtimeExpectArgs(
            node.binaryOpRight.funcCallArgs, [ASTType.AST_STRING]);

        AST other = node.binaryOpRight.funcCallArgs[0];

        String str = left.stringValue;
        AST ast = initAST(ASTType.AST_INT);
        ast.intVal = str.compareTo(other.stringValue);

        return ast;
      }

    case 'contains':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_STRING, ASTType.AST_INT]);

        AST pattern = node.binaryOpRight.funcCallArgs[0];
        AST index = node.binaryOpRight.funcCallArgs[1];

        String str = left.stringValue;
        AST ast = initAST(ASTType.AST_BOOL);
        ast.boolValue = str.contains(pattern.stringValue, index.intVal);

        return ast;
      }

    case 'endsWith':
      {
        runtimeExpectArgs(
            node.binaryOpRight.funcCallArgs, [ASTType.AST_STRING]);

        AST pattern = node.binaryOpRight.funcCallArgs[0];

        String str = left.stringValue;
        AST ast = initAST(ASTType.AST_BOOL);
        ast.boolValue = str.endsWith(pattern.stringValue);

        return ast;
      }

    case 'indexOf':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_STRING, ASTType.AST_INT]);

        AST pattern = node.binaryOpRight.funcCallArgs[0];
        AST index = node.binaryOpRight.funcCallArgs[1];

        String str = left.stringValue;
        AST ast = initAST(ASTType.AST_INT);
        ast.intVal = str.indexOf(pattern.stringValue, index.intVal);

        return ast;
      }
    case 'lastIndexOf':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_STRING, ASTType.AST_INT]);

        AST pattern = node.binaryOpRight.funcCallArgs[0];
        AST index = node.binaryOpRight.funcCallArgs[1];

        String str = left.stringValue;
        AST ast = initAST(ASTType.AST_INT);
        ast.intVal = str.lastIndexOf(pattern.stringValue, index.intVal);

        return ast;
      }

    case 'padLeft':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_STRING]);

        AST width = node.binaryOpRight.funcCallArgs[0];
        AST padding = node.binaryOpRight.funcCallArgs[1];

        left.stringValue =
            left.stringValue.padLeft(width.intVal, padding.stringValue);

        return left;
      }
    case 'padRight':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_STRING]);

        AST width = node.binaryOpRight.funcCallArgs[0];
        AST padding = node.binaryOpRight.funcCallArgs[1];

        left.stringValue =
            left.stringValue.padRight(width.intVal, padding.stringValue);

        return left;
      }
    case 'replaceAll':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_STRING, ASTType.AST_STRING]);

        AST pattern = node.binaryOpRight.funcCallArgs[0];
        AST replace = node.binaryOpRight.funcCallArgs[1];

        left.stringValue = left.stringValue
            .replaceAll(pattern.stringValue, replace.stringValue);

        return left;
      }
    case 'replaceFirst':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_STRING, ASTType.AST_STRING, ASTType.AST_INT]);

        AST pattern = node.binaryOpRight.funcCallArgs[0];
        AST replace = node.binaryOpRight.funcCallArgs[1];
        AST index = node.binaryOpRight.funcCallArgs[2];

        left.stringValue = left.stringValue.replaceFirst(
            pattern.stringValue, replace.stringValue, index.intVal);

        return left;
      }
    case 'replaceRange':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_INT, ASTType.AST_STRING]);

        AST start = node.binaryOpRight.funcCallArgs[0];
        AST end = node.binaryOpRight.funcCallArgs[1];
        AST replace = node.binaryOpRight.funcCallArgs[2];

        left.stringValue
            .replaceRange(start.intVal, end.intVal, replace.stringValue);

        return left;
      }

    case 'split':
      {
        runtimeExpectArgs(
            node.binaryOpRight.funcCallArgs, [ASTType.AST_STRING]);

        AST pattern = node.binaryOpRight.funcCallArgs[0];

        String str = left.stringValue;
        AST ast = initAST(ASTType.AST_LIST);
        ast.listElements = str.split(pattern.stringValue);

        return ast;
      }

    case 'startsWith':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_STRING, ASTType.AST_INT]);

        AST pattern = node.binaryOpRight.funcCallArgs[0];
        AST index = node.binaryOpRight.funcCallArgs[1];

        String str = left.stringValue;
        AST ast = initAST(ASTType.AST_BOOL);
        ast.boolValue = str.startsWith(pattern.stringValue, index.intVal);

        return ast;
      }

    case 'substring':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_INT]);

        AST start = node.binaryOpRight.funcCallArgs[0];
        AST end = node.binaryOpRight.funcCallArgs[1];

        String str = left.stringValue;
        AST ast = initAST(ASTType.AST_STRING);
        ast.stringValue = str.substring(start.intVal, end.intVal);

        return ast;
      }

    case 'toLowerCase':
      {
        left.stringValue = left.stringValue.toLowerCase();

        return left;
      }

    case 'toUpperCase':
      {
        left.stringValue = left.stringValue.toUpperCase();

        return left;
      }

    case 'trim':
      {
        left.stringValue = left.stringValue.trim();

        return left;
      }

    case 'trimLeft':
      {
        left.stringValue = left.stringValue.trimLeft();
        return left;
      }

    case 'trimRight':
      {
        left.stringValue = left.stringValue.trimRight();
        return left;
      }

    default:
      throw NoSuchPropertyException(node.binaryOpRight.variableName, 'String');
  }
}

AST visitStrBufMethods(AST node, AST left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'toString':
      AST strAST = initAST(ASTType.AST_STRING)
        ..stringValue = left.stringBuffer.toString();
      return strAST;

    case 'clear':
      left.stringBuffer.clear();
      return left;

    case 'write':
      runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_STRING]);

      left.stringBuffer
          .write((node.binaryOpRight.funcCallArgs[0] as AST).stringValue);
      return left;

    case 'writeAll':
      runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_LIST]);

      (node.binaryOpRight.funcCallArgs[0] as AST).listElements.forEach((e) {
        left.stringBuffer.write((e as AST).stringValue);
      });
      return left;

    case 'writeAsciiCode':
      runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
      left.stringBuffer.writeCharCode((node.binaryOpRight.funcCallArgs[0] as AST).intVal);
      return left;
      
    case 'writeLine':
      runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_STRING]);
      left.stringBuffer
          .write('${(node.binaryOpRight.funcCallArgs[0] as AST).stringValue}\n');
  }
  throw NoSuchPropertyException(
      node.binaryOpRight.funcCallExpression.variableName, 'StrBuffer');
}
