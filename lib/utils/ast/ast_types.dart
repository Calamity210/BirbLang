import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/AST.dart';

class CompoundNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_COMPOUND;

  @override
  var compoundValue = [];

}

class FuncCallNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_FUNC_CALL;

  @override
  var funcName;

  @override
  var funcCallArgs = [];

}

class FuncDefNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_FUNC_DEFINITION;

  @override
  var funcName;

  @override
  var funcDefBody;

  @override
  var funcDefType;

  @override
  var funcDefArgs = [];

  @override
  var funcPointer;

  @override
  var futureFuncPointer;

  @override
  var compChildren = [];

}

class ClassNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_CLASS;

  @override
  var classChildren = [];

}

class EnumNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ENUM;

  @override
  var enumElements = [];

}

class ListNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_LIST;

  @override
  var listElements = [];

}

class MapNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_MAP;

  @override
  var map = {};

}

class VariableNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_VARIABLE;

  @override
  var variableName;

  @override
  var variableValue;

  @override
  var variableType;

  @override
  var isFinal;

}

class VarDefNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_VARIABLE_DEFINITION;

  @override
  var variableName;

  @override
  var variableValue;

  @override
  var variableType;

  @override
  var variableAssignmentLeft;

  @override
  var isFinal;

  @override
  var savedFuncCall;

}

class VarAssignmentNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_VARIABLE_ASSIGNMENT;

  @override
  var variableName;

  @override
  var variableValue;

  @override
  var variableType;

  @override
  var variableAssignmentLeft;

  @override
  var isFinal;

}

class NullNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_NULL;

}

class StringNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_STRING;

  @override
  var stringValue;

}

class StrBufferNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_STRING_BUFFER;

  @override
  var strBuffer;

}

class IntNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_INT;

  @override
  var intVal = 0;

  @override
  var doubleVal = 0;

}

class DoubleNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_DOUBLE;

  @override
  var doubleVal = 0;

  @override
  var intVal = 0;

}

class BoolNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_BOOL;

  @override
  var boolVal = false;

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
  var binaryOpLeft;

  @override
  var binaryOpRight;

  @override
  var binaryOperator;

}

class UnaryOpNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_UNARYOP;

  @override
  var unaryOpRight;

  @override
  var unaryOperator;

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
  var returnValue;

}

class ContinueNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_CONTINUE;

}

class TernaryNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_TERNARY;

  @override
  var ternaryExpression;

  @override
  var ternaryBody;

  @override
  var ternaryElseBody;

}

class IfNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_IF;

  @override
  var ifExpression;

  @override
  var ifBody;

  @override
  var ifElse;

}

class ElseNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ELSE;

  @override
  var elseBody;

}

class SwitchNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_SWITCH;

  @override
  var switchExpression;

  @override
  var switchCases;

  @override
  var switchDefault;

}

class WhileNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_WHILE;

  @override
  var whileExpression;

  @override
  var whileBody;

}

class ForNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_FOR;

  @override
  var forInitStatement;

  @override
  var forConditionStatement;

  @override
  var forChangeStatement;

  @override
  var forBody;

}

class AttributeAccessNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ATTRIBUTE_ACCESS;

  @override
  var classChildren;

  @override
  var binaryOpRight;

  @override
  var binaryOpLeft;

  @override
  var enumElements;

}

class ListAccessNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_LIST_ACCESS;

  @override
  var listAccessPointer;

}

class IterateNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ITERATE;

  @override
  var iterateIterable;

  @override
  var iterateFunction;

}

class AssertNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ASSERT;

  @override
  var assertExpression;

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