import 'dart:collection';

import 'package:Birb/lexer/token.dart';
import 'package:Birb/parser/data_type.dart';
import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/scope.dart';

typedef AstFuncPointer = ASTNode Function(Runtime runtime, ASTNode self, List<ASTNode> args);
typedef AstFutureFuncPointer = Future<ASTNode> Function(
    Runtime runtime, ASTNode self, List<ASTNode> args);


ASTNode initASTWithLine(ASTNode node, int line) {
  node.lineNum = line;
  return node;
}

abstract class ASTNode {
  ASTNode parent;

  bool isClassChild = false;

  ASTType type;

  DataType typeValue;

  int lineNum;

  Scope scope;

  ASTNode get assertExpression => throw Exception('Not part of $runtimeType => $type');
  set assertExpression(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get ast => throw Exception('Not part of $runtimeType => $type');
  set ast(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get binaryOpLeft => throw Exception('Not part of $runtimeType => $type');
  set binaryOpLeft(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get binaryOpRight => throw Exception('Not part of $runtimeType => $type');
  set binaryOpRight(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  Token get binaryOperator => throw Exception('Not part of $runtimeType => $type');
  set binaryOperator(Token _) => throw Exception('Not part of $runtimeType => $type');

  bool get boolVal => throw Exception('Not part of $runtimeType => $type');
  set boolVal(bool _) => throw Exception('Not part of $runtimeType => $type');

  String get className => throw Exception('Not part of $runtimeType => $type');
  set className(String _) => throw Exception('Not part of $runtimeType => $type');

  ListQueue<ASTNode> get classChildren => throw Exception('Not part of $runtimeType => $type');
  set classChildren(ListQueue<ASTNode> _) => throw Exception('Not part of $runtimeType => $type');

  List<ASTNode> get compChildren => throw Exception('Not part of $runtimeType => $type');
  set compChildren(List<ASTNode> _) => throw Exception('Not part of $runtimeType => $type');

  List<ASTNode> get compoundValue => throw Exception('Not part of $runtimeType => $type');
  set compoundValue(List<ASTNode> _) => throw Exception('Not part of $runtimeType => $type');

  double get doubleVal => throw Exception('Not part of $runtimeType => $type');
  set doubleVal(double _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get elseBody => throw Exception('Not part of $runtimeType => $type');
  set elseBody(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  List<ASTNode> get enumElements => throw Exception('Not part of $runtimeType => $type');
  set enumElements(List<ASTNode> _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get forBody => throw Exception('Not part of $runtimeType => $type');
  set forBody(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get forChangeStatement => throw Exception('Not part of $runtimeType => $type');
  set forChangeStatement(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get forConditionStatement => throw Exception('Not part of $runtimeType => $type');
  set forConditionStatement(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get forInitStatement => throw Exception('Not part of $runtimeType => $type');
  set forInitStatement(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  List<ASTNode> get funcCallArgs => throw Exception('Not part of $runtimeType => $type');
  set funcCallArgs(List<ASTNode> _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get funcCallExpression => throw Exception('Not part of $runtimeType => $type');
  set funcCallExpression(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  List<ASTNode> get funcDefArgs => throw Exception('Not part of $runtimeType => $type');
  set funcDefArgs(List<ASTNode> _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get funcDefBody => throw Exception('Not part of $runtimeType => $type');
  set funcDefBody(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get funcDefType => throw Exception('Not part of $runtimeType => $type');
  set funcDefType(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  List get funcDefinitions => throw Exception('Not part of $runtimeType => $type');
  set funcDefinitions(List _) => throw Exception('Not part of $runtimeType => $type');

  String get funcName => throw Exception('Not part of $runtimeType => $type');
  set funcName(String _) => throw Exception('Not part of $runtimeType => $type');

  AstFuncPointer get funcPointer => throw Exception('Not part of $runtimeType => $type');
  set funcPointer(AstFuncPointer _) => throw Exception('Not part of $runtimeType => $type');

  AstFutureFuncPointer get futureFuncPointer => throw Exception('Not part of $runtimeType => $type');
  set futureFuncPointer(AstFutureFuncPointer _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get ifBody => throw Exception('Not part of $runtimeType => $type');
  set ifBody(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get ifElse => throw Exception('Not part of $runtimeType => $type');
  set ifElse(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get ifExpression => throw Exception('Not part of $runtimeType => $type');
  set ifExpression(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  int get intVal => throw Exception('Not part of $runtimeType => $type');
  set intVal(int _) => throw Exception('Not part of $runtimeType => $type');

  bool get isFinal => throw Exception('Not part of $runtimeType => $type');
  set isFinal(bool _) => throw Exception('Not part of $runtimeType => $type');

  bool get isNullable => throw Exception('Not part of $runtimeType => $type');
  set isNullable(bool _) => throw Exception('Not part of $runtimeType => $type');

  bool get isSuperseding => throw Exception('Not part of $runtimeType => $type');
  set isSuperseding(bool _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get iterateFunction => throw Exception('Not part of $runtimeType => $type');
  set iterateFunction(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get iterateIterable => throw Exception('Not part of $runtimeType => $type');
  set iterateIterable(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get listAccessPointer => throw Exception('Not part of $runtimeType => $type');
  set listAccessPointer(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  List get listElements => throw Exception('Not part of $runtimeType => $type');
  set listElements(List _) => throw Exception('Not part of $runtimeType => $type');

  Map<String, dynamic> get map => throw Exception('Not part of $runtimeType => $type');
  set map(Map<String, dynamic> _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get newValue => throw Exception('Not part of $runtimeType => $type');
  set newValue(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get returnValue => throw Exception('Not part of $runtimeType => $type');
  set returnValue(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get throwValue => throw Exception('Not part of $runtimeType => $type');
  set throwValue(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get savedFuncCall => throw Exception('Not part of $runtimeType => $type');
  set savedFuncCall(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  StringBuffer get strBuffer => throw Exception('Not part of $runtimeType => $type');
  set strBuffer(StringBuffer _) => throw Exception('Not part of $runtimeType => $type');

  String get stringValue => throw Exception('Not part of $runtimeType => $type');
  set stringValue(String _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get superClass => throw Exception('Not part of $runtimeType => $type');
  set superClass(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  Map<ASTNode, ASTNode> get switchCases => throw Exception('Not part of $runtimeType => $type');
  set switchCases(Map<ASTNode, ASTNode>_) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get switchDefault => throw Exception('Not part of $runtimeType => $type');
  set switchDefault(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get switchExpression => throw Exception('Not part of $runtimeType => $type');
  set switchExpression(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get ternaryBody => throw Exception('Not part of $runtimeType => $type');
  set ternaryBody(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get ternaryElseBody => throw Exception('Not part of $runtimeType => $type');
  set ternaryElseBody(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get ternaryExpression => throw Exception('Not part of $runtimeType => $type');
  set ternaryExpression(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get unaryOpRight => throw Exception('Not part of $runtimeType => $type');
  set unaryOpRight(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  Token get unaryOperator => throw Exception('Not part of $runtimeType => $type');
  set unaryOperator(Token _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get variableAssignmentLeft => throw Exception('Not part of $runtimeType => $type');
  set variableAssignmentLeft(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  String get variableName => throw Exception('Not part of $runtimeType => $type');
  set variableName(String _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get variableType => throw Exception('Not part of $runtimeType => $type');
  set variableType(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get variableValue => throw Exception('Not part of $runtimeType => $type');
  set variableValue(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get whileBody => throw Exception('Not part of $runtimeType => $type');
  set whileBody(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode get whileExpression => throw Exception('Not part of $runtimeType => $type');
  set whileExpression(ASTNode _) => throw Exception('Not part of $runtimeType => $type');

  ASTNode copy();
}

enum ASTType {
  AST_CLASS,
  AST_ENUM,
  AST_VARIABLE,
  AST_VARIABLE_DEFINITION,
  AST_VARIABLE_ASSIGNMENT,
  AST_VARIABLE_MODIFIER,
  AST_FUNC_DEFINITION,
  AST_FUNC_CALL,
  AST_NULL,
  AST_STRING,
  AST_STRING_BUFFER,
  AST_DOUBLE,
  AST_LIST,
  AST_MAP,
  AST_BOOL,
  AST_INT,
  AST_ANY,
  AST_COMPOUND,
  AST_TYPE,
  AST_BINARYOP,
  AST_UNARYOP,
  AST_NOOP,
  AST_NEW,
  AST_BREAK,
  AST_RETURN,
  AST_THROW,
  AST_NEXT,
  AST_TERNARY,
  AST_IF,
  AST_ELSE,
  AST_SWITCH,
  AST_WHILE,
  AST_FOR,
  AST_ATTRIBUTE_ACCESS,
  AST_LIST_ACCESS,
  AST_ITERATE,
  AST_ASSERT
}

String astToString(ASTNode ast) {
  switch (ast.type) {
    case ASTType.AST_CLASS:
      return '{ class }';
    case ASTType.AST_VARIABLE:
      return ast.variableName;
    case ASTType.AST_FUNC_DEFINITION:
      return '${ast.funcName} (${ast.funcDefArgs.length})';
    case ASTType.AST_FUNC_CALL:
      final String expressionStr = astToString(ast.funcCallExpression);
      return '$expressionStr (${ast.funcCallArgs.length})';
    case ASTType.AST_NULL:
      return 'null';
    case ASTType.AST_STRING:
      return ast.stringValue;
    case ASTType.AST_STRING_BUFFER:
      return '[ StrBuffer ]';
    case ASTType.AST_DOUBLE:
      return ast.doubleVal.toString();
    case ASTType.AST_LIST:
      return ast.listElements.toString();
    case ASTType.AST_MAP:
      return ast.map.toString();
    case ASTType.AST_BOOL:
      return ast.boolVal.toString();
    case ASTType.AST_INT:
      return ast.intVal.toString();
    case ASTType.AST_TYPE:
      return '< Type >';
    case ASTType.AST_ATTRIBUTE_ACCESS:
      return '$astToString(ast.binaryOpLeft).$astToString(ast.binaryOpRight)';
    case ASTType.AST_LIST_ACCESS:
      return 'list[access]';
    case ASTType.AST_BINARYOP:
      ASTNode visitedBiOp;
      visitBinaryOp(initRuntime(null), ast).then((value) => visitedBiOp = value);
      return astToString(visitedBiOp);
    case ASTType.AST_NOOP:
      return '{{NO-OP}}';
    case ASTType.AST_BREAK:
      return 'break';
    case ASTType.AST_RETURN:
      return astToString(ast.returnValue);
    case ASTType.AST_ENUM:
      return ast.variableName;
    default:
      print('Could not convert ast of type ${ast.type} to String');
      return null;
  }
}
