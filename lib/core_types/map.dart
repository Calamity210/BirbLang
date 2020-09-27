import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Map`s
ASTNode visitMapProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'runtimeType':
      {
        final StringNode stringAST = StringNode()
          ..stringValue = 'Map';
        return stringAST;
      }

    case 'isEmpty':
      {
        final ASTNode astBool = BoolNode()..boolVal = left.map.isEmpty;

        return astBool;
      }

    case 'isNotEmpty':
      {
        final ASTNode astBool = BoolNode()..boolVal = left.map.isNotEmpty;

        return astBool;
      }

    case 'length':
      {
        final ASTNode astInt = IntNode()..intVal = left.map.length;

        return astInt;
      }

    default:
      throw NoSuchPropertyException(node.binaryOpRight.variableName, 'Map');
  }
}

/// Visits methods for `Map`
ASTNode visitMapMethods(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'toString':
      {
        final ASTNode strAST = StringNode()..stringValue = left.map.toString();
        return strAST;
      }

    default:
      {
        throw NoSuchMethodException(node.binaryOpRight.funcCallExpression.variableName, 'Map');
      }
  }
}
