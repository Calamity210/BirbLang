import 'data_type.dart';
import 'runtime.dart';
import 'scope.dart';
import 'token.dart';

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
  int intVal;

  // AST_BOOL
  bool boolValue = false;

  bool isClassChild = false;

  // AST_DOUBLE
  double doubleValue;

  // AST_STRING
  String stringValue;

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

  dynamic classValue;

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

  AstFuncPointer fptr;
  AstFutureFuncPointer futureptr;
}

/// Initializes the Abstract Syntax tree with default values
AST initAST(ASTType type) {
  var ast = AST()..type = type;
  ast.compoundValue = ast.type == ASTType.AST_COMPOUND ? [] : null;
  ast.funcCallArgs = ast.type == ASTType.AST_FUNC_CALL ? [] : null;
  ast.funcDefArgs = ast.type == ASTType.AST_FUNC_DEFINITION ? [] : null;
  ast.classChildren = ast.type == ASTType.AST_CLASS ? [] : null;
  ast.enumElements = ast.type == ASTType.AST_ENUM ? [] : null;
  ast.listElements = ast.type == ASTType.AST_LIST ? [] : null;
  ast.compChildren = ast.type == ASTType.AST_FUNC_DEFINITION ? [] : null;

  return ast;
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
    case ASTType.AST_DOUBLE:
      return ast.doubleValue.toStringAsPrecision(6).padRight(12);
    case ASTType.AST_LIST:
      return ast.listElements.toString();
    case ASTType.AST_MAP:
      return ast.map.toString();
    case ASTType.AST_BOOL:
      return ast.boolValue.toString();
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
