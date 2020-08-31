import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Int`s
AST visitIntProperties(AST node, AST left) {
  switch (node.binaryOpRight.variableName) {
    case 'bitLength':
      {
        AST intAST = IntNode()..intVal = left.intVal.bitLength;
        return intAST;
      }

    case 'isEven':
      {
        AST boolAST = BoolNode()..boolVal = left.intVal.isEven;
        return boolAST;
      }

    case 'isFinite':
      {
        AST boolAST = BoolNode()..boolVal = left.intVal.isFinite;
        return boolAST;
      }

    case 'isInfinite':
      {
        AST boolAST = BoolNode()..boolVal = left.intVal.isInfinite;
        return boolAST;
      }

    case 'isNaN':
      {
        AST boolAST = BoolNode()..boolVal = left.intVal.isNaN;
        return boolAST;
      }

    case 'isNegative':
      {
        AST boolAST = BoolNode()..boolVal = left.intVal.isNegative;
        return boolAST;
      }

    case 'isOdd':
      {
        AST boolAST = BoolNode()..boolVal = left.intVal.isOdd;
        return boolAST;
      }

    case 'sign':
      {
        AST intAST = BoolNode()..intVal = left.intVal.sign;
        return intAST;
      }

    case 'runtimeType':
      {
        AST stringAST = StringNode()
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
        AST intAST = IntNode()..intVal = left.intVal.abs();
        return intAST;
      }

    case 'clamp':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_INT]);
        List args = node.binaryOpRight.funcCallArgs;
        AST intAST = IntNode()
          ..intVal = left.intVal.clamp(args[0].intVal, args[1].intVal);
        return intAST;
      }

    case 'compareTo':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST intAST = IntNode()
          ..intVal =
              left.intVal.compareTo(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'gcd':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST intAST = IntNode()
          ..intVal = left.intVal.gcd(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'modInverse':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST intAST = IntNode()
          ..intVal =
              left.intVal.modInverse(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'modPow':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_INT]);
        List args = node.binaryOpRight.funcCallArgs;
        AST intAST = IntNode()
          ..intVal = left.intVal.modPow(args[0].intVal, args[1].intVal);
        return intAST;
      }

    case 'remainder':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST intAST = IntNode()
          ..intVal =
              left.intVal.remainder(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'toDouble':
      {
        AST doubleAST = DoubleNode()..doubleVal = left.intVal.toDouble();
        return doubleAST;
      }

    case 'toRadixString':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST stringAST = StringNode()
          ..stringValue = left.intVal
              .toRadixString(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'toSigned':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST intAST = IntNode()
          ..intVal =
              left.intVal.toSigned(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'toString':
      {
        AST stringAST = StringNode()..stringValue = left.intVal.toString();
        return stringAST;
      }

    case 'toStringAsExponential':
      {
        List args = node.binaryOpRight.funcCallArgs;
        AST stringAST = StringNode()
          ..stringValue = left.intVal
              .toStringAsExponential(args.isEmpty ? 0 : args[0].intVal);
        return stringAST;
      }

    case 'toStringAsFixed':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST stringAST = StringNode()
          ..stringValue = left.intVal
              .toStringAsFixed(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'toStringAsPrecision':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST stringAST = StringNode()
          ..stringValue = left.intVal
              .toStringAsPrecision(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'toUnsigned':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST intAST = IntNode()
          ..intVal =
              left.intVal.toUnsigned(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    default:
      throw NoSuchMethodException(
          node.binaryOpRight.funcCallExpression.variableName, 'int');
  }
}
