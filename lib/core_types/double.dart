import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Double`s
ASTNode visitDoubleProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'isFinite':
      {
        final BoolNode boolAST = BoolNode()..boolVal = left.doubleVal.isFinite;
        return boolAST;
      }

    case 'isInfinite':
      {
        final BoolNode boolAST = BoolNode()
          ..boolVal = left.doubleVal.isInfinite;
        return boolAST;
      }

    case 'isNaN':
      {
        final BoolNode boolAST = BoolNode()..boolVal = left.doubleVal.isNaN;
        return boolAST;
      }

    case 'isNegative':
      {
        final BoolNode boolAST = BoolNode()
          ..boolVal = left.doubleVal.isNegative;
        return boolAST;
      }

    case 'sign':
      {
        final DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.sign;
        return doubleAST;
      }

    case 'runtimeType':
      {
        final StringNode stringAST = StringNode()
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
        final DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.abs();
        return doubleAST;
      }

    case 'ceil':
      {
        final IntNode intAST = IntNode()..intVal = left.doubleVal.ceil();
        return intAST;
      }

    case 'ceilToDouble':
      {
        final DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.ceilToDouble();
        return doubleAST;
      }

    case 'clamp':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_DOUBLE, ASTType.AST_DOUBLE]);
        final List<ASTNode> args = node.binaryOpRight.funcCallArgs;
        final DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal
              .clamp(args[0].doubleVal, args[1].doubleVal)
              .toDouble();

        return doubleAST;
      }

    case 'compareTo':
      {
        runtimeExpectArgs(
            node.binaryOpRight.funcCallArgs, [ASTType.AST_DOUBLE]);
        final IntNode intAST = IntNode()
          ..intVal = left.doubleVal
              .compareTo(node.binaryOpRight.funcCallArgs[0].doubleVal);
        return intAST;
      }

    case 'floor':
      {
        final IntNode intAST = IntNode()..intVal = left.doubleVal.floor();
        return intAST;
      }

    case 'floorToDouble':
      {
        final DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.floorToDouble();
        return doubleAST;
      }

    case 'remainder':
      {
        runtimeExpectArgs(
            node.binaryOpRight.funcCallArgs, [ASTType.AST_DOUBLE]);
        final DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal
              .remainder(node.binaryOpRight.funcCallArgs[0].doubleVal);
        return doubleAST;
      }

    case 'round':
      {
        final IntNode intAST = IntNode()..intVal = left.doubleVal.round();
        return intAST;
      }

    case 'roundToDouble':
      {
        final DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.roundToDouble();
        return doubleAST;
      }

    case 'toInt':
      {
        final IntNode intAST = IntNode()..intVal = left.doubleVal.toInt();
        return intAST;
      }

    case 'toString':
      {
        final StringNode stringAST = StringNode()
          ..stringValue = left.doubleVal.toString();
        return stringAST;
      }

    case 'toStringAsExponential':
      {
        final List<ASTNode> args = node.binaryOpRight.funcCallArgs;
        final StringNode stringAST = StringNode()
          ..stringValue = left.doubleVal
              .toStringAsExponential(args.isEmpty ? 0 : args[0].intVal);
        return stringAST;
      }

    case 'toStringAsFixed':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        final StringNode stringAST = StringNode()
          ..stringValue = left.doubleVal
              .toStringAsFixed(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'toStringAsPrecision':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
        final StringNode stringAST = StringNode()
          ..stringValue = left.doubleVal
              .toStringAsPrecision(node.binaryOpRight.funcCallArgs[0].intVal);
        return stringAST;
      }

    case 'truncate':
      {
        final IntNode intAST = IntNode()..intVal = left.doubleVal.truncate();
        return intAST;
      }

    case 'truncateToDouble':
      {
        final DoubleNode doubleAST = DoubleNode()
          ..doubleVal = left.doubleVal.truncateToDouble();
        return doubleAST;
      }

    default:
      throw NoSuchMethodException(
          node.binaryOpRight.funcCallExpression.variableName, 'double');
  }
}
