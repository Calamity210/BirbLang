import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Double`s
ASTNode visitDoubleProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'isFinite':
      {
        BoolNode boolAST = BoolNode()..boolVal = left.doubleVal.isFinite;
        return boolAST;
      }

    case 'isInfinite':
      {
        BoolNode boolAST = BoolNode()..boolVal = left.doubleVal.isInfinite;
        return boolAST;
      }

    case 'isNaN':
      {
        BoolNode boolAST = BoolNode()..boolVal = left.doubleVal.isNaN;
        return boolAST;
      }

    case 'isNegative':
      {
        BoolNode boolAST = BoolNode()..boolVal = left.doubleVal.isNegative;
        return boolAST;
      }

    case 'sign':
      {
        DoubleNode doubleAST = DoubleNode()..doubleVal = left.doubleVal.sign;
        return doubleAST;
      }

    case 'runtimeType':
      {
        StringNode stringAST = StringNode()
          ..stringValue = left.doubleVal.runtimeType.toString();
        return stringAST;
      }
  }

  throw NoSuchPropertyException(node.binaryOpRight.variableName, 'double');
}

/// Visits methods for `Double`s
ASTNode visitDoubleMethods(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'abs':
      {
        DoubleNode doubleAST = DoubleNode()..doubleVal = left.doubleVal.abs();
        return doubleAST;
      }

    case 'ceil':
      {
        IntNode intAST = IntNode()..intVal = left.doubleVal.ceil();
        return intAST;
      }

    case 'ceilToDouble':
      {
        DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.ceilToDouble();
        return doubleAST;
      }

    case 'clamp':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_DOUBLE, ASTType.AST_DOUBLE]);
        List args = node.binaryOpRight.funcCallArgs;
        DoubleNode doubleAST = DoubleNode()
          ..doubleVal =
              left.doubleVal.clamp(args[0].doubleVal, args[1].doubleVal);
        return doubleAST;
      }

    case 'compareTo':
      {
        runtimeExpectArgs(
            node.binaryOpRight.funcCallArgs, [ASTType.AST_DOUBLE]);
        IntNode intAST = IntNode()
          ..intVal = left.doubleVal
              .compareTo(node.binaryOpRight.funcCallArgs[0].doubleVal);
        return intAST;
      }

    case 'floor':
      {
        IntNode intAST = IntNode()..intVal = left.doubleVal.floor();
        return intAST;
      }

    case 'floorToDouble':
      {
        DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.floorToDouble();
        return doubleAST;
      }

    case 'remainder':
      {
        runtimeExpectArgs(
            node.binaryOpRight.funcCallArgs, [ASTType.AST_DOUBLE]);
        DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal
              .remainder(node.binaryOpRight.funcCallArgs[0].doubleVal);
        return doubleAST;
      }

    case 'round':
      {
        IntNode intAST = IntNode()..intVal = left.doubleVal.round();
        return intAST;
      }

    case 'roundToDouble':
      {
        DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.roundToDouble();
        return doubleAST;
      }

    case 'toInt':
      {
        IntNode intAST = IntNode()..intVal = left.doubleVal.toInt();
        return intAST;
      }

    case 'toString':
      {
        StringNode stringAST = StringNode()
          ..stringValue = left.doubleVal.toString();
        return stringAST;
      }

    case 'toStringAsExponential':
      {
        List args = node.binaryOpRight.funcCallArgs;
        StringNode stringAST = StringNode()
          ..stringValue = left.doubleVal
              .toStringAsExponential(args.isEmpty ? 0 : args[0].intVal);
        return stringAST;
      }

    case 'toStringAsFixed':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        StringNode stringAST = StringNode()
          ..stringValue = left.doubleVal
              .toStringAsFixed(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'toStringAsPrecision':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        StringNode stringAST = StringNode()
          ..stringValue = left.doubleVal
              .toStringAsPrecision(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'truncate':
      {
        IntNode intAST = IntNode()..intVal = left.doubleVal.truncate();
        return intAST;
      }

    case 'truncateToDouble':
      {
        DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.truncateToDouble();
        return doubleAST;
      }

    default:
      throw NoSuchMethodException(
          node.binaryOpRight.funcCallExpression.variableName, 'double');
  }
}
