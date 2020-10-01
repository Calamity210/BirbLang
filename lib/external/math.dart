import 'dart:math';

import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

void registerMath(Runtime runtime) {
  registerGlobalFunction(runtime, 'acos', funcACos);
  registerGlobalFunction(runtime, 'asin', funcASin);
  registerGlobalFunction(runtime, 'atan', funcATan);
  registerGlobalFunction(runtime, 'atan2', funcATan2);
  registerGlobalFunction(runtime, 'cos', funcCos);
  registerGlobalFunction(runtime, 'exp', funcExp);
  registerGlobalFunction(runtime, 'ln', funcLn);
  registerGlobalFunction(runtime, 'log', funcLog);
  registerGlobalFunction(runtime, 'rand', funcRand);
  registerGlobalFunction(runtime, 'sin', funcSin);
  registerGlobalFunction(runtime, 'tan', funcTan);
}

ASTNode funcACos(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [ASTType.AST_ANY]);
  final radian = args[0];

  if (radian is IntNode || radian is DoubleNode) {
    final DoubleNode result = DoubleNode()
      ..doubleVal =
          acos(radian is DoubleNode ? radian.doubleVal : radian.intVal);
    return result;
  }

  throw UnexpectedTypeException(
      'The acos method only accept either double or int argument types but got ${radian.type}');
}

ASTNode funcASin(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [ASTType.AST_ANY]);
  final radian = args[0];

  if (radian is IntNode || radian is DoubleNode) {
    final DoubleNode result = DoubleNode()
      ..doubleVal =
          asin(radian is DoubleNode ? radian.doubleVal : radian.intVal);
    return result;
  }

  throw UnexpectedTypeException(
      'The asin method only accept either double or int argument types but got ${radian.type}');
}

ASTNode funcATan(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [ASTType.AST_ANY]);
  final radian = args[0];

  if (radian is IntNode || radian is DoubleNode) {
    final DoubleNode result = DoubleNode()
      ..doubleVal =
          atan(radian is DoubleNode ? radian.doubleVal : radian.intVal);
    return result;
  }

  throw UnexpectedTypeException(
      'The atan method only accept either double or int argument types but got ${radian.type}');
}

ASTNode funcATan2(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [ASTType.AST_ANY, ASTType.AST_ANY]);
  final y = args[0], x = args[1];
  final yVal = y is DoubleNode ? y.doubleVal : y.intVal;
  final xVal = x is DoubleNode ? x.doubleVal : x.intVal;

  if ((x is IntNode || x is DoubleNode) && (y is IntNode || y is DoubleNode)) {
    final DoubleNode result = DoubleNode()..doubleVal = atan2(yVal, xVal);
    return result;
  }

  throw UnexpectedTypeException(
      'The atan2 method only takes either double or int argument types for argument y and x but got ${x.type} and ${y.type}');
}

ASTNode funcCos(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [ASTType.AST_ANY]);
  final radian = args[0];

  if (radian is IntNode || radian is DoubleNode) {
    final DoubleNode result = DoubleNode()
      ..doubleVal =
          cos(radian is DoubleNode ? radian.doubleVal : radian.intVal);
    return result;
  }

  throw UnexpectedTypeException(
      'The cos method only accept either double or int argument types but got ${radian.type}');
}

ASTNode funcExp(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [ASTType.AST_ANY]);
  final val = args[0];

  if (val is IntNode || val is DoubleNode) {
    final DoubleNode result = DoubleNode()
      ..doubleVal = exp(val is DoubleNode ? val.doubleVal : val.intVal);
    return result;
  }

  throw UnexpectedTypeException(
      'The exp method only takes either double or int argument types for argument val but got ${val.type}');
}

ASTNode funcLn(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [ASTType.AST_ANY]);
  final val = args[0];

  if (val is IntNode || val is DoubleNode) {
    final DoubleNode result = DoubleNode()
      ..doubleVal = log(val is DoubleNode ? val.doubleVal : val.intVal);
    return result;
  }

  throw UnexpectedTypeException(
      'The ln method only takes either double or int argument types for argument val but got ${val.type}');
}

ASTNode funcLog(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [ASTType.AST_ANY, ASTType.AST_ANY]);
  final base = args[0], val = args[1];

  if ((base is IntNode || base is DoubleNode) &&
      (val is IntNode || val is DoubleNode)) {
    final double up = log(val is DoubleNode ? val.doubleVal : val.intVal);
    final double down = log(base is DoubleNode ? base.doubleVal : base.intVal);
    final DoubleNode result = DoubleNode()..doubleVal = up / down;
    return result;
  }

  throw UnexpectedTypeException(
      'The log method only takes either double or int argument types for argument base and val but got ${base.type} and ${val.type}');
}

ASTNode funcRand(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [AnyNode]);

  final ASTNode max = args[0];

  if (max is IntNode) {
    final int randVal = Random().nextInt(max.intVal);
    final IntNode intNode = IntNode()..intVal = randVal;
    return intNode;
  } else if (max is DoubleNode) {
    final double randVal = Random().nextDouble() * max.doubleVal;
    final DoubleNode doubleNode = DoubleNode()..doubleVal = randVal;
    return doubleNode;
  } else if (max is StringNode) {
    final Random rand = Random();
    String result = '';

    for (int i = 0; i < max.stringValue.length; i++) {
      final int randVal = 65 + rand.nextInt(65);
      result += String.fromCharCode(randVal);
    }

    final StringNode strNode = StringNode()..stringValue = result;
    return strNode;
  } else if (max is BoolNode) {
    final BoolNode boolNode = BoolNode()..boolVal = Random().nextBool();
    return boolNode;
  }

  throw UnexpectedTypeException(
      'The rand method only takes [String, double, int, and bool] argument types but got ${max.type}');
}

ASTNode funcSin(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [ASTType.AST_ANY]);
  final radian = args[0];

  if (radian is IntNode || radian is DoubleNode) {
    final DoubleNode result = DoubleNode()
      ..doubleVal =
          sin(radian is DoubleNode ? radian.doubleVal : radian.intVal);
    return result;
  }

  throw UnexpectedTypeException(
      'The sin method only accept either double or int argument types but got ${radian.type}');
}

ASTNode funcTan(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [ASTType.AST_ANY]);
  final radian = args[0];

  if (radian is IntNode || radian is DoubleNode) {
    final DoubleNode result = DoubleNode()
      ..doubleVal =
          tan(radian is DoubleNode ? radian.doubleVal : radian.intVal);
    return result;
  }

  throw UnexpectedTypeException(
      'The tan method only accept either double or int argument types but got ${radian.type}');
}
