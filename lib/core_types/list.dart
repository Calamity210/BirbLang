import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

// TODO: (Calamity) work on list properties and methods
ASTNode visitListProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'length':
      ASTNode intAST = IntNode()..intVal = left.listElements.length;
      return intAST;
  }

  throw NoSuchPropertyException(node.binaryOpRight.variableName, 'list');
}
