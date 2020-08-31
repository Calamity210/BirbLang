import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Int`s
AST visitIntProperties(AST node, AST left) {
  switch (node.binaryOpRight.variableName) {
    case 'bitLength':
      {
        /// Returns the minimum number of bits required to store this integer.
        /// The number of bits excludes the sign bit, which gives the natural length for non-negative (unsigned) values. 
        /// Negative values are complemented to return the bit position of the first bit that differs from the sign bit.

        AST intAST = initAST(ASTType.AST_INT)..intVal = left.intVal.bitLength;
        return intAST;
      }

    case 'isEven':
      {
        /// Returns true if and only if this integer is even.
        AST boolAST = initAST(ASTType.AST_BOOL)..boolValue = left.intVal.isEven;
        return boolAST;
      }

    case 'isFinite':
      {
        /// True if the number is finite; otherwise, false.
        /// The only non-finite numbers are NaN, positive infinity, and negative infinity.
        AST boolAST = initAST(ASTType.AST_BOOL)
          ..boolValue = left.intVal.isFinite;
        return boolAST;
      }

    case 'isInfinite':
      {
        /// True if the number is positive infinity or negative infinity; otherwise, false.
        AST boolAST = initAST(ASTType.AST_BOOL)
          ..boolValue = left.intVal.isInfinite;
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
        /// Negative numbers are those less than zero, and the double -0.0.
        AST boolAST = initAST(ASTType.AST_BOOL)
          ..boolValue = left.intVal.isNegative;
        return boolAST;
      }

    case 'isOdd':
      {
        /// Returns true if and only if this integer is odd.
        AST boolAST = initAST(ASTType.AST_BOOL)..boolValue = left.intVal.isOdd;
        return boolAST;
      }

    case 'sign':
      {
        /// Returns the sign of this integer.
        /// Returns 0 for zero, -1 for values less than zero and +1 for values greater than zero.
        AST intAST = initAST(ASTType.AST_BOOL)..intVal = left.intVal.sign;
        return intAST;
      }

    case 'runtimeType':
      {
        /// A representation of the runtime type of the object.
        AST stringAST = initAST(ASTType.AST_STRING)
          ..stringValue = left.intVal.runtimeType.toString();
        return stringAST;
      }

    default:
      throw NoSuchPropertyException(node.binaryOpRight.variableName, 'int');
  }
}

/// Visits methods for `Int`s
AST visitIntMethods(AST node, AST left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'abs':
      {
        AST intAST = initAST(ASTType.AST_INT)..intVal = left.intVal.abs();
        return intAST;
      }

    case 'clamp':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_INT]);
        List args = node.binaryOpRight.funcCallArgs;
        AST intAST = initAST(ASTType.AST_INT)
          ..intVal = left.intVal.clamp(args[0].intVal, args[1].intVal);
        return intAST;
      }

    case 'compareTo':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST intAST = initAST(ASTType.AST_INT)
          ..intVal =
              left.intVal.compareTo(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'gcd':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST intAST = initAST(ASTType.AST_INT)
          ..intVal = left.intVal.gcd(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'modInverse':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST intAST = initAST(ASTType.AST_INT)
          ..intVal =
              left.intVal.modInverse(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'modPow':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_INT]);
        List args = node.binaryOpRight.funcCallArgs;
        AST intAST = initAST(ASTType.AST_INT)
          ..intVal = left.intVal.modPow(args[0].intVal, args[1].intVal);
        return intAST;
      }

    case 'remainder':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST intAST = initAST(ASTType.AST_INT)
          ..intVal =
              left.intVal.remainder(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'toDouble':
      {
        AST doubleAST = initAST(ASTType.AST_DOUBLE)
          ..doubleValue = left.intVal.toDouble();
        return doubleAST;
      }

    case 'toRadixString':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST stringAST = initAST(ASTType.AST_STRING)
          ..stringValue = left.intVal
              .toRadixString(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'toSigned':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST intAST = initAST(ASTType.AST_INT)
          ..intVal =
              left.intVal.toSigned(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'toString':
      {
        AST stringAST = initAST(ASTType.AST_STRING)
          ..stringValue = left.intVal.toString();
        return stringAST;
      }

    case 'toStringAsExponential':
      {
        List args = node.binaryOpRight.funcCallArgs;
        AST stringAST = initAST(ASTType.AST_STRING)
          ..stringValue = left.intVal
              .toStringAsExponential(args.isEmpty ? 0 : args[0].intVal);
        return stringAST;
      }

    case 'toStringAsFixed':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST stringAST = initAST(ASTType.AST_STRING)
          ..stringValue = left.intVal
              .toStringAsFixed(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'toStringAsPrecision':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST stringAST = initAST(ASTType.AST_STRING)
          ..stringValue = left.intVal
              .toStringAsPrecision(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'toUnsigned':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST intAST = initAST(ASTType.AST_INT)
          ..intVal =
              left.intVal.toUnsigned(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    default:
      throw NoSuchMethodException(
          node.binaryOpRight.funcCallExpression.variableName, 'int');
  }
}
