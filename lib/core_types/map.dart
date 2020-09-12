import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Map`s
ASTNode visitMapProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'runtimeType':
      {
        StringNode stringAST = StringNode()
          ..stringValue = left.map.runtimeType.toString();
        return stringAST;
      }

    case 'isEmpty':
      {
        ASTNode astBool = BoolNode()..boolVal = left.map.isEmpty;

        return astBool;
      }

    case 'isNotEmpty':
      {
        ASTNode astBool = BoolNode()..boolVal = left.map.isNotEmpty;

        return astBool;
      }

    case 'length':
      {
        ASTNode astInt = IntNode()..intVal = left.map.length;

        return astInt;
      }

    case 'hashCode':
      {
        ASTNode astInt = IntNode()..intVal = left.map.hashCode;

        return astInt;
      }

    default:
      throw NoSuchPropertyException(node.binaryOpRight.variableName, 'map');
  }
}

/// Visits methods for `Map`
ASTNode visitMapMethods(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'toString':
      {
        ASTNode strAST = StringNode()..stringValue = left.map.toString();
        return strAST;
      }

    default:
      {
        throw NoSuchMethodException(
            node.binaryOpRight.funcCallExpression.variableName, 'StrBuffer');
      }
  }
}
