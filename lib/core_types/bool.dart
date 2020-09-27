import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Bool`s
ASTNode visitBoolProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'runtimeType':
        return StringNode()
          ..stringValue = left.boolVal.runtimeType.toString();
    default:
      throw NoSuchPropertyException(node.binaryOpRight.variableName, 'bool');
  }
}

/// Visits methods for `Bool`s
ASTNode visitBoolMethods(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'toString':
        return StringNode()..stringValue = left.boolVal.toString();
    default:
      throw NoSuchMethodException(node.binaryOpRight.funcCallExpression.variableName, 'bool');
  }
}
