import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Int`s
ASTNode visitIntProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'bitLength':
      {
        ASTNode intAST = IntNode()..intVal = left.intVal.bitLength;
        return intAST;
      }

    case 'isEven':
      {
        ASTNode boolAST = BoolNode()..boolVal = left.intVal.isEven;
        return boolAST;
      }

    case 'isFinite':
      {
        ASTNode boolAST = BoolNode()..boolVal = left.intVal.isFinite;
        return boolAST;
      }

    case 'isInfinite':
      {
        ASTNode boolAST = BoolNode()..boolVal = left.intVal.isInfinite;
        return boolAST;
      }

    case 'isNaN':
      {
        ASTNode boolAST = BoolNode()..boolVal = left.intVal.isNaN;
        return boolAST;
      }

    case 'isNegative':
      {
        ASTNode boolAST = BoolNode()..boolVal = left.intVal.isNegative;
        return boolAST;
      }

    case 'isOdd':
      {
        ASTNode boolAST = BoolNode()..boolVal = left.intVal.isOdd;
        return boolAST;
      }

    case 'sign':
      {
        ASTNode intAST = IntNode()..intVal = left.intVal.sign;
        return intAST;
      }

    case 'runtimeType':
      {
        ASTNode stringAST = StringNode()
          ..stringValue = left.intVal.runtimeType.toString();
        return stringAST;
      }

    default:
      throw NoSuchPropertyException(node.binaryOpRight.variableName, 'int');
  }
}

/// Visits methods for `Int`s
ASTNode visitIntMethods(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'abs':
      {
        ASTNode intAST = IntNode()..intVal = left.intVal.abs();
        return intAST;
      }

    case 'clamp':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_INT]);
        List args = node.binaryOpRight.funcCallArgs;
        ASTNode intAST = IntNode()
          ..intVal = left.intVal.clamp(args[0].intVal, args[1].intVal);
        return intAST;
      }

    case 'compareTo':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        ASTNode intAST = IntNode()
          ..intVal =
              left.intVal.compareTo(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'gcd':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        ASTNode intAST = IntNode()
          ..intVal = left.intVal.gcd(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'modInverse':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        ASTNode intAST = IntNode()
          ..intVal =
              left.intVal.modInverse(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'modPow':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_INT]);
        List args = node.binaryOpRight.funcCallArgs;
        ASTNode intAST = IntNode()
          ..intVal = left.intVal.modPow(args[0].intVal, args[1].intVal);
        return intAST;
      }

    case 'remainder':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        ASTNode intAST = IntNode()
          ..intVal =
              left.intVal.remainder(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'toDouble':
      {
        ASTNode doubleAST = DoubleNode()..doubleVal = left.intVal.toDouble();
        return doubleAST;
      }

    case 'toRadixString':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        ASTNode stringAST = StringNode()
          ..stringValue = left.intVal
              .toRadixString(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'toSigned':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        ASTNode intAST = IntNode()
          ..intVal =
              left.intVal.toSigned(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    case 'toString':
      {
        ASTNode stringAST = StringNode()..stringValue = left.intVal.toString();
        return stringAST;
      }

    case 'toStringAsExponential':
      {
        List args = node.binaryOpRight.funcCallArgs;
        ASTNode stringAST = StringNode()
          ..stringValue = left.intVal
              .toStringAsExponential(args.isEmpty ? 0 : args[0].intVal);
        return stringAST;
      }

    case 'toStringAsFixed':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        ASTNode stringAST = StringNode()
          ..stringValue = left.intVal
              .toStringAsFixed(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'toStringAsPrecision':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        ASTNode stringAST = StringNode()
          ..stringValue = left.intVal
              .toStringAsPrecision(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'toUnsigned':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        ASTNode intAST = IntNode()
          ..intVal =
              left.intVal.toUnsigned(node.binaryOpRight.funcCallArgs[0].intVal);
        return intAST;
      }

    default:
      throw NoSuchMethodException(
          node.binaryOpRight.funcCallExpression.variableName, 'int');
  }
}
