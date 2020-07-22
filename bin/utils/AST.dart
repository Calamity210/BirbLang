import 'data_type.dart';
import 'runtime.dart';
import 'scope.dart';
import 'token.dart';

typedef AstFPtr = AST Function(Runtime runtime, AST self, List args);
typedef FutAstFPtr = Future<AST> Function(Runtime runtime, AST self, List args);

enum ASTType {
  AST_OBJECT,
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

  int lineNum = 0;

// AST_INT
  int intVal = 0;

// AST_BOOL
  bool boolValue = false;

  bool isObjectChild = false;

  // AST_DOUBLE
  double doubleValue = 0.0;

  // AST_STRING
  String stringValue;

  DataType typeValue;

  // AST_VARIABLE_DEFINITION
  String variableName;
  AST variableValue;
  AST variableType;
  AST variableAssignmentLeft;

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

  List objectChildren;
  List enumChildren;
  List listChildren;
  Map<String, dynamic> map;
  List compChildren;

  dynamic objectValue;

  // AST_IF
  AST ifExpression;
  AST ifBody;
  AST ifElse;
  AST elseBody;

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

  AstFPtr fptr;
  FutAstFPtr futureptr;
}

AST initAST(ASTType type) {
  var ast = AST();
  ast.type = type;
  ast.compoundValue = ast.type == ASTType.AST_COMPOUND ? [] : null;
  ast.funcCallArgs = ast.type == ASTType.AST_FUNC_CALL ? [] : null;
  ast.funcDefArgs = ast.type == ASTType.AST_FUNC_DEFINITION ? [] : null;
  ast.objectChildren = ast.type == ASTType.AST_OBJECT ? [] : null;
  ast.enumChildren = ast.type == ASTType.AST_ENUM ? [] : null;
  ast.listChildren = ast.type == ASTType.AST_LIST ? [] : null;
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

AST astCopy(AST ast) {
  if (ast == null) {
    return null;
  }

  switch (ast.type) {
    case ASTType.AST_OBJECT:
      return astRScope(astCopyObject(ast), ast.scope);
    case ASTType.AST_VARIABLE:
      return astRScope(astCopyVariable(ast), ast.scope);
    case ASTType.AST_VARIABLE_DEFINITION:
      return astRScope(astCopyVariableDefinition(ast), ast.scope);
    case ASTType.AST_VARIABLE_ASSIGNMENT:
      return astRScope(astCopyVariableAssignment(ast), ast.scope);
    case ASTType.AST_VARIABLE_MODIFIER:
      return astRScope(astCopyVariableModifier(ast), ast.scope);
    case ASTType.AST_FUNC_DEFINITION:
      return astRScope(astCopyFunctionDefinition(ast), ast.scope);
    case ASTType.AST_FUNC_CALL:
      return astRScope(astCopyFunctionCall(ast), ast.scope);
    case ASTType.AST_NULL:
      return astRScope(astCopyNull(ast), ast.scope);
    case ASTType.AST_STRING:
      return astRScope(astCopyString(ast), ast.scope);
    case ASTType.AST_DOUBLE:
      return astRScope(astCopyDouble(ast), ast.scope);
    case ASTType.AST_LIST:
      return astRScope(astCopyList(ast), ast.scope);
    case ASTType.AST_BOOL:
      return astRScope(astCopyBool(ast), ast.scope);
    case ASTType.AST_INT:
      return astRScope(astCopyInt(ast), ast.scope);
    case ASTType.AST_COMPOUND:
      return astRScope(astCopyCompound(ast), ast.scope);
    case ASTType.AST_TYPE:
      return astRScope(astCopyType(ast), ast.scope);
    case ASTType.AST_BINARYOP:
      return astRScope(astCopyBinop(ast), ast.scope);
    case ASTType.AST_NOOP:
      return ast;
    case ASTType.AST_BREAK:
      return ast;
    case ASTType.AST_RETURN:
      return astRScope(astCopyReturn(ast), ast.scope);
    case ASTType.AST_IF:
      return astRScope(astCopyIf(ast), ast.scope);
    case ASTType.AST_WHILE:
      return astRScope(astCopyWhile(ast), ast.scope);
    default:
      print('AST type ${ast.type} cannot be copied');
      return null;
  }
}

AST astCopyObject(AST ast) {
  var a = initAST(ast.type);
  a.scope = ast.scope;
  a.objectChildren = [];

  for (int i = 0; i < ast.objectChildren.length; i++) {
    var childCopy = astCopy(ast);
    a.objectChildren.add(childCopy);
  }

  return a;
}

AST astCopyVariable(AST ast) {
  AST type;

  if (ast.variableType != null) {
    type = astCopy(ast.variableType);
  }

  var a = initAST(ast.type);
  a.scope = ast.scope;
  a.variableType = type;
  a.variableValue = astCopy(ast.variableValue);
  a.variableName = ast.variableName;

  return a;
}

AST astCopyVariableDefinition(AST ast) {
  var a = initAST(ast.type);
  a.scope = ast.scope;
  a.variableValue = astCopy(ast.variableValue);
  a.variableType = astCopy(ast.variableType);
  a.variableName = ast.variableName;

  return a;
}

AST astCopyFunctionDefinition(AST ast) {
  var a = initAST(ast.type);
  a.scope = ast.scope;
  a.funcName = ast.funcName;
  a.funcDefBody = astCopy(ast.funcDefBody);
  a.funcDefArgs = [];

  for (int i = 0; i < ast.funcDefArgs.length; i++) {
    var item = astCopy(ast.funcDefArgs[i]);
    a.funcDefArgs.add(item);
  }

  return a;
}

AST astCopyString(AST ast) {
  var a = initAST(ast.type);
  a.scope = ast.scope;
  a.stringValue = ast.stringValue;

  return a;
}

AST astCopyDouble(AST ast) {
  var a = initAST(ast.type);
  a.scope = ast.scope;
  a.doubleValue = ast.doubleValue;

  return a;
}

AST astCopyList(AST ast) {
  var a = initAST(ast.type);
  a.scope = ast.scope;
  a.listChildren = [];

  for (int i = 0; i < ast.listChildren.length; i++) {
    var item = astCopy(ast.listChildren[i]);
    a.listChildren.add(item);
  }

  return a;
}

AST astCopyBool(AST ast) {
  var a = initAST(ast.type);
  a.scope = ast.scope;
  a.boolValue = ast.boolValue;

  return a;
}

AST astCopyInt(AST ast) {
  var a = initAST(ast.type);
  a.scope = ast.scope;
  a.intVal = ast.intVal;

  return a;
}

AST astCopyCompound(AST ast) {
  var a = initAST(ast.type);
  a.scope = ast.scope;
  a.compoundValue = [];

  for (int i = 0; i < ast.compoundValue.length; i++) {
    var item = astCopy(ast.compoundValue[i]);
    a.compoundValue.add(item);
  }

  return a;
}

AST astCopyType(AST ast) {
  var a = initAST(ast.type);
  a.scope = ast.scope;
  a.typeValue = dataTypeCopy(ast.typeValue);

  return a;
}

AST astCopyAttributeAccess(AST ast) {
  var a = initAST(ast.type);
  a.scope = ast.scope;
  a.binaryOpLeft = astCopy(ast.binaryOpLeft);
  a.binaryOpRight = astCopy(ast.binaryOpRight);
  a.binaryOperator = ast.binaryOperator;

  return a;
}

AST astCopyReturn(AST ast) {
  var a = initAST(ast.type);
  a.scope = ast.scope;

  if (ast.returnValue != null) {
    a.returnValue = astCopy(ast.returnValue);
  }

  return a;
}

AST astCopyVariableAssignment(AST ast) {
  var a = initAST(ast.type);
  a.variableAssignmentLeft = astCopy(ast.variableAssignmentLeft);
  a.variableValue = astCopy(ast.variableValue);

  return a;
}

AST astCopyVariableModifier(AST ast) {
  var a = initAST(ast.type);
  a.binaryOpLeft = astCopy(ast.binaryOpLeft);
  a.binaryOpRight = astCopy(ast.binaryOpRight);
  a.binaryOperator = ast.binaryOperator;

  return a;
}

AST astCopyFunctionCall(AST ast) {
  var a = initAST(ast.type);
  a.funcCallExpression = astCopy(ast.funcCallExpression);
  a.funcCallArgs = [];

  for (int i = 0; i < ast.funcCallArgs.length; i++) {
    var item = astCopy(ast.funcCallArgs[i]);
    a.funcCallArgs.add(item);
  }

  return a;
}

AST astCopyNull(AST ast) {
  var a = initAST(ast.type);

  return a;
}

AST astCopyListAccess(AST ast) {
  var a = initAST(ast.type);
  a.listAccessPointer = astCopy(ast.listAccessPointer);

  return a;
}

AST astCopyBinop(AST ast) {
  var a = initAST(ast.type);
  a.binaryOpLeft = astCopy(ast.binaryOpLeft);
  a.binaryOpRight = astCopy(ast.binaryOpRight);
  a.binaryOperator = ast.binaryOperator;

  return a;
}

AST astCopyIf(AST ast) {
  var a = initAST(ast.type);
  a.ifExpression = astCopy(ast.ifExpression);
  a.ifBody = astCopy(ast.ifBody);
  a.ifElse = ast.ifElse;

  return a;
}

AST astCopyWhile(AST ast) {
  var a = initAST(ast.type);
  a.whileExpression = astCopy(ast.whileExpression);
  a.whileBody = astCopy(ast.whileBody);

  return a;
}

String astToString(AST ast) {
  switch (ast.type) {
    case ASTType.AST_OBJECT:
      return astObjectToString(ast);
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
        var str = ast.stringValue;
        return str;
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

String astObjectToString(AST ast) {
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
  return 'NULL';
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
