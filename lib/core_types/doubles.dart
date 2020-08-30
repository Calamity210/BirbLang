import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Doubles`s
AST visitDoubleProperties(AST node, AST left) {
  switch (node.binaryOpRight.variableName) {
    case 'isFinite':
      {
        AST boolAST = initAST(ASTType.AST_BOOL)
          ..boolVal = left.doubleVal.isFinite;
        return boolAST;
      }

    case 'isInfinite':
      {
        AST boolAST = initAST(ASTType.AST_BOOL)
          ..boolVal = left.doubleVal.isInfinite;
        return boolAST;
      }

    case 'isNaN':
      {
        AST boolAST = initAST(ASTType.AST_BOOL)..boolVal = left.intVal.isNaN;
        return boolAST;
      }

    case 'isNegative':
      {
        AST boolAST = initAST(ASTType.AST_BOOL)
          ..boolVal = left.doubleVal.isNegative;
        return boolAST;
      }

    case 'hashCode':
      {
        AST intAST = initAST(ASTType.AST_INT)
          ..intVal = left.doubleVal.hashCode;
        return intAST;
      }

    case 'sign':
      {
        AST doubleAST = initAST(ASTType.AST_DOUBLE)
          ..doubleVal = left.doubleVal.sign;
        return doubleAST;
      }
  }

  throw NoSuchPropertyException(node.binaryOpRight.variableName, 'double');
}
