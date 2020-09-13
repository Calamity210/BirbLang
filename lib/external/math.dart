import 'dart:math';

import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

void registerMath(Runtime runtime) {
  registerGlobalFunction(runtime, 'rand', funcRand);
  registerGlobalFunction(runtime, 'atan2', funcATan2);
  for(final name in {'sin', 'cos', 'tan'}){
    registerGlobalFunction(runtime, name, funcTrigo(name));
    registerGlobalFunction(runtime, 'a$name', funcTrigo('a$name'));
  }
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

ASTNode funcATan2(Runtime runtime, ASTNode self, List<ASTNode> args){
  runtimeExpectArgs(args, [ASTType.AST_ANY]);
  final y = args[0], x = args[1];
  switch(y.type) {
    case ASTType.AST_INT: 
      switch(x.type) {
        case ASTType.AST_INT: return DoubleNode()..doubleVal = atan2(y.intVal, x.intVal);
        case ASTType.AST_DOUBLE: return DoubleNode()..doubleVal = atan2(y.intVal, x.doubleVal);
        default:
      } break;
    case ASTType.AST_DOUBLE: 
      switch(x.type) {
        case ASTType.AST_INT: return DoubleNode()..doubleVal = atan2(y.doubleVal, x.intVal);
        case ASTType.AST_DOUBLE: return DoubleNode()..doubleVal = atan2(y.doubleVal, x.doubleVal);
        default:
      } break;
    default:
  }
  throw const UnexpectedTypeException('The atan2 method only takes [double, int] argument types for argument 1 and 2');
}

ASTNode Function(Runtime, ASTNode, List<ASTNode>) funcTrigo(String name){
  final ASTNode Function(Runtime, ASTNode, List<ASTNode>) Function(ASTNode Function(ASTNode)) func = (Function(ASTNode) callback) {
    return (Runtime runtime, ASTNode self, List<ASTNode> args) {
      runtimeExpectArgs(args, [ASTType.AST_ANY]);
      final radian = args[0];
      switch(radian.type){
        case ASTType.AST_INT: 
        case ASTType.AST_DOUBLE: 
          return callback(radian);
        default:
      }
      throw UnexpectedTypeException('The $name method only accept [double, int] argument types');
    };
  };
  switch(name){
    case 'sin': return func(funcSin);
    case 'cos': return func(funcCos);
    case 'tan': return func(funcTan);
    case 'asin': return func(funcASin);
    case 'acos': return func(funcACos);
    case 'atan': return func(funcATan);
  }
  throw Exception('Undefined trigo function $name');
}

ASTNode funcSin(ASTNode radian){
  switch(radian.type){
    case ASTType.AST_INT: return DoubleNode()..doubleVal = sin(radian.intVal);
    case ASTType.AST_DOUBLE: return DoubleNode()..doubleVal = sin(radian.doubleVal);
    default: return NullNode();
  }
}

ASTNode funcCos(ASTNode radian){
  switch(radian.type){
    case ASTType.AST_INT: return DoubleNode()..doubleVal = cos(radian.intVal);
    case ASTType.AST_DOUBLE: return DoubleNode()..doubleVal = cos(radian.doubleVal);
    default: return NullNode();
  }
}

ASTNode funcTan(ASTNode radian){
  switch(radian.type){
    case ASTType.AST_INT: return DoubleNode()..doubleVal = tan(radian.intVal);
    case ASTType.AST_DOUBLE: return DoubleNode()..doubleVal = tan(radian.doubleVal);
    default: return NullNode();
  }
}

ASTNode funcASin(ASTNode radian){
  switch(radian.type){
    case ASTType.AST_INT: return DoubleNode()..doubleVal = asin(radian.intVal);
    case ASTType.AST_DOUBLE: return DoubleNode()..doubleVal = asin(radian.doubleVal);
    default: return NullNode();
  }
}

ASTNode funcACos(ASTNode radian){
  switch(radian.type){
    case ASTType.AST_INT: return DoubleNode()..doubleVal = acos(radian.intVal);
    case ASTType.AST_DOUBLE: return DoubleNode()..doubleVal = acos(radian.doubleVal);
    default: return NullNode();
  }
}

ASTNode funcATan(ASTNode radian){
  switch(radian.type){
    case ASTType.AST_INT: return DoubleNode()..doubleVal = atan(radian.intVal);
    case ASTType.AST_DOUBLE: return DoubleNode()..doubleVal = atan(radian.doubleVal);
    default: return NullNode();
  }
}