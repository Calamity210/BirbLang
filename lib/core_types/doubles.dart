import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Doubles`s
AST visitDoubleProperties(AST node, AST left) {
  switch (node.binaryOpRight.variableName) {
    case 'isFinite':
      {
        /// True if the number is finite; otherwise, false.
        AST boolAST = initAST(ASTType.AST_BOOL)
          ..boolValue = left.doubleValue.isFinite;
        return boolAST;
      }

    case 'isInfinite':
      {
        /// True if the number is positive infinity or negative infinity; otherwise, false.
        AST boolAST = initAST(ASTType.AST_BOOL)
          ..boolValue = left.doubleValue.isInfinite;
        return boolAST;
      }

    case 'isNaN':
      {
        /// True if the number is the double Not-a-Number value; otherwise, false.
        AST boolAST = initAST(ASTType.AST_BOOL)..boolValue = left.intVal.isNaN;
        return boolAST;
      }

    case 'isNegative':
      {
        /// True if the number is negative; otherwise, false. 
        AST boolAST = initAST(ASTType.AST_BOOL)
          ..boolValue = left.doubleValue.isNegative;
        return boolAST;
      }

    case 'hashCode':
      {
        /// The hash code for this object.
        /// A hash code is a single integer which represents the state of the object that affects operator == comparisons.
        AST intAST = initAST(ASTType.AST_INT)
          ..intVal = left.doubleValue.hashCode;
        return intAST;
      }

    case 'sign':
      {
        /// Returns the sign of the double's numerical value.
        AST doubleAST = initAST(ASTType.AST_DOUBLE)
          ..doubleValue = left.doubleValue.sign;
        return doubleAST;
      }
  }

  throw NoSuchPropertyException(node.binaryOpRight.variableName, 'double');
}
