import 'dart:io';

import 'package:Birb/core_types.dart';
import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';
import 'package:Birb/utils/scope.dart';
import 'package:Birb/parser/data_type.dart';
import 'package:Birb/runtime/standards.dart';
import 'package:Birb/lexer/token.dart';

class Runtime {

  Runtime(this.path) {
    INITIALIZED_NOOP = NoopNode();
    initStandards(this, path);

    final LIST_ADD_FUNCTION_DEFINITION = FuncDefNode();
    LIST_ADD_FUNCTION_DEFINITION.funcName = 'add';
    LIST_ADD_FUNCTION_DEFINITION.funcPointer = listAddFuncPointer;
    listMethods.add(LIST_ADD_FUNCTION_DEFINITION);

    final LIST_REMOVE_FUNCTION_DEFINITION = FuncDefNode();
    LIST_REMOVE_FUNCTION_DEFINITION.funcName = 'remove';
    LIST_REMOVE_FUNCTION_DEFINITION.funcPointer = listRemoveFuncPointer;
    listMethods.add(LIST_REMOVE_FUNCTION_DEFINITION);

    final MAP_ADD_FUNCTION_DEFINITION = FuncDefNode();
    MAP_ADD_FUNCTION_DEFINITION.funcName = 'add';
    MAP_ADD_FUNCTION_DEFINITION.funcPointer = mapAddFuncPointer;
    mapMethods.add(MAP_ADD_FUNCTION_DEFINITION);

    final MAP_REMOVE_FUNCTION_DEFINITION = FuncDefNode();
    MAP_REMOVE_FUNCTION_DEFINITION.funcName = 'remove';
    MAP_REMOVE_FUNCTION_DEFINITION.funcPointer = mapAddFuncPointer;
    mapMethods.add(MAP_REMOVE_FUNCTION_DEFINITION);
  }

  Scope scope = Scope(true);
  List listMethods = [];
  List mapMethods = [];
  String stdoutBuffer;
  String path;

  List<Map> stack = [];


  Scope getScope(ASTNode node) {
    return node.scope ?? scope;
  }

  void multipleVariableDefinitionsError(int lineNum, String variableName) {
    throw MultipleVariableDefinitionsException('[Line $lineNum] variable `$variableName` is already defined');
  }

  ASTNode listAddFuncPointer(Runtime runtime, ASTNode self, List args) {
    self.listElements.addAll(args);

    return self;
  }

  ASTNode listRemoveFuncPointer(Runtime runtime, ASTNode self, List args) {
    expectArgs(args, [IntNode]);

    final ASTNode ast_int = args[0];

    if (ast_int.intVal > self.listElements.length) {
      throw const RangeException('Index out of range');
    }

    self.listElements.remove(self.listElements[ast_int.intVal]);

    return self;
  }

  ASTNode mapAddFuncPointer(Runtime runtime, ASTNode self, List args) {
    expectArgs(args, [StringNode, AnyNode]);

    self.map[args[0]] = args[1];
    return self;
  }

  ASTNode mapRemoveFuncPointer(ASTNode self, List args) {
    expectArgs(args, [StringNode]);

    final ASTNode astString = args[0];

    if (!self.map.containsKey(astString.stringValue))
      throw MapEntryNotFoundException('Map does not contain `${astString.stringValue}`');

    self.map.remove(astString.stringValue);
    return self;
  }

  void collectAndSweepGarbage(List oldDefList, Scope scope) {
    if (scope == scope)
      return;

    scope.variableDefinitions.where((newDef) => !oldDefList.contains(newDef))
        .forEach((garb) => scope.variableDefinitions.remove(garb));
  }

  Future<ASTNode> runtimeFunctionCall(ASTNode fCall, ASTNode fDef) async {
    if (fCall.functionCallArgs.length != fDef.functionDefArgs.length ||
        fCall.namedFunctionCallArgs.length > fDef.namedFunctionDefArgs.length)
      throw InvalidArgumentsException(
          'Error: [Line ${fCall.lineNum}] ${fDef.funcName} Expected ${fDef.functionDefArgs.length} arguments but found ${fCall.functionCallArgs.length} arguments\n');

    final funcDefBodyScope = fDef.functionDefBody.scope;

    for (int i = 0; i < fCall.functionCallArgs.length; i++) {
      final ASTNode astArg = fCall.functionCallArgs[i];

      final ASTNode astFDefArg = fDef.functionDefArgs[i];
      final argName = astFDefArg.variableName;

      final newVariableDef = VarDefNode();
      newVariableDef.variableType = astFDefArg.variableType;

      if (astArg.type == ASTType.AST_VARIABLE) {
        final vDef = await getVarDefByName(getScope(astArg), astArg.variableName);

        if (vDef != null)
          newVariableDef.variableValue = vDef.variableValue;
      }

      newVariableDef.variableValue ??= await visit(astArg);
      newVariableDef.variableName = argName;

      final DATATYPE varDefValType = newVariableDef.variableType.typeValue.type;

      if (varDefValType != DATATYPE.DATA_TYPE_VAR &&
          !varDefValType
              .toString()
              .endsWith(newVariableDef.variableValue.type.toString().replaceFirst('ASTType.AST_', ''))) {
        throw UnexpectedTypeException('[Line ${fCall.lineNum}] Invalid type');
      }

      funcDefBodyScope.variableDefinitions.addFirst(newVariableDef);
    }

    fDef.namedFunctionDefArgs.forEach((e) {
      funcDefBodyScope.variableDefinitions.addFirst(e..variableValue = NoSeebNode());
    });

    for (int i = 0; i < fCall.namedFunctionCallArgs.length; i++) {
      final ASTNode astArg = fCall.namedFunctionCallArgs[i];
      final ASTNode astFDefArg = fDef.namedFunctionDefArgs.firstWhere((e) => e.variableName == astArg.variableName,
          orElse: () {
            throw InvalidArgumentsException('No defined parameter `${astArg.variableName}` for `${fDef.funcName}` was found');
          });

      final String argName = astFDefArg.variableName;

      final VarDefNode newVariableDef = VarDefNode()..variableType = astFDefArg.variableType;

      if (astArg.variableValue.type == ASTType.AST_VARIABLE) {
        final vDef = await getVarDefByName(getScope(astArg.variableValue), astArg.variableValue.variableName);

        if (vDef != null)
          newVariableDef.variableValue = vDef.variableValue;
      }

      newVariableDef.variableValue ??= await visit(astArg.variableValue);
      newVariableDef.variableName = argName;

      final DATATYPE varDefValType = newVariableDef.variableType.typeValue.type;

      if (varDefValType != DATATYPE.DATA_TYPE_VAR &&
          !varDefValType
              .toString()
              .endsWith(newVariableDef.variableValue.type.toString().replaceFirst('ASTType.AST_', ''))) {
        throw UnexpectedTypeException('[Line ${fCall.lineNum}] Invalid type');
      }

      funcDefBodyScope.variableDefinitions.addFirst(newVariableDef);
    }

    return await visit(fDef.functionDefBody);
  }

  ASTNode registerGlobalFunction(String fName, AstFuncPointer funcPointer) {
    final fDef = FuncDefNode();
    fDef.funcName = fName;
    fDef.funcPointer = funcPointer;
    scope.functionDefinitions.addFirst(fDef);
    return fDef;
  }

  ASTNode registerLocalFunction(String fName, AstFuncPointer funcPointer, Scope scope) {
    final fDef = FuncDefNode()
      ..funcName = fName
      ..funcPointer = funcPointer;
    scope.functionDefinitions.addFirst(fDef);
    return fDef;
  }

  ASTNode registerGlobalFutureFunction(String fName, AstFutureFuncPointer funcPointer) {
    final fDef = FuncDefNode()
      ..funcName = fName
      ..futureFuncPointer = funcPointer;
    scope.functionDefinitions.addFirst(fDef);
    return fDef;
  }

  ASTNode registerGlobalVariable(String varName, ASTNode varVal) {
    final ASTNode varDef = VarDefNode()
      ..variableName = varName
      ..variableType = StringNode()
      ..variableValue = varVal;
    scope.variableDefinitions.addFirst(varDef);
    return varDef;
  }

  Future<ASTNode> visit(ASTNode node) async {
    if (node == null)
      return null;

    switch (node.type) {
      case ASTType.AST_CLASS:
        stack.add({'line': node.lineNum, 'function': node.className});

        if (node.superClass != null) {
          final ClassNode superClass = await visit(node.superClass);
          final List nullVars = node.classChildren
              .where((child) => child is VarDefNode && child.variableValue == null && child.isSuperseding)
              .toList();

          nullVars.forEach((child) {
            final ASTNode superVariable = superClass.classChildren
                .firstWhere((superChild) => superChild.variableName == (child as ASTNode).variableName);
            (child as ASTNode).variableValue = superVariable.variableValue;
          });
        }
        return node;
      case ASTType.AST_ENUM:
        return node;
      case ASTType.AST_VARIABLE:
        return await visitVariable(node);
      case ASTType.AST_VARIABLE_DEFINITION:
        return await visitVarDef(node);
      case ASTType.AST_VARIABLE_ASSIGNMENT:
        return await visitVarAssignment(node);
      case ASTType.AST_VARIABLE_MODIFIER:
        return await visitVarMod(node);
      case ASTType.AST_FUNC_DEFINITION:
        return await visitFuncDef(node);
      case ASTType.AST_FUNC_CALL:
        return await visitFuncCall(node);
      case ASTType.AST_NULL:
        return node;
      case ASTType.AST_STRING:
        return node;
      case ASTType.AST_STRING_BUFFER:
        return node;
      case ASTType.AST_DOUBLE:
        return node;
      case ASTType.AST_LIST:
        node.funcDefinitions = listMethods;
        return node;
      case ASTType.AST_MAP:
        node.funcDefinitions = mapMethods;
        return node;
      case ASTType.AST_BOOL:
        return node;
      case ASTType.AST_INT:
        return node;
      case ASTType.AST_COMPOUND:
        return await visitCompound(node);
      case ASTType.AST_TYPE:
        return node;
      case ASTType.AST_BINARYOP:
        return await visitBinaryOp(node);
      case ASTType.AST_UNARYOP:
        return await visitUnaryOp(node);
      case ASTType.AST_NOOP:
        return node;
      case ASTType.AST_BREAK:
        return node;
      case ASTType.AST_RETURN:
        return node;
      case ASTType.AST_THROW:
        final ClassNode throwArg = await visit(node.throwValue);

        String classToString = '';

        throwArg.classChildren.whereType<VarDefNode>().forEach((varDef) {
          classToString += '\t${varDef.variableName}: ${varDef.variableValue.toString()}\n';
        });

        stderr.write('${throwArg.className}:\n$classToString');
        exit(1);

        return INITIALIZED_NOOP;
      case ASTType.AST_NEXT:
        return node;
      case ASTType.AST_TERNARY:
        return await visitTernary(node);
      case ASTType.AST_IF:
        return await visitIf(node);
      case ASTType.AST_SWITCH:
        return await visitSwitch(node);
      case ASTType.AST_WHILE:
        return await visitWhile(node);
      case ASTType.AST_FOR:
        return await visitFor(node);
      case ASTType.AST_NEW:
        return await visitNew(node);
      case ASTType.AST_ATTRIBUTE_ACCESS:
        return await visitAttAccess(node);
      case ASTType.AST_LIST_ACCESS:
        return await visitListAccess(node);
      case ASTType.AST_ITERATE:
        return await visitIterate(node);
      case ASTType.AST_ASSERT:
        return await visitAssert(node);
      case ASTType.AST_ANY:
        return node;
      default:
        throw UncaughtStatementException('Uncaught statement ${node.type}');
    }
  }

  bool boolEval(ASTNode node) {
    switch (node.runtimeType) {
      case IntNode:
        return node.intVal != null;
      case DoubleNode:
        return node.doubleVal != null;
      case BoolNode:
        return node.boolVal;
      case StringNode:
        return node.stringValue != null;
      case MapNode:
        return node.map != null;
      case ListNode:
        return node.listElements != null;
      default:
        return false;
    }
  }

  Future<ASTNode> getVarDefByName(Scope scope, String varName) async {
    if (scope.owner != null) {
      if (varName == 'nest') {
        return scope.owner.parent ?? scope.owner;
      }
    }

    return scope.variableDefinitions.firstWhere((e) => e.variableName == varName, orElse: () => null);
  }

  Future<ASTNode> visitVariable(ASTNode node) async {
    final localScope = node.scope;
    final globalScope = scope;

    if (node.classChildren != null && node.classChildren.isNotEmpty) {
      for (int i = 0; i < node.classChildren.length; i++) {
        final ASTNode objectVarDef = node.classChildren.elementAt(i);

        if (objectVarDef.type != ASTType.AST_VARIABLE_DEFINITION) {
          continue;
        }

        if (objectVarDef.variableName == node.variableName) {
          if (objectVarDef.variableValue == null) {
            return objectVarDef;
          }

          final value = await visit(objectVarDef.variableValue);
          value.typeValue = objectVarDef.variableType.typeValue;

          return value;
        }
      }
    } else if (node.enumElements != null && node.enumElements.isNotEmpty) {
      for (int i = 0; i < node.enumElements.length; i++) {
        final ASTNode variable = node.enumElements[i];

        if (variable.variableName == node.variableName) {
          if (variable.ast != null) {
            return variable.ast;
          } else {
            final listAST = ListNode()..listElements = [i, variable.variableName];
            variable.ast = listAST;

            return variable.ast;
          }
        }
      }
    }

    if (localScope != null) {
      final varDef = await getVarDefByName(localScope, node.variableName);

      if (varDef != null) {
        if (varDef.type != ASTType.AST_VARIABLE_DEFINITION)
          return varDef;

        final value = await visit(varDef.variableValue);
        value.typeValue = varDef.variableType.typeValue;

        return value;
      }

      for (int i = 0; i < localScope.functionDefinitions.length; i++) {
        final ASTNode funcDef = localScope.functionDefinitions.elementAt(i);

        if (funcDef.funcName == node.variableName) {
          return funcDef;
        }
      }
    }

    if (!node.isClassChild && globalScope != null) {
      final varDef = await getVarDefByName(globalScope, node.variableName);

      if (varDef != null) {
        if (varDef.type != ASTType.AST_VARIABLE_DEFINITION) {
          return varDef;
        }

        final value = await visit(varDef.variableValue);
        value.typeValue = varDef.variableType.typeValue;

        return value;
      }

      for (int i = 0; i < globalScope.functionDefinitions.length; i++) {
        final ASTNode funcDef = globalScope.functionDefinitions.elementAt(i);

        if (funcDef.funcName == node.variableName) {
          return funcDef;
        }
      }
    }

    String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

    stack.reversed
        .take(5)
        .forEach((Map item) => stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n');

    throw UndefinedVariableException(
        'Error: [Line ${node.lineNum}] Undefined variable `${node.variableName}`.$stacktrace');
  }

  Future<ASTNode> visitVarDef(ASTNode node) async {
    if (node.savedFuncCall != null) {
      node.variableValue = await visit(node.savedFuncCall);
    } else {
      if (node.variableValue != null) {
        if (node.variableValue.type == ASTType.AST_FUNC_CALL) {
          node.savedFuncCall = node.variableValue;
        }

        node.variableValue = await visit(node.variableValue);
      } else {
        node.variableValue = NoSeebNode();
      }
    }
    getScope(node).variableDefinitions.addFirst(node);

    return node.variableValue ?? node;
  }

  Future<ASTNode> visitVarAssignment(VarAssignmentNode node) async {
    final left = node.variableAssignmentLeft;

    final localScope = node.scope;
    final globalScope = scope;

    if (node.classChildren != null && node.classChildren.isNotEmpty) {
      for (int i = 0; i < node.classChildren.length; i++) {
        final ASTNode objectVarDef = node.classChildren.elementAt(i);

        if (objectVarDef.type != ASTType.AST_VARIABLE_DEFINITION) {
          continue;
        }

        if (objectVarDef.variableName == left.variableName) {
          final value = await visit(node.variableValue);

          if (value.type == ASTType.AST_DOUBLE) {
            value.intVal = value.doubleVal.toInt();
          }
          if (objectVarDef.isFinal ?? false) {
            String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

            for (final Map item in stack.reversed.take(5))
              stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

            throw ReassigningFinalVariableException(
                'Error [Line ${node.lineNum}] Cannot reassign final variable `${node.variableAssignmentLeft.variableName}`$stacktrace');
          }

          if (!objectVarDef.isNullable && node.variableValue == null || node.variableValue is NoSeebNode) {
            String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

            for (final Map item in stack.reversed.take(5))
              stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

            throw UnexpectedTypeException(
                'Error [Line ${node.lineNum}]: Non-nullable variables cannot be given a null value, add the `?` suffix to a variable type to make it nullable\n$stacktrace');
          }

          objectVarDef.variableValue = value;

          return value;
        }
      }
    }

    if (localScope != null) {
      final varDef = await getVarDefByName(localScope, left.variableName);

      if (varDef != null) {
        final value = await visit(node.variableValue);
        if (value.type == ASTType.AST_DOUBLE) {
          value.intVal = value.doubleVal.toInt();
        }
        if (varDef.isFinal) {
          String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

          for (final Map item in stack.reversed.take(5))
            stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

          throw ReassigningFinalVariableException(
              'Error [Line ${node.lineNum}] Cannot reassign final variable `${node.variableAssignmentLeft.variableName}`$stacktrace');
        }

        varDef.variableValue = value;
        return value;
      }
    }

    if (globalScope != null) {
      final varDef = await getVarDefByName(globalScope, left.variableName);

      if (varDef != null) {
        final value = await visit(node.variableValue);

        if (value == null)
          return null;
        if (value.type == ASTType.AST_DOUBLE) {
          value.intVal = value.doubleVal.toInt();
        }
        if (varDef.isFinal) {
          String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

          for (final Map item in stack.reversed.take(5))
            stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';
          throw ReassigningFinalVariableException(
              'Error [Line ${node.lineNum}] Cannot reassign final variable `${node.variableAssignmentLeft.variableName}`$stacktrace');
        }

        varDef.variableValue = value;

        return value;
      }
    }
    String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

    for (final Map item in stack.reversed.take(5))
      stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

    throw AssigningUndefinedVariableException(
        "Error: [Line ${left.lineNum}] Can't set undefined variable ${left.variableName}$stacktrace");
  }

  Future<ASTNode> visitVarMod(ASTNode node) async {
    ASTNode value;

    final left = node.binaryOpLeft;
    final varScope = getScope(node);

    for (int i = 0; i < varScope.variableDefinitions.length; i++) {
      ASTNode astVarDef = varScope.variableDefinitions.elementAt(i);

      if (node.classChildren != null) {
        for (int i = 0; i < node.classChildren.length; i++) {
          final ASTNode objectVarDef = node.classChildren.elementAt(i);

          if (objectVarDef.type != ASTType.AST_VARIABLE_DEFINITION)
            continue;

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
              final ASTNode variable = await visitVariable(node.binaryOpRight);
              if (variable.type == ASTType.AST_INT)
                return variable..intVal += 1;
              else
                return variable..doubleVal += 1;
            }
            break;

          case TokenType.TOKEN_SUB_SUB:
            {
              final ASTNode variable = await visitVariable(node.binaryOpRight);
              if (variable.type == ASTType.AST_INT)
                return variable..intVal -= 1;
              else
                return variable..doubleVal -= 1;
            }
            break;
          case TokenType.TOKEN_MUL_MUL:
            {
              final ASTNode variable = await visitVariable(node.binaryOpRight);
              if (variable.type == ASTType.AST_INT)
                return variable..intVal *= variable.intVal;
              else
                return variable..doubleVal *= variable.doubleVal;
            }
            break;
          default:
            String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

            for (final Map item in stack.reversed.take(5))
              stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

            throw NoLeftValueException('Error: [Line ${node.lineNum}] No left value provided$stacktrace');
        }
      }
      if (astVarDef.variableName == left.variableName) {
        value = await visit(node.binaryOpRight);

        switch (node.binaryOperator.type) {
          case TokenType.TOKEN_PLUS_PLUS:
            {
              final ASTNode variable = await visitVariable(left);
              if (variable.typeValue.type == DATATYPE.DATA_TYPE_INT) {
                final IntNode newVariable = variable.copy();
                variable.intVal++;
                return newVariable;
              } else if (variable.typeValue.type == DATATYPE.DATA_TYPE_DOUBLE) {
                final DoubleNode newVariable = variable.copy();
                variable.doubleVal++;
                return newVariable;
              }
            }
            break;
          case TokenType.TOKEN_SUB_SUB:
            {
              final ASTNode variable = await visitVariable(left);

              if (variable.variableType.typeValue.type == DATATYPE.DATA_TYPE_INT) {
                final IntNode newVariable = variable.copy();
                variable.intVal--;
                return newVariable;
              } else if (variable.variableType.typeValue.type == DATATYPE.DATA_TYPE_DOUBLE) {
                final DoubleNode newVariable = variable.copy();
                variable.doubleVal--;
                return newVariable;
              }
            }
            break;
          case TokenType.TOKEN_MUL_MUL:
            {
              final ASTNode variable = await visitVariable(left);
              if (variable.variableType.typeValue.type == DATATYPE.DATA_TYPE_INT) {
                return variable..intVal *= variable.intVal;
              } else if (variable.variableType.typeValue.type == DATATYPE.DATA_TYPE_DOUBLE) {
                return variable..doubleVal *= variable.intVal;
              }
            }
            break;
          case TokenType.TOKEN_PLUS_EQUAL:
            {
              if (astVarDef.variableType.typeValue.type == DATATYPE.DATA_TYPE_INT) {
                astVarDef.variableValue.intVal += value.intVal ?? value.doubleVal.toInt();
              } else if (astVarDef.variableType.typeValue.type == DATATYPE.DATA_TYPE_DOUBLE) {
                astVarDef.variableValue.doubleVal += value.doubleVal ?? value.intVal;
              } else if (astVarDef.variableType.typeValue.type == DATATYPE.DATA_TYPE_STRING) {
                astVarDef.variableValue.stringValue += value.stringValue;
              }
              return astVarDef.variableValue;
            }
            break;

          case TokenType.TOKEN_NOSEEB_ASSIGNMENT:
            {
              if (astVarDef.variableValue is NoSeebNode) {
                return astVarDef.variableValue = value;
              }

              return astVarDef.variableValue;
            }
            break;

          case TokenType.TOKEN_SUB_EQUAL:
            {
              if (astVarDef.variableType.typeValue.type == DATATYPE.DATA_TYPE_INT) {
                astVarDef.variableValue.intVal -= value.intVal ?? value.doubleVal.toInt();
                astVarDef.variableValue.doubleVal -= astVarDef.variableValue.intVal;
                return astVarDef.variableValue;
              } else if (astVarDef.variableType.typeValue.type == DATATYPE.DATA_TYPE_DOUBLE) {
                astVarDef.variableValue.doubleVal -= value.doubleVal ?? value.intVal;
                astVarDef.variableValue.intVal -= astVarDef.variableValue.doubleVal.toInt();
                return astVarDef.variableValue;
              }
            }
            break;

          case TokenType.TOKEN_MUL_EQUAL:
            {
              if (astVarDef.variableType.typeValue.type == DATATYPE.DATA_TYPE_INT) {
                astVarDef.variableValue.intVal *= value.intVal ?? value.doubleVal.toInt();
                astVarDef.variableValue.doubleVal *= astVarDef.variableValue.intVal;
                return astVarDef.variableValue;
              } else if (astVarDef.variableType.typeValue.type == DATATYPE.DATA_TYPE_DOUBLE) {
                astVarDef.variableValue.doubleVal *= value.doubleVal ?? value.intVal;
                astVarDef.variableValue.intVal *= astVarDef.variableValue.doubleVal.toInt();
                return astVarDef.variableValue;
              }
            }
            break;
          case TokenType.TOKEN_DIV_EQUAL:
            {
              if (astVarDef.variableType.typeValue.type == DATATYPE.DATA_TYPE_DOUBLE) {
                astVarDef.variableValue.doubleVal /= value.doubleVal ?? value.intVal;
                return astVarDef.variableValue;
              }
            }
            break;

          case TokenType.TOKEN_MOD_EQUAL:
            {
              if (astVarDef.variableType.typeValue.type == DATATYPE.DATA_TYPE_DOUBLE) {
                astVarDef.variableValue.intVal %= value.doubleVal ?? value.intVal;
                return astVarDef.variableValue;
              }
            }
            break;

          default:
            String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

            for (final Map item in stack.reversed.take(5))
              stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

            throw InvalidOperatorException(
                'Error: [Line ${node.lineNum}] `${node.binaryOperator.value}` is not a valid operator$stacktrace');
        }
      }
    }
    String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

    for (final Map item in stack.reversed.take(5))
      stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

    throw AssigningUndefinedVariableException(
        "Error: [Line ${node.lineNum}] Can't set undefined variable `${node.variableName}`$stacktrace");
  }

  Future<ASTNode> visitFuncDef(ASTNode node) async {
    final scope = getScope(node);
    scope.functionDefinitions.addFirst(node);

    return node;
  }

  Future<ASTNode> runtimeFuncLookup(Scope scope, ASTNode node) async {
    ASTNode funcDef;

    final ASTNode visitedExpr = await visit(node.funcCallExpression);

    if (visitedExpr.type == ASTType.AST_FUNC_DEFINITION)
      funcDef = visitedExpr;

    if (funcDef == null)
      return null;

    if (funcDef.futureFuncPointer != null) {
      final List<ASTNode> visitedFuncPointerArgs = [];

      for (int i = 0; i < node.functionCallArgs.length; i++) {
        final ASTNode astArg = node.functionCallArgs[i];
        ASTNode visited;

        if (astArg.type == ASTType.AST_VARIABLE) {
          final vDef = await getVarDefByName(getScope(astArg), astArg.variableName);

          if (vDef != null)
            visited = vDef.variableValue;
        }

        visited = visited ?? await visit(astArg);
        visitedFuncPointerArgs.add(visited);
      }

      final ret = await visit(await funcDef.futureFuncPointer(this, funcDef, visitedFuncPointerArgs));

      return ret;
    }

    if (funcDef.funcPointer != null) {
      final List<ASTNode> visitedFuncPointerArgs = [];

      for (int i = 0; i < node.functionCallArgs.length; i++) {
        final ASTNode astArg = node.functionCallArgs[i];
        ASTNode visited;

        if (astArg.type == ASTType.AST_VARIABLE) {
          final vDef = await getVarDefByName(getScope(astArg), astArg.variableName);

          if (vDef != null)
            visited = vDef.variableValue;
        }

        visited = visited ?? await visit(astArg);
        visitedFuncPointerArgs.add(visited);
      }

      final ret = await visit(funcDef.funcPointer(this, funcDef, visitedFuncPointerArgs));

      return ret;
    }

    if (funcDef.functionDefBody != null)
      return await runtimeFunctionCall(node, funcDef);
    else if (funcDef.compChildren != null) {
      ASTNode finalRes;
      final dataType = funcDef.funcDefType.typeValue.type;

      if (dataType == DATATYPE.DATA_TYPE_INT) {
        finalRes = IntNode();
      } else if (dataType == DATATYPE.DATA_TYPE_DOUBLE) {
        finalRes = DoubleNode();
      } else if (dataType == DATATYPE.DATA_TYPE_STRING) {
        finalRes = StringNode();
      } else if (dataType == DATATYPE.DATA_TYPE_STRING_BUFFER) {
        finalRes = StrBufferNode();
      }

      final List<ASTNode> callArgs = [];
      callArgs.add(finalRes);

      for (int i = 0; i < funcDef.compChildren.length; i++) {
        final ASTNode compChild = funcDef.compChildren[i];

        ASTNode res;

        if (compChild.type == ASTType.AST_FUNC_DEFINITION) {
          if (i == 0)
            node.functionCallArgs = node.functionCallArgs;
          else
            node.functionCallArgs = callArgs;

          res = await runtimeFunctionCall(node, compChild);
        } else {
          final fCall = FuncCallNode();
          fCall.funcCallExpression = compChild;

          if (i == 0)
            fCall.functionCallArgs = node.functionCallArgs;
          else
            fCall.functionCallArgs = callArgs;

          res = await runtimeFuncLookup(scope, fCall);
        }

        switch (res.type) {
          case ASTType.AST_INT:
            finalRes.intVal = res.intVal;
            break;
          case ASTType.AST_DOUBLE:
            finalRes.doubleVal = res.doubleVal;
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

  Future<ASTNode> visitFuncCall(ASTNode node) async {
    stack.add({'line': node.lineNum, 'function': node.funcCallExpression.variableName});

    if (node.scope != null) {
      final localScopeFuncDef = await runtimeFuncLookup(node.scope, node);

      if (localScopeFuncDef != null)
        return localScopeFuncDef;
    }

    final globalScopeFuncDef = await runtimeFuncLookup(scope, node);
    if (globalScopeFuncDef != null)
      return globalScopeFuncDef;

    String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

    for (final Map item in stack.reversed.take(5))
      stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

    throw UndefinedVariableException('Error: [Line ${node.lineNum}] Undefined method `?`$stacktrace');
  }

  Future<ASTNode> visitCompound(ASTNode node) async {
    final scope = getScope(node);
    final List<ASTNode> oldDefList = [];

    for (int i = 0; i < scope.variableDefinitions.length; i++) {
      final ASTNode varDef = scope.variableDefinitions.elementAt(i);
      oldDefList.add(varDef);
    }

    for (int i = 0; i < node.compoundValue.length; i++) {
      final ASTNode child = node.compoundValue[i];

      if (child == null)
        continue;

      final ASTNode visited = await visit(child);
      if (visited != null) {
        if (visited.type == ASTType.AST_RETURN) {
          if (visited.returnValue != null) {
            collectAndSweepGarbage(oldDefList, scope);
            return await visit(visited.returnValue);
          }

          collectAndSweepGarbage(oldDefList, scope);
          return null;
        } else if (visited.type == ASTType.AST_BREAK || visited.type == ASTType.AST_NEXT) {
          return visited;
        }
      }
    }

    collectAndSweepGarbage(oldDefList, scope);
    return node;
  }

  Future<ASTNode> visitAttAccess(ASTNode node) async {
    if (node.classChildren != null && node.classChildren.isNotEmpty)
      node.binaryOpLeft.classChildren = node.classChildren;

    if (node.binaryOpRight != null &&
        node.binaryOpLeft.type == ASTType.AST_FUNC_CALL &&
        node.binaryOpRight.type == ASTType.AST_FUNC_CALL) {
      return visit(node.binaryOpLeft).then((value) async {
        return await visit(node.binaryOpRight.functionCallArgs[0]);
      });
    } else {
      final left = await visit(node.binaryOpLeft);

      switch (left.type) {
        case ASTType.AST_LIST:
          if (node.binaryOpRight.type == ASTType.AST_VARIABLE)
            return visitListProperties(node, left);
          else if (node.binaryOpRight.type == ASTType.AST_FUNC_CALL)
            return visitListMethods(node, left);
          break;
        case ASTType.AST_STRING:
          if (node.binaryOpRight.type == ASTType.AST_VARIABLE)
            return visitStringProperties(node, left);
          else if (node.binaryOpRight.type == ASTType.AST_FUNC_CALL)
            return visitStringMethods(node, left);
          break;
        case ASTType.AST_STRING_BUFFER:
          if (node.binaryOpRight.type == ASTType.AST_VARIABLE)
            return visitStrBufferProperties(node, left);
          else if (node.binaryOpRight.type == ASTType.AST_FUNC_CALL)
            return visitStrBufferMethods(node, left);
          break;
        case ASTType.AST_INT:
          if (node.binaryOpRight.type == ASTType.AST_VARIABLE)
            return visitIntProperties(node, left);
          else if (node.binaryOpRight.type == ASTType.AST_FUNC_CALL)
            return visitIntMethods(node, left);
          break;
        case ASTType.AST_DOUBLE:
          if (node.binaryOpRight.type == ASTType.AST_VARIABLE)
            return visitDoubleProperties(node, left);
          else if (node.binaryOpRight.type == ASTType.AST_FUNC_CALL)
            return visitDoubleMethods(node, left);
          break;
        case ASTType.AST_MAP:
          if (node.binaryOpRight.type == ASTType.AST_VARIABLE)
            return visitMapProperties(node, left);
          else if (node.binaryOpRight.type == ASTType.AST_FUNC_CALL)
            return visitMapMethods(node, left);
          break;
        case ASTType.AST_BOOL:
          if (node.binaryOpRight.type == ASTType.AST_VARIABLE)
            return visitBoolProperties(node, left);
          else if (node.binaryOpRight.type == ASTType.AST_FUNC_CALL)
            return visitBoolMethods(node, left);
          break;
        case ASTType.AST_CLASS:
          final ASTNode binOpRight = node.binaryOpRight;
          if (binOpRight.type == ASTType.AST_VARIABLE ||
              binOpRight.type == ASTType.AST_VARIABLE_ASSIGNMENT ||
              binOpRight.type == ASTType.AST_VARIABLE_MODIFIER ||
              binOpRight.type == ASTType.AST_ATTRIBUTE_ACCESS) {
            final ASTNode classPropertyNode = visitClassProperties(node, left);

            if (classPropertyNode != null)
              return classPropertyNode;

            binOpRight.classChildren = left.classChildren;
            binOpRight.scope = left.scope;
            binOpRight.isClassChild = true;
            node.classChildren = left.classChildren;
            node.scope = left.scope;
          }
          break;
        case ASTType.AST_LIST_ACCESS:
          node.binaryOpRight.binaryOpLeft.classChildren = left.classChildren;
          node.binaryOpRight.binaryOpLeft.scope = left.scope;
          node.binaryOpRight.binaryOpLeft.isClassChild = true;
          node.binaryOpRight.classChildren = left.classChildren;
          node.binaryOpRight.scope = left.scope;
          break;
        case ASTType.AST_ENUM:
          if (node.binaryOpRight.type == ASTType.AST_VARIABLE) {
            node.binaryOpRight.enumElements = left.enumElements;
            node.binaryOpRight.scope = left.scope;
            node.enumElements = left.enumElements;
            node.scope = left.scope;
          }
          break;
        default:
          String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

          for (final Map item in stack.reversed.take(5))
            stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

          throw UnexpectedTokenException(
              'Error [Line ${node.lineNum}]: Cannot access attribute for Type `${node.type.toString()}`$stacktrace');
          break;
      }

      if (node.binaryOpRight.type == ASTType.AST_FUNC_CALL) {
        if (node.binaryOpRight.funcCallExpression.type == ASTType.AST_VARIABLE) {
          final funcCallName = node.binaryOpRight.funcCallExpression.variableName;

          if (left is! ClassNode && left.funcDefinitions != null) {
            for (int i = 0; i < left.funcDefinitions.length; i++) {
              final ASTNode fDef = left.funcDefinitions[i];

              if (fDef.funcName == funcCallName) {
                if (fDef.funcPointer != null) {
                  final List<ASTNode> visitedFuncPointerArgs = [];

                  for (int j = 0; j < node.binaryOpRight.functionCallArgs.length; j++) {
                    final ASTNode astArg = node.binaryOpRight.functionCallArgs[j];
                    final visited = await visit(astArg);
                    visitedFuncPointerArgs.add(visited);
                  }

                  return await visit(fDef.funcPointer(this, left, visitedFuncPointerArgs));
                }
              }
            }
          }

          if (left.classChildren != null) {
            for (int i = 0; i < left.classChildren.length; i++) {
              final ASTNode objChild = left.classChildren.elementAt(i);

              if (objChild.type == ASTType.AST_FUNC_DEFINITION)
                if (objChild.funcName == funcCallName) {
                  if (objChild.funcPointer != null) {
                    final List<ASTNode> visitedFuncPointerArgs = [];

                    for (int j = 0; j < node.binaryOpRight.functionCallArgs.length; j++) {
                      final ASTNode astArg = node.binaryOpRight.functionCallArgs[j];
                      final visited = await visit(astArg);
                      visitedFuncPointerArgs.add(visited);
                    }

                    return await visit(objChild.funcPointer(this, left, visitedFuncPointerArgs));
                  }

                  return await runtimeFunctionCall(node.binaryOpRight, objChild);
                }
            }
          }
        }
      }

      node.scope = getScope(left);

      final ASTNode newAST = await visit(node.binaryOpRight);

      return await visit(newAST);
    }
  }

  Future<ASTNode> visitListAccess(ASTNode node) async {
    final left = await visit(node.binaryOpLeft);
    final ASTNode ast = await visit(node.listAccessPointer);

    if (ast.type == ASTType.AST_STRING) {
      final key = ast.stringValue;
      if (left.type != ASTType.AST_MAP) {
        String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

        for (final Map item in stack.reversed.take(5))
          stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

        throw UnexpectedTypeException('Error: [Line ${node.lineNum}] Expected a Map$stacktrace');
      }

      if (left.map.containsKey(key)) {
        if (left.map[key] is String) {
          final ASTNode mapValAST = StringNode()..stringValue = left.map[key];
          return mapValAST;
        }
        return left.map[key];
      } else
        return null;
    } else {
      final index = ast.intVal;
      if (left.type == ASTType.AST_LIST) {
        if (left.listElements.isNotEmpty && index < left.listElements.length) {
          if (left.listElements[index] is Map) {
            final type = DataType.as(DATATYPE.DATA_TYPE_MAP);
            final ASTNode mapAst = MapNode()
              ..typeValue = type
              ..scope = left.scope
              ..map = left.listElements[index];

            return mapAst;
          } else if (left.listElements[index] is String) {
            final type = DataType.as(DATATYPE.DATA_TYPE_STRING);
            final ASTNode stringAst = StringNode()
              ..typeValue = type
              ..scope = left.scope
              ..stringValue = left.listElements[index];

            return stringAst;
          }
          return left.listElements[index];
        } else {
          String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

          for (final Map item in stack.reversed.take(5))
            stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

          throw RangeException(
              'Error: Invalid list index: Valid range is: ${left.listElements.isNotEmpty ? left.listElements.length - 1 : 0}$stacktrace');
        }
      }

      if (left.type == ASTType.AST_MAP) {
        if (index >= left.map.keys.length) {
          String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

          for (final Map item in stack.reversed.take(5))
            stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

          throw RangeException(
              'Error: Invalid map index: Valid range is: ${left.map.keys.isNotEmpty ? left.map.keys.length - 1 : 0}$stacktrace');
        }
        return left.map[left.map.keys.toList()[index]];
      }

      String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

      for (final Map item in stack.reversed.take(5))
        stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

      throw UnexpectedTypeException('List Access left value is not iterable.$stacktrace');
    }
  }

  Future<ASTNode> visitBinaryOp(ASTNode node) async {
    ASTNode retVal;
    final left = await visit(node.binaryOpLeft);
    var right = node.binaryOpRight;

    if (node.binaryOperator.type == TokenType.TOKEN_DOT) {
      String accessName;

      if (right.type == ASTType.AST_VARIABLE)
        accessName = right.variableName;

      if (right.type == ASTType.AST_BINARYOP)
        right = await visit(right);

      if (left.type == ASTType.AST_CLASS) {
        for (int i = 0; i < left.classChildren.length; i++) {
          final child = await visit(left.classChildren.elementAt(i));

          if (child.type == ASTType.AST_VARIABLE_DEFINITION && child.type == ASTType.AST_VARIABLE_ASSIGNMENT) {
            child.variableValue = await visit(right.variableValue);
            return child.variableValue;
          }

          if (child.type == ASTType.AST_VARIABLE_DEFINITION) {
            if (child.variableName == accessName) {
              if (child.variableValue != null)
                return await visit(child.variableValue);
              else
                return child;
            }
          } else if (child.type == ASTType.AST_FUNC_DEFINITION) {
            if (child.funcName == accessName) {
              for (int j = 0; j < right.functionCallArgs.length; j++) {
                final ASTNode astArg = right.functionCallArgs[j];

                if (j > child.functionDefArgs.length - 1) {
                  print('Error: [Line ${astArg.lineNum}] Too many arguments for function `$accessName`');
                  break;
                }

                final ASTNode astFDefArg = child.functionDefArgs[j];
                final String argName = astFDefArg.variableName;

                final newVarDef = VarDefNode();
                newVarDef.variableValue = await visit(astArg);
                newVarDef.variableName = argName;

                getScope(child.functionDefBody).variableDefinitions.addFirst(newVarDef);
              }

              return await visit(child.functionDefBody);
            }
          }
        }
      }
    }

    right = await visit(right);

    switch (node.binaryOperator.type) {
      case TokenType.TOKEN_PLUS:
        {
          if (left.type == ASTType.AST_INT && right.type == ASTType.AST_INT) {
            retVal = IntNode();

            retVal.intVal = left.intVal + right.intVal;

            return retVal;
          }
          if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_DOUBLE) {
            retVal = DoubleNode();

            retVal.doubleVal = left.doubleVal + right.doubleVal;

            return retVal;
          }
          if (left.type == ASTType.AST_INT && right.type == ASTType.AST_DOUBLE) {
            retVal = DoubleNode();

            retVal.doubleVal = left.intVal + right.doubleVal;

            return retVal;
          }
          if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_INT) {
            retVal = DoubleNode();

            retVal.doubleVal = left.doubleVal + right.intVal;

            return retVal;
          }
          if (left.type == ASTType.AST_STRING && right.type == ASTType.AST_STRING) {
            retVal = StringNode();

            retVal.stringValue = left.stringValue + right.stringValue;

            return retVal;
          }

          if (left.type == ASTType.AST_STRING && right.type == ASTType.AST_INT) {
            retVal = StringNode();

            retVal.stringValue = left.stringValue + right.intVal.toString();

            return retVal;
          }
          if (left.type == ASTType.AST_INT && right.type == ASTType.AST_STRING) {
            retVal = StringNode();

            retVal.stringValue = left.intVal.toString() + right.stringValue;

            return retVal;
          }
          if (left.type == ASTType.AST_STRING && right.type == ASTType.AST_DOUBLE) {
            retVal = StringNode();

            retVal.stringValue = left.stringValue + right.doubleVal.toString();

            return retVal;
          }
          if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_STRING) {
            retVal = StringNode();

            retVal.stringValue = left.doubleVal.toString() + right.stringValue;

            return retVal;
          }
        }

        break;

      case TokenType.TOKEN_SUB:
        {
          if (left is IntNode && right is IntNode) {
            retVal = IntNode();

            retVal.intVal = left.intVal - right.intVal;

            return retVal;
          }
          if (left is DoubleNode && right is DoubleNode) {
            retVal = DoubleNode();

            retVal.doubleVal = left.doubleVal - right.doubleVal;

            return retVal;
          }
          if (left is IntNode && right is DoubleNode) {
            retVal = DoubleNode();

            retVal.doubleVal = left.intVal - right.doubleVal;

            return retVal;
          }
          if (left is DoubleNode && right is IntNode) {
            retVal = DoubleNode();

            retVal.doubleVal = left.doubleVal - right.intVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_MUL:
        {
          if (left is IntNode && right is IntNode) {
            retVal = IntNode();

            retVal.intVal = left.intVal * right.intVal;

            return retVal;
          }
          if (left is DoubleNode && right is DoubleNode) {
            retVal = DoubleNode();

            retVal.doubleVal = left.doubleVal * right.doubleVal;

            return retVal;
          }
          if (left is IntNode && right is DoubleNode) {
            retVal = DoubleNode();

            retVal.doubleVal = left.intVal * right.doubleVal;

            return retVal;
          }
          if (left is DoubleNode && right is IntNode) {
            retVal = DoubleNode();

            retVal.doubleVal = left.doubleVal * right.intVal;

            return retVal;
          }

          if (left is StringNode && right is IntNode) {
            retVal = StringNode();

            retVal.stringValue = left.stringValue * right.intVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_DIV:
        {
          if (left is IntNode && right is IntNode) {
            retVal = DoubleNode();

            retVal.doubleVal = left.intVal / right.intVal;

            return retVal;
          }
          if (left is DoubleNode && right is DoubleNode) {
            retVal = DoubleNode();

            retVal.doubleVal = left.doubleVal / right.doubleVal;

            return retVal;
          }
          if (left is IntNode && right is DoubleNode) {
            retVal = DoubleNode();

            retVal.doubleVal = left.intVal / right.doubleVal;

            return retVal;
          }
          if (left is DoubleNode && right is IntNode) {
            retVal = DoubleNode();

            retVal.doubleVal = left.doubleVal / right.intVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_AND:
        {
          if (left is BoolNode && right is BoolNode) {
            retVal = BoolNode();

            retVal.boolVal = left.boolVal && right.boolVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_OR:
        {
          if (left is BoolNode && right is BoolNode) {
            retVal = BoolNode();

            retVal.boolVal = left.boolVal || right.boolVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_LESS_THAN:
        {
          if (left is IntNode && right is IntNode) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal < right.intVal;

            return retVal;
          }
          if (left is DoubleNode && right is DoubleNode) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal < right.doubleVal;

            return retVal;
          }
          if (left is IntNode && right is DoubleNode) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal < right.doubleVal;

            return retVal;
          }
          if (left is DoubleNode && right is IntNode) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal < right.intVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_GREATER_THAN:
        {
          if (left is IntNode && right is IntNode) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal > right.intVal;

            return retVal;
          }
          if (left is DoubleNode && right is DoubleNode) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal > right.doubleVal;

            return retVal;
          }
          if (left is IntNode && right is DoubleNode) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal > right.doubleVal;

            return retVal;
          }
          if (left is DoubleNode && right is IntNode) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal > right.intVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_LESS_THAN_EQUAL:
        {
          if (left is IntNode && right is IntNode) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal <= right.intVal;

            return retVal;
          }
          if (left is DoubleNode && right is DoubleNode) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal <= right.doubleVal;

            return retVal;
          }
          if (left is IntNode && right is DoubleNode) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal <= right.doubleVal;

            return retVal;
          }
          if (left is DoubleNode && right is IntNode) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal <= right.intVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_GREATER_THAN_EQUAL:
        {
          if (left is IntNode && right is IntNode) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal >= right.intVal;

            return retVal;
          }
          if (left is DoubleNode && right is DoubleNode) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal >= right.doubleVal;

            return retVal;
          }
          if (left is IntNode && right is DoubleNode) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal >= right.doubleVal;

            return retVal;
          }
          if (left is DoubleNode && right is IntNode) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal >= right.intVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_BITWISE_AND:
        {
          if (left is IntNode && right is IntNode) {
            retVal = IntNode()..intVal = left.intVal & right.intVal;

            return retVal;
          }
        }
        break;

      case TokenType.NOSEEB_AWARE_OPERATOR:
        if (left is NoSeebNode) {
          return right;
        }

        return left;

      case TokenType.TOKEN_BITWISE_OR:
        {
          if (left is IntNode && right is IntNode) {
            retVal = IntNode()..intVal = left.intVal | right.intVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_BITWISE_XOR:
        {
          if (left is IntNode && right is IntNode) {
            retVal = IntNode()..intVal = left.intVal ^ right.intVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_LSHIFT:
        {
          if (left is IntNode && right is IntNode) {
            retVal = IntNode()..intVal = left.intVal << right.intVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_RSHIFT:
        {
          if (left is IntNode && right is IntNode) {
            retVal = IntNode()..intVal = left.intVal >> right.intVal;

            return retVal;
          }
        }
        break;

      case TokenType.TOKEN_EQUALITY:
        {
          if (left is BoolNode && right is BoolNode) {
            retVal = BoolNode()..boolVal = left.boolVal == right.boolVal;

            return retVal;
          }

          if (left is BoolNode && right is IntNode) {
            retVal = BoolNode();

            if (right.intVal != 1 && right.intVal != 0) {
              String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

              for (final Map item in stack.reversed.take(5))
                stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

              throw UnexpectedTokenException('Only integer literals `0` and `1` can be compared with a bool$stacktrace');
            }

            retVal.boolVal = left.boolVal == (right.intVal == 1);

            return retVal;
          }

          if (left is BoolNode && right is NoSeebNode) {
            retVal = BoolNode();

            retVal.boolVal = left.boolVal == null;

            return retVal;
          }

          if (left is IntNode && right is BoolNode) {
            if (left.intVal != 1 && left.intVal != 0) {
              String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

              for (final Map item in stack.reversed.take(5))
                stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

              throw UnexpectedTokenException('Only integer literals `0` and `1` can be compared with a bool$stacktrace');
            }

            retVal = BoolNode();

            retVal.boolVal = (left.intVal == 1) == right.boolVal;

            return retVal;
          }

          if (left is IntNode && right is IntNode) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal == right.intVal;

            return retVal;
          }
          if (left is DoubleNode && right is DoubleNode) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal == right.doubleVal;

            return retVal;
          }
          if (left is IntNode && right is DoubleNode) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal == right.doubleVal;

            return retVal;
          }
          if (left is IntNode && right is NoSeebNode) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal == 0 || left.intVal == null;

            return retVal;
          }
          if (left is DoubleNode && right is IntNode) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal == right.intVal;

            return retVal;
          }
          if (left is DoubleNode && right is NoSeebNode) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal == 0 || left.doubleVal == null;

            return retVal;
          }
          if (left is StringNode && right is StringNode) {
            retVal = BoolNode();

            retVal.boolVal = left.stringValue == right.stringValue;

            return retVal;
          }

          if (left is StringNode && right is NoSeebNode) {
            retVal = BoolNode();

            retVal.boolVal = left.stringValue == null;

            return retVal;
          }

          if (left is ClassNode && right is ClassNode) {
            retVal = BoolNode()..boolVal = left.className == right.className;

            final leftChildren = left.classChildren.whereType<VarDefNode>().toList();
            final rightChildren = right.classChildren.whereType<VarDefNode>().toList();

            if (leftChildren.length != rightChildren.length) {
              retVal.boolVal = false;
              return retVal;
            }

            for (int i = 0; i < leftChildren.length; i++) {
              retVal.boolVal = retVal.boolVal && (leftChildren[i] == rightChildren[i]);
            }

            return retVal;
          }

          if (left is ClassNode && right is NoSeebNode) {
            retVal = BoolNode();

            retVal.boolVal = left.classChildren.isEmpty;

            return retVal;
          }

          if (left is NoSeebNode && right is NoSeebNode) {
            retVal = BoolNode();

            retVal.boolVal = true;

            return retVal;
          }
        }
        break;
      case TokenType.TOKEN_NOT_EQUAL:
        {
          if (left is BoolNode && right is BoolNode) {
            retVal = BoolNode();

            retVal.boolVal = left.boolVal != right.boolVal;

            return retVal;
          }

          if (left is BoolNode && right.type == ASTType.AST_INT) {
            retVal = BoolNode();

            if (right.intVal != 1 && right.intVal != 0) {
              String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

              for (final Map item in stack.reversed.take(5))
                stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

              throw UnexpectedTokenException('Only integer literals `0` and `1` can be compared with a bool$stacktrace');
            }

            retVal.boolVal = left.boolVal != (right.intVal == 1);

            return retVal;
          }

          if (left is BoolNode && right is NoSeebNode) {
            retVal = BoolNode();

            retVal.boolVal = left.boolVal == null;

            return retVal;
          }

          if (left.type == ASTType.AST_INT && right is BoolNode) {
            if (left.intVal != 1 && left.intVal != 0) {
              String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

              for (final Map item in stack.reversed.take(5))
                stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

              throw UnexpectedTokenException('Only integer literals `0` and `1` can be compared with a bool.$stacktrace');
            }

            retVal = BoolNode();

            retVal.boolVal = (left.intVal == 1) != right.boolVal;

            return retVal;
          }

          if (left.type == ASTType.AST_INT && right.type == ASTType.AST_INT) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal != right.intVal;

            return retVal;
          }
          if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_DOUBLE) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal != right.doubleVal;

            return retVal;
          }
          if (left.type == ASTType.AST_INT && right.type == ASTType.AST_DOUBLE) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal != right.doubleVal;

            return retVal;
          }
          if (left.type == ASTType.AST_INT && right.type == ASTType.AST_NULL) {
            retVal = BoolNode();

            retVal.boolVal = left.intVal != 0 || left.intVal != null;

            return retVal;
          }
          if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_INT) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal != right.intVal;

            return retVal;
          }
          if (left.type == ASTType.AST_DOUBLE && right.type == ASTType.AST_NULL) {
            retVal = BoolNode();

            retVal.boolVal = left.doubleVal != 0 || left.doubleVal != null;

            return retVal;
          }
          if (left.type == ASTType.AST_STRING && right.type == ASTType.AST_STRING) {
            retVal = BoolNode();

            retVal.boolVal = left.stringValue != right.stringValue;

            return retVal;
          }

          if (left.type == ASTType.AST_STRING && right.type == ASTType.AST_NULL) {
            retVal = BoolNode();

            retVal.boolVal = left.stringValue != null;

            return retVal;
          }
          if (left.type == ASTType.AST_CLASS && right.type == ASTType.AST_CLASS) {
            retVal = BoolNode();

            retVal.boolVal = left.classChildren != right.classChildren;

            return retVal;
          }

          if (left.type == ASTType.AST_CLASS && right.type == ASTType.AST_NULL) {
            retVal = BoolNode();

            retVal.boolVal = left.classChildren.isNotEmpty;

            return retVal;
          }

          if (left.type == ASTType.AST_NULL && right.type == ASTType.AST_NULL) {
            retVal = BoolNode();

            retVal.boolVal = false;

            return retVal;
          }
        }
        break;

      default:
        String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

        for (final Map item in stack.reversed.take(5))
          stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

        throw InvalidOperatorException(
            'Error: [Line ${node.lineNum}] `${node.binaryOperator.value}` is not a valid operator.$stacktrace');
    }

    return node;
  }

  Future<ASTNode> visitUnaryOp(ASTNode node) async {
    final ASTNode right = await visit(node.unaryOpRight);

    ASTNode returnValue = INITIALIZED_NOOP;

    switch (node.unaryOperator.type) {
      case TokenType.TOKEN_ONES_COMPLEMENT:
        {
          if (right.type == ASTType.AST_INT) {
            returnValue = IntNode()..intVal = ~right.intVal;
          }
        }
        break;
      case TokenType.TOKEN_SUB:
        {
          if (right.type == ASTType.AST_INT) {
            returnValue = IntNode()..intVal = -right.intVal;
          } else if (right.type == ASTType.AST_DOUBLE) {
            returnValue = DoubleNode()..doubleVal = -right.doubleVal;
          }
        }
        break;

      case TokenType.TOKEN_PLUS:
        {
          if (right.type == ASTType.AST_INT) {
            returnValue = IntNode();
            returnValue.intVal = right.intVal.abs();
          } else if (right.type == ASTType.AST_DOUBLE) {
            returnValue = DoubleNode();
            returnValue.doubleVal = right.doubleVal.abs();
          }
        }
        break;

      case TokenType.TOKEN_PLUS_PLUS:
        {
          final ASTNode variable = await visitVariable(node.unaryOpRight);
          if (variable.type == ASTType.AST_INT)
            return variable..intVal += 1;
          else
            return variable..doubleVal += 1;
        }
        break;

      case TokenType.TOKEN_SUB_SUB:
        {
          final ASTNode variable = await visitVariable(node.unaryOpRight);
          if (variable.type == ASTType.AST_INT)
            return variable..intVal -= 1;
          else
            return variable..doubleVal -= 1;
        }
        break;
      case TokenType.TOKEN_MUL_MUL:
        {
          final ASTNode variable = await visitVariable(node.unaryOpRight);
          if (variable.type == ASTType.AST_INT)
            return variable..intVal *= variable.intVal;
          else
            return variable..doubleVal *= variable.doubleVal;
        }
        break;
      case TokenType.TOKEN_NOT:
        {
          final ASTNode boolAST = BoolNode();
          switch (node.unaryOpRight.type) {
            case ASTType.AST_VARIABLE:
              {
                boolAST.boolVal = !boolEval(await visitVariable(node.unaryOpRight));
                return boolAST;
              }
              break;
            default:
              boolAST.boolVal = !boolEval(node.unaryOpRight);
              break;
          }
          break;
        }
        break;

      default:
        String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

        for (final Map item in stack.reversed.take(5))
          stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

        throw InvalidOperatorException(
            'Error: [Line ${node.lineNum}] `${node.unaryOperator.value}` is not a valid operator.$stacktrace');
    }

    return returnValue;
  }

  Future<ASTNode> visitIf(ASTNode node) async {
    if (node.ifExpression == null) {
      String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

      for (final Map item in stack.reversed.take(5))
        stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

      throw UnexpectedTypeException('Error: [Line ${node.lineNum}] If expression can\'t be empty.$stacktrace');
    }

    if (node.ifExpression.type == ASTType.AST_UNARYOP) {
      if (boolEval(await visit(node.ifExpression.unaryOpRight)) == false) {
        return await visit(node.ifBody);
      } else {
        if (node.ifElse != null)
          return await visit(node.ifElse);

        if (node.elseBody != null)
          return await visit(node.elseBody);
      }
    } else {
      if (boolEval(await visit(node.ifExpression))) {
        return await visit(node.ifBody);
      } else {
        if (node.ifElse != null)
          return await visit(node.ifElse);

        if (node.elseBody != null)
          return await visit(node.elseBody);
      }
    }
    return node;
  }

  Future<ASTNode> visitSwitch(ASTNode node) async {
    if (node.switchExpression == null) {
      String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

      for (final Map item in stack.reversed.take(5))
        // ignore: unnecessary_brace_in_string_interps
        stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';

      throw UnexpectedTypeException('Error: [Line ${node.lineNum}] Switch expression can\'t be empty$stacktrace');
    }

    final ASTNode caseAST = await visit(node.switchExpression);

    switch (caseAST.type) {
      case ASTType.AST_STRING:
        final Iterable<ASTNode> testCase =
        node.switchCases.keys.where((element) => element.stringValue == caseAST.stringValue);

        if (testCase != null && testCase.isNotEmpty) {
          return await visit(node.switchCases[testCase.first]);
        }
        return await visit(node.switchDefault);
      case ASTType.AST_INT:
        final Iterable<ASTNode> testCase = node.switchCases.keys.where((element) => element.intVal == caseAST.intVal);

        if (testCase != null && testCase.isNotEmpty) {
          return await visit(node.switchCases[testCase.first]);
        }
        return await visit(node.switchDefault);
      case ASTType.AST_DOUBLE:
        final Iterable<ASTNode> testCase =
        node.switchCases.keys.where((element) => element.doubleVal == caseAST.doubleVal);

        if (testCase != null && testCase.isNotEmpty) {
          return await visit(node.switchCases[testCase.first]);
        }
        return await visit(node.switchDefault);
      case ASTType.AST_MAP:
        final Iterable<ASTNode> testCase = node.switchCases.keys.where((element) => element.map == caseAST.map);

        if (testCase != null && testCase.isNotEmpty) {
          return await visit(node.switchCases[testCase.first]);
        }
        return await visit(node.switchDefault);
      case ASTType.AST_LIST:
        final Iterable<ASTNode> testCase =
        node.switchCases.keys.where((element) => element.listElements == caseAST.listElements);

        if (testCase != null && testCase.isNotEmpty) {
          return await visit(node.switchCases[testCase.first]);
        }
        return await visit(node.switchDefault);
      default:
        return await visit(node.switchDefault);
    }
  }

  Future<ASTNode> visitTernary(ASTNode node) async {
    return boolEval(await visit(node.ternaryExpression))
        ? await visit(node.ternaryBody)
        : await visit(node.ternaryElseBody);
  }

  Future<ASTNode> visitWhile(ASTNode node) async {
    while (boolEval(await visit(node.whileExpression))) {
      final visited = await visit(node.whileBody);

      if (visited.type == ASTType.AST_BREAK)
        break;
      else if (visited.type == ASTType.AST_NEXT)
        continue;
    }

    return node;
  }

  Future<ASTNode> visitFor(ASTNode node) async {
    await visit(node.forInitStatement);

    while (boolEval(await visit(node.forConditionStatement))) {
      final visited = await visit(node.forBody);

      if (visited is BreakNode)
        break;
      else if (visited is NextNode) {
        await visit(node.forChangeStatement);
        continue;
      }
      await visit(node.forChangeStatement);
    }

    return node;
  }

  Future<ASTNode> visitNew(ASTNode node) async => (await visit(node.newValue)).copy();

  Future<ASTNode> visitIterate(ASTNode node) async {
    final scope = getScope(node);
    final ASTNode astIterable = await visit(node.iterateIterable);

    ASTNode fDef;

    if (node.iterateFunction.type == ASTType.AST_FUNC_DEFINITION)
      fDef = node.iterateFunction;

    if (fDef == null) {
      for (int i = 0; i < scope.functionDefinitions.length; i++) {
        fDef = scope.functionDefinitions.elementAt(i);

        if (fDef.funcName == node.iterateFunction.variableName) {
          if (fDef.funcPointer != null) {
            String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

            stack.reversed.take(5).forEach((Map item) {
              stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n';
            });

            throw UnexpectedTypeException('Error: Can not iterate with native method.$stacktrace');
          }
          break;
        }
      }
    }

    final fDefBodyScope = fDef.functionDefBody.scope;
    final iterableVarName = (fDef.functionDefArgs[0]).variableName;

    int i = 0;

    for (int j = fDefBodyScope.variableDefinitions.length - 1; j > 0; j--) {
      fDefBodyScope.variableDefinitions.remove(fDefBodyScope.variableDefinitions.elementAt(i));
    }

    ASTNode indexVar;

    if (fDef.functionDefArgs.length > 1) {
      indexVar = VarDefNode();
      indexVar.variableValue = IntNode();
      indexVar.variableValue.intVal = i;
      indexVar.variableName = (fDef.functionDefArgs[0]).variableName;

      fDefBodyScope.variableDefinitions.addFirst(indexVar);
    }

    if (astIterable.type == ASTType.AST_STRING) {
      final VarDefNode newVarDef = VarDefNode();
      newVarDef.variableValue = StringNode();
      newVarDef.variableValue.stringValue = astIterable.stringValue[i];
      newVarDef.variableName = iterableVarName;

      fDefBodyScope.variableDefinitions.addFirst(newVarDef);

      for (; i < astIterable.stringValue.length; i++) {
        newVarDef.variableValue.stringValue = astIterable.stringValue[i];

        if (indexVar != null)
          indexVar.variableValue.intVal = i;

        await visit(fDef.functionDefBody);
      }
    } else if (astIterable.type == ASTType.AST_LIST) {
      final VarDefNode newVarDef = VarDefNode();
      newVarDef.variableValue = await visit(astIterable.listElements[i]);
      newVarDef.variableName = iterableVarName;

      fDefBodyScope.variableDefinitions.addFirst(newVarDef);

      for (; i < astIterable.listElements.length; i++) {
        newVarDef.variableValue = await visit(astIterable.listElements[i] as ASTNode);

        if (indexVar != null)
          indexVar.variableValue.intVal = i;

        await visit(fDef.functionDefBody);
      }
    }

    return INITIALIZED_NOOP;
  }

  Future<ASTNode> visitAssert(ASTNode node) async {
    final ASTNode boolAST = await visit(node.assertExpression);
    if (!boolEval(boolAST)) {
      String str;

      if (node.assertExpression.type == ASTType.AST_BINARYOP) {
        final left = (await visit(node.assertExpression.binaryOpLeft)).toString();
        final right = (await visit(node.assertExpression.binaryOpRight)).toString();
        str = 'ASSERT($left, $right)';

        print(str);
      } else {
        str = (await visit(node.assertExpression)).toString();
        print(str);
      }
      String stacktrace = '\nThe stacktrace when the error was thrown was:\n';

      stack.reversed
          .take(5)
          .forEach((Map item) => stacktrace += ' [Line:${item['line']}] $path::${item['function']}\n');

      throw AssertionException('Assert failed.$stacktrace');
    }

    return INITIALIZED_NOOP;
  }

}

/// Expect arguments for a function
void expectArgs(List inArgs, List<Type> args) {
  if (inArgs.length < args.length)
    throw InvalidArgumentsException('${inArgs.length} argument(s) were provided, while ${args.length} were expected');

  for (int i = 0; i < args.length; i++) {
    if (args[i] == AnyNode)
      continue;

    final ASTNode ast = inArgs[i];

    if (ast.runtimeType != args[i]) {
      print('Received argument of type ${ast.runtimeType}, but expected ${args[i]}');
      throw const InvalidArgumentsException('Got unexpected arguments, terminating');
    }
  }
}
