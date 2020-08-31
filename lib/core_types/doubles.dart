import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Doubles`s
AST visitDoubleProperties(AST node, AST left) {
  switch (node.binaryOpRight.variableName) {
    case 'isFinite':
      {
        AST boolAST = BoolNode()
          ..boolVal = left.doubleVal.isFinite;
        return boolAST;
      }

    case 'isInfinite':
      {
        AST boolAST = BoolNode()
          ..boolVal = left.doubleVal.isInfinite;
        return boolAST;
      }

    case 'isNaN':
      {
        AST boolAST = BoolNode()..boolVal = left.intVal.isNaN;
        return boolAST;
      }

    case 'isNegative':
      {
        AST boolAST = BoolNode()
          ..boolVal = left.doubleVal.isNegative;
        return boolAST;
      }

    case 'hashCode':
      {
        AST intAST = IntNode()
          ..intVal = left.doubleVal.hashCode;
        return intAST;
      }

    case 'sign':
      {
        AST doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.sign;
        return doubleAST;
      }
  }

  throw NoSuchPropertyException(node.binaryOpRight.variableName, 'double');
}
