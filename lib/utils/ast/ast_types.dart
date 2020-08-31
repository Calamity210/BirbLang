
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/lexer/token.dart';
import 'package:Birb/utils/AST.dart';

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
  AST funcCallExpression;

  @override
  List funcCallArgs = [];

}

class FuncDefNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_FUNC_DEFINITION;

  @override
  String funcName;

  @override
  AST funcDefBody;

  @override
  AST funcDefType;

  @override
  List funcDefArgs = [];

  @override
  AstFuncPointer funcPointer;

  @override
  AstFutureFuncPointer futureFuncPointer;

  @override
  List compChildren = [];

}

class ClassNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_CLASS;

  @override
  List classChildren = [];

  @override
  List funcDefinitions = [];

  @override
  AST variableType;

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
  AST variableValue;

  @override
  AST variableType;

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
  AST variableValue;

  @override
  AST variableType;

  @override
  bool isFinal;

  @override
  Token binaryOperator;

  @override
  AST binaryOpLeft;

  @override
  AST binaryOpRight;

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
  AST variableValue;

  @override
  AST variableType;

  @override
  AST variableAssignmentLeft;

  @override
  bool isFinal;

  @override
  AST savedFuncCall;

}

class VarAssignmentNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_VARIABLE_ASSIGNMENT;

  @override
  String variableName;

  @override
  AST variableValue;

  @override
  AST variableType;

  @override
  AST variableAssignmentLeft;

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

  @override
  String stringValue = '0';

}

class DoubleNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_DOUBLE;

  @override
  double doubleVal = 0;

  @override
  int intVal = 0;

  @override
  String stringValue = '0.0';

}

class BoolNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_BOOL;

  @override
  bool boolVal = false;

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
  AST binaryOpLeft;

  @override
  AST binaryOpRight;

  @override
  Token binaryOperator;

}

class UnaryOpNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_UNARYOP;

  @override
  AST unaryOpRight;

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
  AST returnValue;

}

class ContinueNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_CONTINUE;

}

class TernaryNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_TERNARY;

  @override
  AST ternaryExpression;

  @override
  AST ternaryBody;

  @override
  AST ternaryElseBody;

}

class IfNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_IF;

  @override
  AST ifExpression;

  @override
  AST ifBody;

  @override
  AST ifElse;

}

class ElseNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ELSE;

  @override
  AST elseBody;

}

class SwitchNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_SWITCH;

  @override
  AST switchExpression;

  @override
  Map<AST, AST> switchCases;

  @override
  AST switchDefault;

}

class WhileNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_WHILE;

  @override
  AST whileExpression;

  @override
  AST whileBody;

}

class ForNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_FOR;

  @override
  AST forInitStatement;

  @override
  AST forConditionStatement;

  @override
  AST forChangeStatement;

  @override
  AST forBody;

}

class AttributeAccessNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ATTRIBUTE_ACCESS;

  @override
  List classChildren;

  @override
  AST binaryOpRight;

  @override
  AST binaryOpLeft;

  @override
  List enumElements;

}

class ListAccessNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_LIST_ACCESS;

  @override
  AST listAccessPointer;

  @override
  AST binaryOpLeft;

}

class IterateNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ITERATE;

  @override
  AST iterateIterable;

  @override
  AST iterateFunction;

}

class AssertNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ASSERT;

  @override
  AST assertExpression;

}

AST initAST(ASTType type) {
  if (type == ASTType.AST_COMPOUND) return CompoundNode();
  if (type == ASTType.AST_FUNC_CALL) return FuncCallNode();
  if (type == ASTType.AST_FUNC_DEFINITION) return FuncDefNode();
  if (type == ASTType.AST_CLASS) return ClassNode();
  if (type == ASTType.AST_ENUM) return EnumNode();
  if (type == ASTType.AST_LIST) return ListNode();
  if (type == ASTType.AST_MAP) return MapNode();
  if (type == ASTType.AST_VARIABLE) return VariableNode();
  if (type == ASTType.AST_VARIABLE_MODIFIER) return VarModNode();
  if (type == ASTType.AST_VARIABLE_DEFINITION) return VarDefNode();
  if (type == ASTType.AST_VARIABLE_ASSIGNMENT) return VarAssignmentNode();
  if (type == ASTType.AST_NULL) return NullNode();
  if (type == ASTType.AST_STRING) return StringNode();
  if (type == ASTType.AST_STRING_BUFFER) return StrBufferNode();
  if (type == ASTType.AST_INT) return IntNode();
  if (type == ASTType.AST_DOUBLE) return DoubleNode();
  if (type == ASTType.AST_BOOL) return BoolNode();
  if (type == ASTType.AST_ANY) return AnyNode();
  if (type == ASTType.AST_TYPE) return TypeNode();
  if (type == ASTType.AST_BINARYOP) return BinaryOpNode();
  if (type == ASTType.AST_UNARYOP) return UnaryOpNode();
  if (type == ASTType.AST_NOOP) return NoopNode();
  if (type == ASTType.AST_BREAK) return BreakNode();
  if (type == ASTType.AST_RETURN) return ReturnNode();
  if (type == ASTType.AST_CONTINUE) return ContinueNode();
  if (type == ASTType.AST_TERNARY) return TernaryNode();
  if (type == ASTType.AST_IF) return IfNode();
  if (type == ASTType.AST_ELSE) return ElseNode();
  if (type == ASTType.AST_SWITCH) return SwitchNode();
  if (type == ASTType.AST_WHILE) return WhileNode();
  if (type == ASTType.AST_FOR) return ForNode();
  if (type == ASTType.AST_ATTRIBUTE_ACCESS) return AttributeAccessNode();
  if (type == ASTType.AST_LIST_ACCESS) return ListAccessNode();
  if (type == ASTType.AST_ITERATE) return IterateNode();
  if (type == ASTType.AST_ASSERT) return AssertNode();
  return AST();
}