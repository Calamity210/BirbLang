import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/exceptions.dart';

ASTNode visitListProperties(ASTNode node, ASTNode left) {
  final binaryOpRight = node.binaryOpRight;

  switch (binaryOpRight.variableName) {
    case 'first':
      return left.listElements.first;

    case 'isEmpty':
      return BoolNode()..boolVal = left.listElements.isEmpty;

    case 'isNotEmpty':
      return BoolNode()..boolVal = left.listElements.isNotEmpty;

    case 'last':
      return left.listElements.last;

    case 'length':
      return IntNode()..intVal = left.listElements.length;

    case 'reversed':
      return ListNode()..listElements = left.listElements.reversed.toList();

    case 'runtimeType':
      return StringNode()..stringValue = 'List';
  }

  throw NoSuchPropertyException(binaryOpRight.variableName, 'List');
}

/// Visits methods for `List`s
ASTNode visitListMethods(ASTNode node, ASTNode left) {
  final binaryOpRight = node.binaryOpRight;

  switch (binaryOpRight.funcCallExpression.variableName) {
    case 'append':
      expectArgs(binaryOpRight.functionCallArgs, [AnyNode]);
      return left..listElements.add(binaryOpRight.functionCallArgs[0]);

    case 'appendAll':
      expectArgs(binaryOpRight.functionCallArgs, [ListNode]);
      return left..listElements.addAll(binaryOpRight.functionCallArgs[0].listElements);

    case 'appendAt':
      final List<ASTNode> args = binaryOpRight.functionCallArgs;

      expectArgs(args, [IntNode, AnyNode]);

      final List elements = left.listElements;

      left.listElements = elements
          .getRange(0, args[0].intVal)
          .followedBy([args[1], ...elements.getRange(args[0].intVal, elements.length)]).toList();

      return left;

    case 'appendAllFrom':
      final List<ASTNode> args = binaryOpRight.functionCallArgs;

      expectArgs(args, [IntNode, ListNode]);

      return left..listElements.insertAll(0, args[0].listElements);

    case 'at':
      expectArgs(binaryOpRight.functionCallArgs, [IntNode]);

      return left.listElements.elementAt(binaryOpRight.functionCallArgs[0].intVal);

    case 'atRange':
      final List<ASTNode> args = binaryOpRight.functionCallArgs;

      expectArgs(args, [IntNode, IntNode]);

      return ListNode()..listElements = left.listElements.getRange(args[0].intVal, args[1].intVal).toList();

    case 'clear':
      return left..listElements.clear();

    case 'fillRange':
      final List<ASTNode> args = binaryOpRight.functionCallArgs;

      expectArgs(args, [IntNode, IntNode, AnyNode]);

      return left..listElements.fillRange(args[0].intVal, args[1].intVal, args[2]);

    case 'remove':
      expectArgs(binaryOpRight.functionCallArgs, [AnyNode]);
      return left..listElements.remove(binaryOpRight.functionCallArgs[0]);

    case 'removeAll':
      expectArgs(binaryOpRight.functionCallArgs, [ListNode]);

      for (int i = 0; i < binaryOpRight.functionCallArgs[0].listElements.length; i++)
        left.listElements.remove(binaryOpRight.functionCallArgs[i]);

      return left;

    case 'toMap':
      final Map map = {};

      for (int i = 0; i < left.listElements.length; i++)
        map['$i'] = left.listElements[i];

      return MapNode()..map = map;

    case 'toString':
      return StringNode()..stringValue = left.listElements.toString();

    case 'with':
      expectArgs(binaryOpRight.functionCallArgs, [ListNode]);
      return ListNode()..listElements = left.listElements.followedBy(binaryOpRight.functionCallArgs[0].listElements);

    default:
      throw NoSuchMethodException(binaryOpRight.funcCallExpression.variableName, 'List');
  }
}

ASTNode listEmpty(Runtime runtime, ASTNode self, List<ASTNode> args) {
  return ListNode()..listElements = List.empty();
}

ASTNode listFilled(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [IntNode, AnyNode]);

  return ListNode()..listElements = List.filled(args[0].intVal, args[1]);
}

