import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

ASTNode visitListProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'length':
      {
        ASTNode intAST = IntNode()..intVal = left.listElements.length;
        return intAST;
      }

    case 'hashCode':
      {
        ASTNode intAST = IntNode()..intVal = left.listElements.hashCode;
        return intAST;
      }

    case 'isEmpty':
      {
        ASTNode boolAST = BoolNode()..boolVal = left.listElements.isEmpty;
        return boolAST;
      }

    case 'isNotEmpty':
      {
        ASTNode boolAST = BoolNode()..boolVal = left.listElements.isNotEmpty;
        return boolAST;
      }

    case 'runtimeType':
      {
        ASTNode stringAST = StringNode()
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
        ASTNode stringAST = StringNode()
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
