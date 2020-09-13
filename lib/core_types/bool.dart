import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Bool`s
ASTNode visitBoolProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'runtimeType':
      {
        final StringNode stringAST = StringNode()
          ..stringValue = left.boolVal.runtimeType.toString();
        return stringAST;
      }
    default:
  }
}

/// Visits methods for `Bool`s
ASTNode visitBoolMethods(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'toString':
      {
        final StringNode stringAST = StringNode()
          ..stringValue = left.boolVal.toString();
        return stringAST;
      }
    default:
  }
}
