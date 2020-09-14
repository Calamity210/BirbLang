import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

ASTNode visitListProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'length':
      {
        final ASTNode intAST = IntNode()..intVal = left.listElements.length;
        return intAST;
      }

    case 'hashCode':
      {
        final ASTNode intAST = IntNode()..intVal = left.listElements.hashCode;
        return intAST;
      }

    case 'isEmpty':
      {
        final ASTNode boolAST = BoolNode()..boolVal = left.listElements.isEmpty;
        return boolAST;
      }

    case 'isNotEmpty':
      {
        final ASTNode boolAST = BoolNode()..boolVal = left.listElements.isNotEmpty;
        return boolAST;
      }

    case 'runtimeType':
      {
        final ASTNode stringAST = StringNode()
          ..stringValue = left.listElements.runtimeType.toString();
        return stringAST;
      }
  }

  throw NoSuchPropertyException(node.binaryOpRight.variableName, 'list');
}

/// Visits methods for `List`s
ASTNode visitListMethods(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'toString':
      {
        final ASTNode stringAST = StringNode()
          ..stringValue = left.listElements.toString();
        return stringAST;
      }
    default:
      {
        throw NoSuchMethodException(
            node.binaryOpRight.funcCallExpression.variableName, 'list');
      }
  }
}
