
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/lexer/token.dart';

class CompoundNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_COMPOUND;

  @override
  List compoundValue = [];

}

class FuncCallNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_FUNC_CALL;

  @override
  String funcName;

  @override
  ASTNode funcCallExpression;

  @override
  List funcCallArgs = [];

  @override
  String variableName;

}

class FuncDefNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_FUNC_DEFINITION;

  @override
  String funcName;

  @override
  ASTNode funcDefBody;

  @override
  ASTNode funcDefType;

  @override
  List funcDefArgs = [];

  @override
  AstFuncPointer funcPointer;

  @override
  AstFutureFuncPointer futureFuncPointer;

  @override
  List compChildren = [];

  @override
  bool isSuperseding;

}

class ClassNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_CLASS;

  @override
  String className;

  @override
  List classChildren = [];

  @override
  ASTNode superClass;

  @override
  List funcDefinitions = [];

  @override
  ASTNode variableType;

}

class EnumNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ENUM;

  @override
  List enumElements = [];

}

class ListNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_LIST;

  @override
  List listElements = [];

  @override
  List funcDefinitions = [];

}

class MapNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_MAP;

  @override
  Map<String, dynamic> map = {};

  @override
  List funcDefinitions = [];

}

class VariableNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_VARIABLE;

  @override
  String variableName;

  @override
  ASTNode variableValue;

  @override
  ASTNode variableType;

  @override
  bool isFinal;

  @override
  List classChildren = [];

  @override
  List enumElements = [];

}

class VarModNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_VARIABLE_MODIFIER;

  @override
  String variableName;

  @override
  ASTNode variableValue;

  @override
  ASTNode variableType;

  @override
  bool isFinal;

  @override
  Token binaryOperator;

  @override
  ASTNode binaryOpLeft;

  @override
  ASTNode binaryOpRight;

  @override
  List classChildren = [];

  @override
  List enumElements = [];

}

class VarDefNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_VARIABLE_DEFINITION;

  @override
  String variableName;

  @override
  ASTNode variableValue;

  @override
  ASTNode variableType;

  @override
  ASTNode variableAssignmentLeft;

  @override
  bool isFinal;

  @override
  ASTNode savedFuncCall;

  @override
  bool isSuperseding;

}

class VarAssignmentNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_VARIABLE_ASSIGNMENT;

  @override
  String variableName;

  @override
  ASTNode variableValue;

  @override
  ASTNode variableType;

  @override
  ASTNode variableAssignmentLeft;

  @override
  bool isFinal;

  @override
  List classChildren = [];

}

class NullNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_NULL;

}

class StringNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_STRING;

  @override
  String stringValue = '';

}

class StrBufferNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_STRING_BUFFER;

  @override
  StringBuffer strBuffer = StringBuffer();

  @override
  bool isFinal;

}

class IntNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_INT;

  @override
  int intVal = 0;

  @override
  double doubleVal = 0;

}

class DoubleNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_DOUBLE;

  @override
  double doubleVal = 0;

  @override
  int intVal = 0;

}

class BoolNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_BOOL;

  @override
  bool boolVal = false;

  @override
  int intVal = 0;

}

class AnyNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ANY;

}

class TypeNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_TYPE;

}

class BinaryOpNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_BINARYOP;

  @override
  ASTNode binaryOpLeft;

  @override
  ASTNode binaryOpRight;

  @override
  Token binaryOperator;

}

class UnaryOpNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_UNARYOP;

  @override
  ASTNode unaryOpRight;

  @override
  Token unaryOperator;

}

class NoopNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_NOOP;

}

class BreakNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_BREAK;

}

class ReturnNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_RETURN;

  @override
  ASTNode returnValue;

}

class ThrowNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_THROW;

  @override
  VariableNode throwValue;

}

class ContinueNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_CONTINUE;

}

class TernaryNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_TERNARY;

  @override
  ASTNode ternaryExpression;

  @override
  ASTNode ternaryBody;

  @override
  ASTNode ternaryElseBody;

}

class IfNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_IF;

  @override
  ASTNode ifExpression;

  @override
  ASTNode ifBody;

  @override
  ASTNode ifElse;

  @override
  ASTNode elseBody;

}

class ElseNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ELSE;

  @override
  ASTNode elseBody;

}

class SwitchNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_SWITCH;

  @override
  ASTNode switchExpression;

  @override
  Map<ASTNode, ASTNode> switchCases;

  @override
  ASTNode switchDefault;

}

class WhileNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_WHILE;

  @override
  ASTNode whileExpression;

  @override
  ASTNode whileBody;

}

class ForNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_FOR;

  @override
  ASTNode forInitStatement;

  @override
  ASTNode forConditionStatement;

  @override
  ASTNode forChangeStatement;

  @override
  ASTNode forBody;

}

class AttributeAccessNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ATTRIBUTE_ACCESS;

  @override
  List classChildren;

  @override
  ASTNode binaryOpRight;

  @override
  ASTNode binaryOpLeft;

  @override
  List enumElements;

}

class ListAccessNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_LIST_ACCESS;

  @override
  ASTNode listAccessPointer;

  @override
  ASTNode binaryOpLeft;

}

class IterateNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ITERATE;

  @override
  ASTNode iterateIterable;

  @override
  ASTNode iterateFunction;

}

class AssertNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ASSERT;

  @override
  ASTNode assertExpression;

}

