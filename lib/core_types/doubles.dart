import 'package:Birb/utils/AST.dart';

/// Visits properties for `Doubles`s
AST visitDoubleProperties(AST node, AST left) {
  switch (node.binaryOpRight.variableName) {
    case 'isFinite':
      {
        AST boolAST = initAST(ASTType.AST_BOOL)
          ..boolValue = left.doubleValue.isFinite;
        return boolAST;
      }

    case 'isInfinite':
      {
        AST boolAST = initAST(ASTType.AST_BOOL)
          ..boolValue = left.doubleValue.isInfinite;
        return boolAST;
      }

    case 'isNaN':
      {
        AST boolAST = initAST(ASTType.AST_BOOL)..boolValue = left.intVal.isNaN;
        return boolAST;
      }

    case 'isNegative':
      {
        AST boolAST = initAST(ASTType.AST_BOOL)
          ..boolValue = left.doubleValue.isNegative;
        return boolAST;
      }

    case 'hashCode':
      {
        AST intAST = initAST(ASTType.AST_INT)
          ..intVal = left.doubleValue.hashCode;
        return intAST;
      }

    case 'sign':
      {
        AST doubleAST = initAST(ASTType.AST_INT)
          ..doubleValue = left.doubleValue.sign;
        return doubleAST;
      }
  }
}
