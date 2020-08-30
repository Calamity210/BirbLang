import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/exceptions.dart';

// TODO: (Calamity) work on list properties and methods
AST visitListProperties(AST node, AST left) {
  switch (node.binaryOpRight.variableName) {
    case 'length':
      AST intAST = initAST(ASTType.AST_INT)..intVal = left.listElements.length;
      return intAST;
  }

  throw NoSuchPropertyException(node.binaryOpRight.variableName, 'list');
}
