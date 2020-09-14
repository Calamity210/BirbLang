import 'dart:math';

import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

void registerMath(Runtime runtime) {
  registerGlobalFunction(runtime, 'rand', funcRand);
  registerGlobalFunction(runtime, 'sin', funcSin);
  registerGlobalFunction(runtime, 'cos', funcCos);
  registerGlobalFunction(runtime, 'tan', funcTan);
  registerGlobalFunction(runtime, 'asin', funcASin);
  registerGlobalFunction(runtime, 'acos', funcACos);
  registerGlobalFunction(runtime, 'atan', funcATan);
  registerGlobalFunction(runtime, 'atan2', funcATan2);
  registerGlobalFunction(runtime, 'exp', funcExp);
  registerGlobalFunction(runtime, 'log', funcLog);
  registerGlobalFunction(runtime, 'ln', funcLn);
}

ASTNode funcRand(Runtime runtime, ASTNode self, List<ASTNode> args) {
  runtimeExpectArgs(args, [ASTType.AST_ANY]);

  final ASTNode max = args[0];

  if (max is IntNode) {
    final int randVal = Random().nextInt(max.intVal);
    final IntNode intNode = IntNode()..intVal = randVal..doubleVal = randVal.toDouble();
    return intNode;
  } else if (max is DoubleNode) {
    final double randVal = Random().nextDouble() * max.doubleVal;
    final DoubleNode doubleNode = DoubleNode()..doubleVal = randVal..intVal = randVal.toInt();

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

ASTNode funcSin(Runtime runtime, ASTNode self, List<ASTNode> args){
  runtimeExpectArgs(args, [ASTType.AST_ANY]);
  final radian = args[0];
  
  if(radian is IntNode || radian is DoubleNode){
    final DoubleNode result = DoubleNode()..doubleVal = sin(radian is DoubleNode ? radian.doubleVal : radian.intVal);
    return result;
  }
  
  throw const UnexpectedTypeException('The sin method only accept [double, int] argument types');
}

ASTNode funcCos(Runtime runtime, ASTNode self, List<ASTNode> args){
  runtimeExpectArgs(args, [ASTType.AST_ANY]);
  final radian = args[0];
     
  if(radian is IntNode || radian is DoubleNode){
    final DoubleNode result = DoubleNode()..doubleVal = cos(radian is DoubleNode ? radian.doubleVal : radian.intVal);
    return result;
  }
  
  throw const UnexpectedTypeException('The cos method only accept [double, int] argument types');
}

ASTNode funcTan(Runtime runtime, ASTNode self, List<ASTNode> args){  
  runtimeExpectArgs(args, [ASTType.AST_ANY]);
  final radian = args[0];
     
  if(radian is IntNode || radian is DoubleNode){
    final DoubleNode result = DoubleNode()..doubleVal = tan(radian is DoubleNode ? radian.doubleVal : radian.intVal);
    return result;
  }
  
  throw const UnexpectedTypeException('The tan method only accept [double, int] argument types');
}

ASTNode funcASin(Runtime runtime, ASTNode self, List<ASTNode> args){
  runtimeExpectArgs(args, [ASTType.AST_ANY]);
  final radian = args[0];
     
  if(radian is IntNode || radian is DoubleNode){
    final DoubleNode result = DoubleNode()..doubleVal = asin(radian is DoubleNode ? radian.doubleVal : radian.intVal);
    return result;
  }
  
  throw const UnexpectedTypeException('The asin method only accept [double, int] argument types');
}

ASTNode funcACos(Runtime runtime, ASTNode self, List<ASTNode> args){
  runtimeExpectArgs(args, [ASTType.AST_ANY]);
  final radian = args[0];
     
  if(radian is IntNode || radian is DoubleNode){
    final DoubleNode result = DoubleNode()..doubleVal = acos(radian is DoubleNode ? radian.doubleVal : radian.intVal);
    return result;
  }
  
  throw const UnexpectedTypeException('The acos method only accept [double, int] argument types');
}

ASTNode funcATan(Runtime runtime, ASTNode self, List<ASTNode> args){
  runtimeExpectArgs(args, [ASTType.AST_ANY]);
  final radian = args[0];
     
  if(radian is IntNode || radian is DoubleNode){
    final DoubleNode result = DoubleNode()..doubleVal = atan(radian is DoubleNode ? radian.doubleVal : radian.intVal);
    return result;
  }
  
  throw const UnexpectedTypeException('The atan method only accept [double, int] argument types');
}

ASTNode funcATan2(Runtime runtime, ASTNode self, List<ASTNode> args){
  runtimeExpectArgs(args, [ASTType.AST_ANY, ASTType.AST_ANY]);
  final y = args[0], x = args[1];
  final yVal = y is DoubleNode ? y.doubleVal : y.intVal;
  final xVal = x is DoubleNode ? x.doubleVal : x.intVal;

  if((x is IntNode || x is DoubleNode) && (y is IntNode || y is DoubleNode)){
    final DoubleNode result = DoubleNode()..doubleVal = atan2(yVal, xVal);
    return result;
  }
  
  throw const UnexpectedTypeException('The atan2 method only takes [double, int] argument types for argument y and x');
}

ASTNode funcExp(Runtime runtime, ASTNode self, List<ASTNode> args){
  runtimeExpectArgs(args, [ASTType.AST_ANY]);
  final val = args[0];

  if(val is IntNode || val is DoubleNode){
    final DoubleNode result = DoubleNode()..doubleVal = exp(val is DoubleNode ? val.doubleVal : val.intVal);
    return result;
  }

  throw const UnexpectedTypeException('The exp method only takes [double, int] argument types for argument val');
}

ASTNode funcLog(Runtime runtime, ASTNode self, List<ASTNode> args){
  runtimeExpectArgs(args, [ASTType.AST_ANY, ASTType.AST_ANY]);
  final base = args[0], val = args[1];

  if((base is IntNode || base is DoubleNode) && (val is IntNode || val is DoubleNode)){
    final double up = log(val is DoubleNode ? val.doubleVal : val.intVal);
    final double down = log(base is DoubleNode ? base.doubleVal : base.intVal);
    final DoubleNode result = DoubleNode()..doubleVal = up / down;
    return result;
  }

  throw const UnexpectedTypeException('The log method only takes [double, int] argument types for argument base and val');
}

ASTNode funcLn(Runtime runtime, ASTNode self, List<ASTNode> args){
  runtimeExpectArgs(args, [ASTType.AST_ANY]);
  final val = args[0];

  if(val is IntNode || val is DoubleNode){
    final DoubleNode result = DoubleNode()..doubleVal = log(val is DoubleNode ? val.doubleVal : val.intVal);
    return result;
  }

  throw const UnexpectedTypeException('The ln method only takes [double, int] argument types for argument val');
}