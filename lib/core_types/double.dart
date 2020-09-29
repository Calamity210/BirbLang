import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `Double`s
ASTNode visitDoubleProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'isFinite':
        return BoolNode()..boolVal = left.doubleVal.isFinite;

    case 'isInfinite':
        return BoolNode()..boolVal = left.doubleVal.isInfinite;

    case 'isNaN':
        return BoolNode()..boolVal = left.doubleVal.isNaN;

    case 'isNegative':
        return BoolNode()
          ..boolVal = left.doubleVal.isNegative;

    case 'sign':
        return DoubleNode()
          ..doubleVal = left.doubleVal.sign;

    case 'runtimeType':
          return StringNode()..stringValue = left.doubleVal.runtimeType.toString();
  }

  throw NoSuchPropertyException(node.binaryOpRight.variableName, 'double');
}

/// Visits methods for `Double`s
ASTNode visitDoubleMethods(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'abs':
        return DoubleNode()..doubleVal = left.doubleVal.abs();

    case 'ceil':
        return IntNode()..intVal = left.doubleVal.ceil();

    case 'ceilToDouble':
        return DoubleNode()..doubleVal = left.doubleVal.ceilToDouble();

    case 'clamp':
        expectArgs(node.binaryOpRight.functionCallArgs, [DoubleNode, DoubleNode]);

        final List<ASTNode> args = node.binaryOpRight.functionCallArgs;

        return DoubleNode()
          ..doubleVal = left.doubleVal
              .clamp(args[0].doubleVal, args[1].doubleVal)
              .toDouble();

    case 'compareTo':
        expectArgs(node.binaryOpRight.functionCallArgs, [DoubleNode]);

        return IntNode()
          ..intVal = left.doubleVal
              .compareTo(node.binaryOpRight.functionCallArgs[0].doubleVal);

    case 'floor':
        return IntNode()..intVal = left.doubleVal.floor();

    case 'floorToDouble':
        return DoubleNode()
          ..doubleVal = left.doubleVal.floorToDouble();

    case 'remainder':
        expectArgs(node.binaryOpRight.functionCallArgs, [DoubleNode]);

        return DoubleNode()
          ..doubleVal = left.doubleVal
              .remainder(node.binaryOpRight.functionCallArgs[0].doubleVal);

    case 'round':
        return IntNode()..intVal = left.doubleVal.round();

    case 'roundToDouble':
        return DoubleNode()..doubleVal = left.doubleVal.roundToDouble();

    case 'toInt':
        return IntNode()..intVal = left.doubleVal.toInt();

    case 'toString':
        return StringNode()..stringValue = left.doubleVal.toString();

    case 'toStringAsExponential':
        final List<ASTNode> args = node.binaryOpRight.functionCallArgs;

        return StringNode()
          ..stringValue = left.doubleVal
              .toStringAsExponential(args.isEmpty ? 0 : args[0].intVal);

    case 'toStringAsFixed':
        expectArgs(node.binaryOpRight.functionCallArgs, [IntNode]);

        return StringNode()
          ..stringValue = left.doubleVal
              .toStringAsFixed(node.binaryOpRight.functionCallArgs[0].intVal);

    case 'toStringAsPrecision':
        expectArgs(node.binaryOpRight.functionCallArgs, [IntNode]);

        return StringNode()
          ..stringValue = left.doubleVal
              .toStringAsPrecision(node.binaryOpRight.functionCallArgs[0].intVal);

    case 'truncate':
        return IntNode()..intVal = left.doubleVal.truncate();

    case 'truncateToDouble':
        return DoubleNode()
          ..doubleVal = left.doubleVal.truncateToDouble();

    default:
      throw NoSuchMethodException(
          node.binaryOpRight.funcCallExpression.variableName, 'double');
  }
}
