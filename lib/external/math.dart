import 'dart:math';

import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

void registerMath(Runtime runtime) {
  registerGlobalFunction(runtime, 'rand', funcRand);
}

ASTNode funcRand(Runtime runtime, ASTNode self, List<ASTNode> args) {
  runtimeExpectArgs(args, [ASTType.AST_ANY]);

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

  throw const UnexpectedTypeException('The rand method only takes [String, double, int, and bool] argument types');
}