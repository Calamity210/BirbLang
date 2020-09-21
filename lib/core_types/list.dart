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
      runtimeExpectArgs(binaryOpRight.funcCallArgs, [ASTType.AST_ANY]);
      return left..listElements.add(binaryOpRight.funcCallArgs[0]);

    case 'appendAll':
      runtimeExpectArgs(binaryOpRight.funcCallArgs, [ASTType.AST_LIST]);
      return left..listElements.addAll(binaryOpRight.funcCallArgs[0].listElements);

    case 'appendAt':
      final List<ASTNode> args = binaryOpRight.funcCallArgs;

      runtimeExpectArgs(args, [ASTType.AST_INT, ASTType.AST_ANY]);

      return left..listElements.insert(0, args[0]);

    case 'appendAllFrom':
      final List<ASTNode> args = binaryOpRight.funcCallArgs;

      runtimeExpectArgs(args, [ASTType.AST_INT, ASTType.AST_LIST]);

      return left..listElements.insertAll(0, args[0].listElements);

    case 'at':
      runtimeExpectArgs(binaryOpRight.funcCallArgs, [ASTType.AST_INT]);

      return left.listElements.elementAt(binaryOpRight.funcCallArgs[0].intVal);
      
    case 'atRange':
      final List<ASTNode> args = binaryOpRight.funcCallArgs;

      runtimeExpectArgs(args, [ASTType.AST_INT, ASTType.AST_INT]);

      return ListNode()
        ..listElements = left.listElements.getRange(args[0].intVal, args[1].intVal).toList();
      
    case 'clear':
      return left..listElements.clear();

    case 'fillRange':
      final List<ASTNode> args = binaryOpRight.funcCallArgs;

      runtimeExpectArgs(args, [ASTType.AST_INT, ASTType.AST_INT, ASTType.AST_ANY]);

      return left..listElements.fillRange(args[0].intVal, args[1].intVal, args[2]);

    case 'remove':
      runtimeExpectArgs(binaryOpRight.funcCallArgs, [ASTType.AST_ANY]);
      return left..listElements.remove(binaryOpRight.funcCallArgs[0]);

    case 'removeAll':
      runtimeExpectArgs(binaryOpRight.funcCallArgs, [ASTType.AST_LIST]);

      for (int i = 0; i < binaryOpRight.funcCallArgs[0].listElements.length; i++)
      left.listElements.remove(binaryOpRight.funcCallArgs[i]);

      return left;

    case 'toMap':
      final Map map = {};

      for (int i = 0; i < left.listElements.length; i++)
        map['$i'] = left.listElements[i];

      return MapNode()..map = map;

    case 'toString':
      return StringNode()..stringValue = left.listElements.toString();

    case 'with':
      runtimeExpectArgs(binaryOpRight.funcCallArgs, [ASTType.AST_LIST]);
      return ListNode()..listElements = left.listElements.followedBy(binaryOpRight.funcCallArgs[0].listElements);

    default:
    throw NoSuchMethodException(binaryOpRight.funcCallExpression.variableName, 'List');
  }
}
