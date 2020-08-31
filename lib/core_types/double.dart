import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Double`s
AST visitDoubleProperties(AST node, AST left) {
  switch (node.binaryOpRight.variableName) {
    case 'isFinite':
      {
        AST boolAST = BoolNode()..boolVal = left.doubleVal.isFinite;
        return boolAST;
      }

    case 'isInfinite':
      {
        AST boolAST = BoolNode()..boolVal = left.doubleVal.isInfinite;
        return boolAST;
      }

    case 'isNaN':
      {
        AST boolAST = BoolNode()..boolVal = left.doubleVal.isNaN;
        return boolAST;
      }

    case 'isNegative':
      {
        AST boolAST = BoolNode()..boolVal = left.doubleVal.isNegative;
        return boolAST;
      }

    case 'sign':
      {
        AST doubleAST = DoubleNode()..doubleVal = left.doubleVal.sign;
        return doubleAST;
      }

    case 'runtimeType':
      {
        AST stringAST = StringNode()
          ..stringValue = left.doubleVal.runtimeType.toString();
        return stringAST;
      }
  }

  throw NoSuchPropertyException(node.binaryOpRight.variableName, 'double');
}

/// Visits methods for `Double`s
AST visitDoubleMethods(AST node, AST left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'abs':
      {
        AST doubleAST = DoubleNode()..doubleVal = left.doubleVal.abs();
        return doubleAST;
      }

    case 'ceil':
      {
        AST intAST = IntNode()..intVal = left.doubleVal.ceil();
        return intAST;
      }

    case 'ceilToDouble':
      {
        AST doubleAST = DoubleNode()..doubleVal = left.doubleVal.ceilToDouble();
        return doubleAST;
      }

    case 'clamp':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_DOUBLE, ASTType.AST_DOUBLE]);
        List args = node.binaryOpRight.funcCallArgs;
        AST doubleAST = DoubleNode()
          ..doubleVal =
              left.doubleVal.clamp(args[0].doubleVal, args[1].doubleVal);
        return doubleAST;
      }

    case 'compareTo':
      {
        runtimeExpectArgs(
            node.binaryOpRight.funcCallArgs, [ASTType.AST_DOUBLE]);
        AST intAST = IntNode()
          ..intVal = left.doubleVal
              .compareTo(node.binaryOpRight.funcCallArgs[0].doubleVal);
        return intAST;
      }

    case 'floor':
      {
        AST intAST = IntNode()..intVal = left.doubleVal.floor();
        return intAST;
      }

    case 'floorToDouble':
      {
        AST doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.floorToDouble();
        return doubleAST;
      }

    case 'remainder':
      {
        runtimeExpectArgs(
            node.binaryOpRight.funcCallArgs, [ASTType.AST_DOUBLE]);
        AST doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal
              .remainder(node.binaryOpRight.funcCallArgs[0].doubleVal);
        return doubleAST;
      }

    case 'round':
      {
        AST intAST = IntNode()..intVal = left.doubleVal.round();
        return intAST;
      }

    case 'roundToDouble':
      {
        AST doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.roundToDouble();
        return doubleAST;
      }

    case 'toInt':
      {
        AST intAST = IntNode()..intVal = left.doubleVal.toInt();
        return intAST;
      }

    case 'toString':
      {
        AST stringAST = StringNode()..stringValue = left.doubleVal.toString();
        return stringAST;
      }

    case 'toStringAsExponential':
      {
        List args = node.binaryOpRight.funcCallArgs;
        AST stringAST = StringNode()
          ..stringValue = left.doubleVal
              .toStringAsExponential(args.isEmpty ? 0 : args[0].intVal);
        return stringAST;
      }

    case 'toStringAsFixed':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST stringAST = StringNode()
          ..stringValue = left.doubleVal
              .toStringAsFixed(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'toStringAsPrecision':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        AST stringAST = StringNode()
          ..stringValue = left.doubleVal
              .toStringAsPrecision(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'truncate':
      {
        AST intAST = IntNode()..intVal = left.doubleVal.truncate();
        return intAST;
      }

    case 'truncateToDouble':
      {
        AST doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.truncateToDouble();
        return doubleAST;
      }

    default:
      throw NoSuchMethodException(
          node.binaryOpRight.funcCallExpression.variableName, 'double');
  }
}
