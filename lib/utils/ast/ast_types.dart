import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/lexer/token.dart';

class CompoundNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_COMPOUND;

  @override
  List<ASTNode> compoundValue = [];

  @override
  ASTNode copy() {
    CompoundNode node = CompoundNode()..scope = scope;

    compoundValue.forEach((child) {
      node.compoundValue.add(child?.copy());
    });

    return node;
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
  List<ASTNode> funcCallArgs = [];

  @override
  String variableName;

  @override
  ASTNode copy() {
    FuncCallNode node = FuncCallNode()
      ..scope = scope
      ..funcName = funcName
      ..funcCallExpression = (funcCallExpression?.copy())
      ..variableName = variableName;

    funcCallArgs.forEach((child) {
      node.funcCallArgs.add(child?.copy());
    });

    return node;
  }
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
  List<ASTNode> funcDefArgs = [];

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
    FuncDefNode node = FuncDefNode()
      ..scope = scope
      ..funcName = funcName
      ..funcDefBody = (funcDefBody?.copy())
      ..funcDefType = (funcDefType?.copy())
      ..funcDefArgs = []
      ..funcPointer = funcPointer
      ..futureFuncPointer = futureFuncPointer
      ..compChildren = []
      ..isSuperseding = isSuperseding;

    funcDefArgs.forEach((child) {
      node.funcDefArgs.add(child?.copy());
    });

    compChildren.forEach((child) {
      node.compChildren.add(child?.copy());
    });

    return node;
  }
}

class ClassNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_CLASS;

  @override
  String className;

  @override
  List<ASTNode> classChildren = [];

  @override
  ASTNode superClass;

  @override
  List funcDefinitions = [];

  @override
  ASTNode variableType;

  @override
  ASTNode copy() {
    ClassNode node = ClassNode()
      ..scope = scope
      ..className = className
      ..superClass = (superClass?.copy())
      ..variableType = (variableType?.copy());

    classChildren.forEach((child) {
      ASTNode copyChild = child?.copy();
      node.classChildren.add(copyChild);
    });

    classChildren.forEach((child) {
      child.parent = node;
    });

    funcDefinitions.forEach((child) {
      node.funcDefinitions.add(child?.copy());
    });
    return node;
  }
}

class EnumNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_ENUM;

  @override
  List<ASTNode> enumElements = [];

  @override
  ASTNode copy() {
    EnumNode node = EnumNode()..scope = scope;

    enumElements.forEach((child) {
      node.enumElements.add(child?.copy());
    });

    return node;
  }
}

class ListNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_LIST;

  @override
  List listElements = [];

  @override
  List funcDefinitions = [];

  @override
  ASTNode copy() {
    ListNode node = ListNode()..scope = scope;

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
}

class MapNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_MAP;

  @override
  Map<String, dynamic> map = {};

  @override
  List funcDefinitions = [];

  @override
  ASTNode copy() {
    MapNode node = MapNode()..scope = scope;

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
  List<ASTNode> classChildren = [];

  @override
  List<ASTNode> enumElements = [];

  @override
  ASTNode copy() {
    var copyType;

    if (variableType != null) copyType = variableType.copy();

    VariableNode node = VariableNode()
      ..scope = scope
      ..variableType = copyType
      ..variableValue = (variableValue?.copy())
      ..variableName = variableName;

    classChildren.forEach((element) => node.classChildren.add(element?.copy()));
    enumElements.forEach((element) => node.enumElements.add(element?.copy()));

    return node;
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
  List<ASTNode> classChildren = [];

  @override
  List<ASTNode> enumElements = [];

  @override
  ASTNode copy() {
    VarModNode node = VarModNode()
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
  ASTNode savedFuncCall;

  @override
  bool isSuperseding;

  @override
  ASTNode copy() {
    VarDefNode node = VarDefNode()
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
  List<ASTNode> classChildren = [];

  @override
  ASTNode copy() {
    VarAssignmentNode node = VarAssignmentNode()
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

class NullNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_NULL;

  @override
  ASTNode copy() => NullNode();
}

class StringNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_STRING;

  @override
  String stringValue = '';

  @override
  ASTNode copy() {
    StringNode node = StringNode()..scope = scope..stringValue = stringValue;
    return node;
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
    StrBufferNode node = StrBufferNode()..scope = scope..strBuffer = strBuffer;

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
  int intVal = 0;

  @override
  double doubleVal = 0;

  @override
  ASTNode copy() {
    IntNode node = IntNode()
      ..scope = scope
      ..intVal = intVal
      ..doubleVal = doubleVal;

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
  double doubleVal = 0;

  @override
  int intVal = 0;

  @override
  ASTNode copy() {
    DoubleNode node = DoubleNode()
      ..scope = scope
      ..intVal = intVal
      ..doubleVal = doubleVal;

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
    BoolNode node = BoolNode()
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
    BinaryOpNode node = BinaryOpNode()
      ..scope = scope
      ..binaryOperator = binaryOperator
      ..binaryOpLeft = (binaryOpLeft?.copy())
      ..binaryOpRight = (binaryOpRight?.copy());

    return node;
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
    UnaryOpNode node = UnaryOpNode()
      ..scope = scope
      ..unaryOperator = unaryOperator
      ..unaryOpRight = (unaryOpRight?.copy());

    return node;
  }
}

class NoopNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_NOOP;

  @override
  ASTNode copy() => NoopNode();
}

class NewNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_NEW;

  @override
  ASTNode newValue;

  @override
  ASTNode copy() {
    NewNode node = NewNode()..scope = scope..newValue = (newValue?.copy());

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
    ReturnNode node = ReturnNode()..scope = scope..returnValue = (returnValue?.copy());

    return node;
  }
}

class ThrowNode extends ASTNode {
  @override
  ASTType type = ASTType.AST_THROW;

  @override
  ASTNode throwValue;

  @override
  ASTNode copy() {
    ThrowNode node = ThrowNode()..scope = scope..throwValue = (throwValue?.copy());

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
    TernaryNode node = TernaryNode()
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
    IfNode node = IfNode()
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
    ElseNode node = ElseNode()..scope = scope..elseBody = (elseBody?.copy());

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
    SwitchNode node = SwitchNode()
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
    WhileNode node = WhileNode()
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
    ForNode node = ForNode()
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
  List<ASTNode> classChildren = [];

  @override
  ASTNode binaryOpRight;

  @override
  ASTNode binaryOpLeft;

  @override
  List<ASTNode> enumElements = [];

  @override
  ASTNode copy() {
    AttributeAccessNode node = AttributeAccessNode()
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
    ListAccessNode node = ListAccessNode()
      ..scope = scope
      ..listAccessPointer = (listAccessPointer?.copy())
      ..binaryOpLeft = (binaryOpLeft?.copy());

    return node;
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
    IterateNode node = IterateNode()
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
    AssertNode node = AssertNode()
      ..scope = scope
      ..assertExpression = (assertExpression?.copy());

    return node;
  }
}
