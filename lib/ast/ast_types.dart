import 'dart:collection';

import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/lexer/token.dart';
import 'package:Birb/runtime/runtime.dart';

class CompoundNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_COMPOUND;

  @override
  List<ASTNode> compoundValue = [];

  @override
  ASTNode copy() {
    final CompoundNode node = CompoundNode()..scope = scope;

    compoundValue.forEach((child) {
      node.compoundValue.add(child?.copy());
    });

    return node;
  }

  @override
  String toString() {
    super.toString();
    return '{ compound }';
  }
}

class FuncCallNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_FUNC_CALL;

  @override
  String funcName;

  @override
  ASTNode funcCallExpression;

  @override
  List<ASTNode> functionCallArgs = [];

  @override
  List<ASTNode> namedFunctionCallArgs = [];

  @override
  String variableName;

  @override
  ASTNode copy() {
    final FuncCallNode node = FuncCallNode()
      ..scope = scope
      ..funcName = funcName
      ..funcCallExpression = (funcCallExpression?.copy())
      ..variableName = variableName;

    functionCallArgs.forEach((child) {
      node.functionCallArgs.add(child?.copy());
    });

    return node;
  }

  @override
  String toString() {
    super.toString();

    return '${funcCallExpression.toString()}(${functionCallArgs.length})';
  }
}

class FuncDefNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_FUNC_DEFINITION;

  @override
  String funcName;

  @override
  ASTNode functionDefBody;

  @override
  ASTNode funcDefType;

  @override
  List<ASTNode> functionDefArgs = [];

  @override
  List<ASTNode> namedFunctionDefArgs = [];

  @override
  AstFuncPointer funcPointer;

  @override
  AstFutureFuncPointer futureFuncPointer;

  @override
  List<ASTNode> compChildren = [];

  @override
  bool isSuperseding;

  @override
  ASTNode copy() {
    final FuncDefNode node = FuncDefNode()
      ..scope = scope
      ..funcName = funcName
      ..functionDefBody = (functionDefBody?.copy())
      ..funcDefType = (funcDefType?.copy())
      ..functionDefArgs = []
      ..funcPointer = funcPointer
      ..futureFuncPointer = futureFuncPointer
      ..compChildren = []
      ..isSuperseding = isSuperseding;

    functionDefArgs.forEach((child) {
      node.functionDefArgs.add(child?.copy());
    });

    compChildren.forEach((child) {
      node.compChildren.add(child?.copy());
    });

    return node;
  }

  @override
  String toString() {
    super.toString();

    return '$funcName (${functionDefArgs.length})';
  }
}

class ClassNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_CLASS;

  @override
  String className;

  @override
  ListQueue<ASTNode> classChildren = ListQueue();

  @override
  ASTNode superClass;

  @override
  ASTNode variableType;

  @override
  ASTNode copy() {
    final ClassNode node = ClassNode()
      ..scope = scope
      ..className = className
      ..superClass = (superClass?.copy())
      ..variableType = (variableType?.copy());

    classChildren.forEach((child) {
      final ASTNode copyChild = child?.copy();
      node.classChildren.add(copyChild);
    });

    classChildren.forEach((child) {
      child.parent = node;
    });

    return node;
  }

  @override
  String toString() {
    super.toString();
    return '{ class }';
  }
}

class EnumNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ENUM;

  @override
  List<ASTNode> enumElements = [];

  @override
  ASTNode copy() {
    final EnumNode node = EnumNode()..scope = scope;

    enumElements.forEach((child) {
      node.enumElements.add(child?.copy());
    });

    return node;
  }

  @override
  String toString() {
    super.toString();

    String enumStr = 'enum {\n';
    enumElements.forEach((element) => enumStr += ' ${element.toString()},\n');
    enumStr += '}';

    return enumStr;
  }
}

class ListNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_LIST;

  @override
  List listElements;

  @override
  List funcDefinitions = [];

  @override
  ASTNode copy() {
    final ListNode node = ListNode()..scope = scope;

    listElements.forEach((child) {
      if (child is ASTNode)
        node.listElements.add(child?.copy());
      else
        node.listElements.add(child);
    });

    funcDefinitions.forEach((child) {
      node.funcDefinitions.add(child?.copy());
    });

    return node;
  }

  @override
  String toString() {
    super.toString();

    return listElements.toString();
  }
}

class MapNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_MAP;

  @override
  Map<String, dynamic> map;

  @override
  List funcDefinitions = [];

  @override
  ASTNode copy() {
    final MapNode node = MapNode()..scope = scope;

    map.forEach((key, val) {
      if (val is ASTNode)
        node.map[key] = val.copy();
      else
        node.map[key] = val;
    });

    funcDefinitions.forEach((child) {
      node.funcDefinitions.add(child?.copy());
    });

    return node;
  }

  @override
  String toString() {
    super.toString();

    return map.toString();
  }
}

class VariableNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_VARIABLE;

  @override
  ASTNode ast;

  @override
  String variableName;

  @override
  ASTNode variableValue;

  @override
  ASTNode variableType;

  @override
  bool isFinal;

  @override
  ListQueue<ASTNode> classChildren = ListQueue();

  @override
  List<ASTNode> enumElements = [];

  @override
  ASTNode copy() {
    TypeNode copyType;

    if (variableType != null)
      copyType = variableType.copy();

    final VariableNode node = VariableNode()
      ..scope = scope
      ..variableType = copyType
      ..variableValue = (variableValue?.copy())
      ..variableName = variableName;

    classChildren.forEach((element) => node.classChildren.add(element?.copy()));
    enumElements.forEach((element) => node.enumElements.add(element?.copy()));

    return node;
  }

  @override
  String toString() {
    super.toString();
    return variableName;
  }
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
  ListQueue<ASTNode> classChildren = ListQueue();

  @override
  List<ASTNode> enumElements = [];

  @override
  ASTNode copy() {
    final VarModNode node = VarModNode()
      ..scope = scope
      ..variableName = variableName
      ..variableValue = (variableValue?.copy())
      ..variableType = (variableType?.copy())
      ..binaryOperator = binaryOperator
      ..binaryOpLeft = (binaryOpLeft?.copy())
      ..binaryOpRight = (binaryOpRight?.copy());

    classChildren.forEach((child) {
      node.classChildren.add(child?.copy());
    });

    enumElements.forEach((child) {
      node.enumElements.add(child?.copy());
    });

    return node;
  }
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
  bool isNullable = false;

  @override
  ASTNode savedFuncCall;

  @override
  bool isSuperseding;

  @override
  ASTNode copy() {
    final VarDefNode node = VarDefNode()
      ..scope = scope
      ..savedFuncCall = (savedFuncCall?.copy())
      ..variableAssignmentLeft = (variableAssignmentLeft?.copy())
      ..isSuperseding = isSuperseding
      ..variableValue = (variableValue?.copy())
      ..variableType = (variableType?.copy())
      ..variableName = variableName;

    return node;
  }

  @override
  String toString() {
    super.toString();
    return variableValue.toString();
  }
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
  ListQueue<ASTNode> classChildren = ListQueue();

  @override
  ASTNode copy() {
    final VarAssignmentNode node = VarAssignmentNode()
      ..scope = scope
      ..variableName = variableName
      ..variableValue = (variableValue?.copy())
      ..variableType = (variableType?.copy())
      ..variableAssignmentLeft = (variableAssignmentLeft?.copy());

    classChildren.forEach((child) {
      node.classChildren.add(child?.copy());
    });

    return node;
  }

}

class NoSeebNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_NULL;

  @override
  ASTNode copy() => NoSeebNode();

  @override
  String toString() {
    super.toString();

    return 'noSeeb';
  }
}

class StringNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_STRING;

  @override
  String stringValue;

  @override
  ASTNode copy() {
    return StringNode()..scope = scope..stringValue = stringValue;
  }

  @override
  String toString() {
    super.toString();
   return stringValue;
  }
}

class StrBufferNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_STRING_BUFFER;

  @override
  StringBuffer strBuffer = StringBuffer();

  @override
  bool isFinal;

  @override
  ASTNode copy() {
    final StrBufferNode node = StrBufferNode()..scope = scope..strBuffer = strBuffer;

    return node;
  }

  @override
  String toString() {
    super.toString();
    return strBuffer.toString();
  }
}

class IntNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_INT;

  @override
  int intVal;

  @override
  ASTNode copy() {
    final IntNode node = IntNode()
      ..scope = scope
      ..intVal = intVal;

    return node;
  }

  @override
  String toString() {
    super.toString();
    return intVal.toString();
  }
}

class DoubleNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_DOUBLE;

  @override
  double doubleVal;

  @override
  ASTNode copy() {
    final DoubleNode node = DoubleNode()
      ..scope = scope
      ..intVal = intVal;

    return node;
  }

  @override
  String toString() {
    super.toString();
    return doubleVal.toString();
  }
}

class BoolNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_BOOL;

  @override
  bool boolVal = false;

  @override
  int intVal = 0;

  @override
  ASTNode copy() {
    final BoolNode node = BoolNode()
      ..scope = scope
      ..boolVal = boolVal
      ..intVal = intVal;

    return node;
  }

  @override
  String toString() {
    super.toString();

    return boolVal.toString();
  }
}

class AnyNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ANY;

  @override
  ASTNode copy() => AnyNode();
}

class TypeNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_TYPE;

  @override
  ASTNode copy() => TypeNode();

  @override
  String toString() {
    super.toString();
    return '< Type >';
  }
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

  @override
  ASTNode copy() {
    final BinaryOpNode node = BinaryOpNode()
      ..scope = scope
      ..binaryOperator = binaryOperator
      ..binaryOpLeft = (binaryOpLeft?.copy())
      ..binaryOpRight = (binaryOpRight?.copy());

    return node;
  }

  @override
  String toString() {
    super.toString();

    ASTNode visitedBiOp;
    visitBinaryOp(Runtime(null), this).then((value) => visitedBiOp = value);
    return visitedBiOp.toString();
  }
}

class UnaryOpNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_UNARYOP;

  @override
  ASTNode unaryOpRight;

  @override
  Token unaryOperator;

  @override
  ASTNode copy() {
    final UnaryOpNode node = UnaryOpNode()
      ..scope = scope
      ..unaryOperator = unaryOperator
      ..unaryOpRight = (unaryOpRight?.copy());

    return node;
  }

  @override
  String toString() {
    super.toString();

    ASTNode visitedUnaryOp;
    visitUnaryOp(Runtime(null), this).then((value) => visitedUnaryOp = value);
    return visitedUnaryOp.toString();
  }
}

class NoopNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_NOOP;

  @override
  ASTNode copy() => NoopNode();

  @override
  String toString() {
    super.toString();
    return '{ NO-OP }';
  }
}

class NewNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_NEW;

  @override
  ASTNode newValue;

  @override
  ASTNode copy() {
    final NewNode node = NewNode()..scope = scope..newValue = (newValue?.copy());

    return node;
  }
}

class BreakNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_BREAK;

  @override
  ASTNode copy() => BreakNode();
}

class ReturnNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_RETURN;

  @override
  ASTNode returnValue;

  @override
  ASTNode copy() {
    final ReturnNode node = ReturnNode()..scope = scope..returnValue = (returnValue?.copy());

    return node;
  }

  @override
  String toString() {
    super.toString();
    return returnValue.toString();
  }
}

class ThrowNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_THROW;

  @override
  ASTNode throwValue;

  @override
  ASTNode copy() {
    final ThrowNode node = ThrowNode()..scope = scope..throwValue = (throwValue?.copy());

    return node;
  }
}

class NextNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_NEXT;

  @override
  ASTNode copy() => NextNode();
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

  @override
  ASTNode copy() {
    final TernaryNode node = TernaryNode()
      ..scope = scope
      ..ternaryExpression = (ternaryExpression?.copy())
      ..ternaryBody = (ternaryBody?.copy())
      ..ternaryElseBody = (ternaryElseBody?.copy());

    return node;
  }

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

  @override
  ASTNode copy() {
    final IfNode node = IfNode()
      ..scope = scope
      ..ifExpression = (ifExpression?.copy())
      ..ifBody = (ifBody?.copy())
      ..ifElse = (ifElse?.copy())
      ..elseBody = (elseBody?.copy());

    return node;
  }
}

class ElseNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ELSE;

  @override
  ASTNode elseBody;

  @override
  ASTNode copy() {
    final ElseNode node = ElseNode()..scope = scope..elseBody = (elseBody?.copy());

    return node;
  }
}

class SwitchNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_SWITCH;

  @override
  ASTNode switchExpression;

  @override
  Map<ASTNode, ASTNode> switchCases = {};

  @override
  ASTNode switchDefault;

  @override
  ASTNode copy() {
    final SwitchNode node = SwitchNode()
      ..scope = scope
      ..switchExpression = (switchExpression?.copy())
      ..switchDefault = (switchDefault?.copy());

    switchCases.forEach((key, val) {
      node.switchCases[key.copy()] = val.copy();
    });

    return node;
  }
}

class WhileNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_WHILE;

  @override
  ASTNode whileExpression;

  @override
  ASTNode whileBody;

  @override
  ASTNode copy() {
    final WhileNode node = WhileNode()
      ..scope = scope
      ..whileExpression = (whileExpression?.copy())
      ..whileBody = (whileBody?.copy());

    return node;
  }
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

  @override
  ASTNode copy() {
    final ForNode node = ForNode()
      ..scope = scope
      ..forInitStatement = (forInitStatement?.copy())
      ..forConditionStatement = (forConditionStatement?.copy())
      ..forChangeStatement = (forChangeStatement?.copy())
      ..forBody = (forBody?.copy());

    return node;
  }
}

class AttributeAccessNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ATTRIBUTE_ACCESS;

  @override
  ListQueue<ASTNode> classChildren = ListQueue();

  @override
  ASTNode binaryOpRight;

  @override
  ASTNode binaryOpLeft;

  @override
  List<ASTNode> enumElements = [];

  @override
  ASTNode copy() {
    final AttributeAccessNode node = AttributeAccessNode()
      ..scope = scope
      ..binaryOpLeft = (binaryOpLeft?.copy())
      ..binaryOpRight = (binaryOpRight?.copy());

    classChildren.forEach((child) {
      node.classChildren.add(child.copy());
    });

    enumElements.forEach((child) {
      node.enumElements.add(child.copy());
    });

    return node;
  }

  @override
  String toString() {
    super.toString();
    return '${binaryOpLeft.toString()}.${binaryOpRight.toString()}';
  }
}

class ListAccessNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_LIST_ACCESS;

  @override
  ASTNode listAccessPointer;

  @override
  ASTNode binaryOpLeft;

  @override
  ASTNode copy() {
    final ListAccessNode node = ListAccessNode()
      ..scope = scope
      ..listAccessPointer = (listAccessPointer?.copy())
      ..binaryOpLeft = (binaryOpLeft?.copy());

    return node;
  }

  @override
  String toString() {
    super.toString();
    return 'list[access]';
  }
}

class IterateNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ITERATE;

  @override
  ASTNode iterateIterable;

  @override
  ASTNode iterateFunction;

  @override
  ASTNode copy() {
    final IterateNode node = IterateNode()
      ..scope = scope
      ..iterateIterable = (iterateIterable?.copy())
      ..iterateFunction = (iterateFunction?.copy());

    return node;
  }
}

class AssertNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ASSERT;

  @override
  ASTNode assertExpression;

  @override
  ASTNode copy() {
    final AssertNode node = AssertNode()
      ..scope = scope
      ..assertExpression = (assertExpression?.copy());

    return node;
  }
}
