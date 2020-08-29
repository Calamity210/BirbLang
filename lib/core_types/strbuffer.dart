import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `StrBuffer`
Future<AST> visitStrBufferProperties(AST node, AST left) async {
  switch (node.binaryOpRight.variableName) {
    case 'isEmpty':
      {
        AST astBool = initAST(ASTType.AST_BOOL)
          ..boolValue = left.stringBuffer.isEmpty;

        return astBool;
      }

    case 'isNotEmpty':
      {
        AST astBool = initAST(ASTType.AST_BOOL)
          ..boolValue = left.stringBuffer.isNotEmpty;

        return astBool;
      }
    case 'length':
      {
        AST astInt = initAST(ASTType.AST_INT)
          ..intVal = left.stringBuffer.length;

        return astInt;
      }
    default:
      throw NoSuchPropertyException(
          node.binaryOpRight.variableName, 'StrBuffer');
  }
}

/// Visits methods for `StrBuffer`
AST visitStrBufferMethods(AST node, AST left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'toString':
      AST strAST = initAST(ASTType.AST_STRING)
        ..stringValue = left.stringBuffer.toString();
      return strAST;

    case 'clear':
      left.stringBuffer.clear();
      return left;

    case 'write':
      runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_STRING]);

      left.stringBuffer
          .write((node.binaryOpRight.funcCallArgs[0] as AST).stringValue);
      return left;

    case 'writeAll':
      runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_LIST]);

      (node.binaryOpRight.funcCallArgs[0] as AST).listElements.forEach((e) {
        left.stringBuffer.write((e as AST).stringValue);
      });
      return left;

    case 'writeAsciiCode':
      runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
      left.stringBuffer
          .writeCharCode((node.binaryOpRight.funcCallArgs[0] as AST).intVal);
      return left;

    case 'writeLine':
      runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_STRING]);
      left.stringBuffer.write(
          '${(node.binaryOpRight.funcCallArgs[0] as AST).stringValue}\n');
  }
  throw NoSuchMethodException(
      node.binaryOpRight.funcCallExpression.variableName, 'StrBuffer');
}
