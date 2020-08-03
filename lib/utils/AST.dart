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
  AST_NEW,
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
  AST newValue;
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
  var node = initAST(type);
  node.lineNum = line;

  return node;
}

AST astRScope(AST ast, Scope scope) {
  ast.scope = scope;
  return ast;
}

String astToString(AST ast) {
  switch (ast.type) {
    case ASTType.AST_CLASS:
      return astClassToString(ast);
    case ASTType.AST_VARIABLE:
      return ast.variableName;
    case ASTType.AST_FUNC_DEFINITION:
      return astFunctionDefinitionToString(ast);
    case ASTType.AST_FUNC_CALL:
      return astFunctionCallToString(ast);
    case ASTType.AST_NULL:
      return astNullToString(ast);
    case ASTType.AST_STRING:
      {
        return ast.stringValue;
      }
    case ASTType.AST_DOUBLE:
      return astDoubleToString(ast);
    case ASTType.AST_LIST:
      return astListToString(ast);
    case ASTType.AST_BOOL:
      return astBoolToString(ast);
    case ASTType.AST_INT:
      return astIntToString(ast);
    case ASTType.AST_TYPE:
      return astTypeToString(ast);
    case ASTType.AST_ATTRIBUTE_ACCESS:
      return astAttributeAccessToString(ast);
    case ASTType.AST_LIST_ACCESS:
      return astListAccessToString(ast);
    case ASTType.AST_BINARYOP:
      {
        AST visitedBiOp;
        visitBinaryOp(initRuntime(), ast).then((value) => visitedBiOp = value);
        return astToString(visitedBiOp);
      }
    case ASTType.AST_NOOP:
      return '';
    case ASTType.AST_BREAK:
      return '';
    case ASTType.AST_RETURN:
      return astToString(ast.returnValue);
    case ASTType.AST_ENUM:
      return astEnumToString(ast);
    default:
      print('Could no convert ast of type ${ast.type} to String');
      return null;
  }
}

String astClassToString(AST ast) {
  return '{ class }';
}

String astFunctionDefinitionToString(AST ast) {
  return '${ast.funcName} (${ast.funcDefArgs.length})';
}

String astFunctionCallToString(AST ast) {
  var expressionStr = astToString(ast.funcCallExpression);

  return '$expressionStr (${ast.funcCallArgs.length})';
}

String astNullToString(AST ast) {
  return 'null';
}

String astDoubleToString(AST ast) {
  return ast.doubleValue.toStringAsPrecision(6).padRight(12);
}

String astListToString(AST ast) {
  return '[ list ]';
}

String astBoolToString(AST ast) {
  return ast.boolValue.toString();
}

String astIntToString(AST ast) {
  return ast.intVal.toString();
}

String astTypeToString(AST ast) {
  return '< type >';
}

String astAttributeAccessToString(AST ast) {
  return '$astToString(ast.binaryOpLeft).$astToString(ast.binaryOpRight)';
}

String astListAccessToString(AST ast) {
  return '[ listAccess ]';
}

String astBinopToString(AST ast) {
  return '$astToString(ast.binaryOpLeft).$astToString(ast.binaryOpRight)';
}

String astEnumToString(AST ast) {
  return ast.variableName;
}
