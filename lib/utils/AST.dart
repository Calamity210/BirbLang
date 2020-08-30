import 'package:Birb/utils/ast/ast_types.dart' as types;

import '../parser/data_type.dart';
import '../runtime/runtime.dart';
import 'scope.dart';
import '../lexer/token.dart';

typedef AstFuncPointer = AST Function(Runtime runtime, AST self, List args);
typedef AstFutureFuncPointer = Future<AST> Function(
    Runtime runtime, AST self, List args);

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
  AST_BREAK,
  AST_RETURN,
  AST_CONTINUE,
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

class AST {
  ASTType type;

  AST funcCallExpression;

  int lineNum;

  // AST_INT
  int intVal = 0;

  // AST_BOOL
  bool boolVal = false;

  bool isClassChild = false;

  // AST_DOUBLE
  double doubleVal = 0;

  // AST_STRING
  String stringValue;

  // AST_STRING_BUFFER
  StringBuffer strBuffer;

  DataType typeValue;

  // AST_VARIABLE_DEFINITION
  String variableName;
  AST variableValue;
  AST variableType;
  AST variableAssignmentLeft;
  bool isFinal = false;

  String funcName;

  // AST_BINARYOP
  AST binaryOpLeft;
  AST binaryOpRight;
  Token binaryOperator;

  // AST_UNARYOP
  AST unaryOpRight;
  Token unaryOperator;

  // AST_FOR
  AST forInitStatement;
  AST forConditionStatement;
  AST forChangeStatement;
  AST forBody;

  List compoundValue;

  List funcCallArgs;

  List funcDefinitions;
  List funcDefArgs;
  AST funcDefBody;
  AST funcDefType;

  List classChildren;
  List enumElements;
  List listElements;
  Map<String, dynamic> map;
  List compChildren;

  // AST_IF
  AST ifExpression;
  AST ifBody;
  AST ifElse;
  AST elseBody;

  // AST_SWITCH
  AST switchExpression;
  Map<AST, AST> switchCases;
  AST switchDefault;

  // AST_TERNARYOP
  AST ternaryExpression;
  AST ternaryBody;
  AST ternaryElseBody;

  AST whileExpression;
  AST whileBody;
  AST returnValue;
  AST listAccessPointer;
  AST savedFuncCall;
  AST iterateIterable;
  AST iterateFunction;

  AST ast;
  AST parent;
  AST assertExpression;

  Scope scope;

  AstFuncPointer funcPointer;
  AstFutureFuncPointer futureFuncPointer;
}

/// Initializes the Abstract Syntax tree with default values
AST initAST(ASTType type) {
  return types.initAST(type);
}

AST initASTWithLine(ASTType type, int line) {
  var node = initAST(type)..lineNum = line;

  return node;
}

String astToString(AST ast) {
  switch (ast.type) {
    case ASTType.AST_CLASS:
      return '{ class }';
    case ASTType.AST_VARIABLE:
      return ast.variableName;
    case ASTType.AST_FUNC_DEFINITION:
      return '${ast.funcName} (${ast.funcDefArgs.length})';
    case ASTType.AST_FUNC_CALL:
      String expressionStr = astToString(ast.funcCallExpression);
      return '$expressionStr (${ast.funcCallArgs.length})';
    case ASTType.AST_NULL:
      return 'null';
    case ASTType.AST_STRING:
      return ast.stringValue;
    case ASTType.AST_STRING_BUFFER:
      return '[ StrBuffer ]';
    case ASTType.AST_DOUBLE:
      return ast.doubleVal.toStringAsPrecision(6).padRight(12);
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
      AST visitedBiOp;
      visitBinaryOp(initRuntime(), ast).then((value) => visitedBiOp = value);
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
      print('Could no convert ast of type ${ast.type} to String');
      return null;
  }
}
