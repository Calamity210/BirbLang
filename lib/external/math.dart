import 'dart:math';

import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

void registerMath(Runtime runtime) {
  registerGlobalFunction(runtime, 'rand', funcRand);
}

ASTNode funcRand(Runtime runtime, ASTNode self, List<ASTNode> args) {
  runtimeExpectArgs(args, [ASTType.AST_ANY]);

  ASTNode max = args[0];

  if (max is IntNode) {
    int randVal = Random().nextInt(max.intVal);
    IntNode intNode = IntNode()..intVal = randVal..doubleVal = randVal.toDouble();
    return intNode;
  } else if (max is DoubleNode) {
    double randVal = Random().nextDouble() * max.doubleVal;
    DoubleNode doubleNode = DoubleNode()..doubleVal = randVal..intVal = randVal.toInt();

    return doubleNode;
  } else if (max is StringNode) {
    Random rand = Random();
    String result = '';

    for (int i = 0; i < max.stringValue.length; i++) {
      int randVal = 65 + rand.nextInt(65);
      result += String.fromCharCode(randVal);
    }

    StringNode strNode = StringNode()..stringValue = result;
    return strNode;
  } else if (max is BoolNode) {
    BoolNode boolNode = BoolNode()..boolVal = Random().nextBool();
    return boolNode;
  }

  throw UnexpectedTypeException('The rand method only takes [String, double, int, and bool] argument types');
}