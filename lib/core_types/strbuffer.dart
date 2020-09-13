import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `StrBuffer`
Future<ASTNode> visitStrBufferProperties(ASTNode node, ASTNode left) async {
  switch (node.binaryOpRight.variableName) {
    case 'isEmpty':
      {
        final ASTNode astBool = BoolNode()..boolVal = left.strBuffer.isEmpty;

        return astBool;
      }

    case 'isNotEmpty':
      {
        final ASTNode astBool = BoolNode()..boolVal = left.strBuffer.isNotEmpty;

        return astBool;
      }
    case 'length':
      {
        final ASTNode astInt = IntNode()..intVal = left.strBuffer.length;

        return astInt;
      }
    default:
      throw NoSuchPropertyException(
          node.binaryOpRight.variableName, 'StrBuffer');
  }
}

/// Visits methods for `StrBuffer`
ASTNode visitStrBufferMethods(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'toString':
      final ASTNode strAST = StringNode()..stringValue = left.strBuffer.toString();
      return strAST;

    case 'clear':
      left.strBuffer.clear();
      return left;

    case 'write':
      runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_STRING]);

      left.strBuffer
          .write((node.binaryOpRight.funcCallArgs[0]).stringValue);
      return left;

    case 'writeAll':
      runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_LIST]);

      (node.binaryOpRight.funcCallArgs[0]).listElements.forEach((dynamic e) {
        left.strBuffer.write((e as ASTNode).stringValue);
      });
      return left;

    case 'writeAsciiCode':
      runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);
      left.strBuffer.writeCharCode(
          (node.binaryOpRight.funcCallArgs[0]).intVal);
      return left;

    case 'writeLine':
      runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_STRING]);
      left.strBuffer.write(
          '${(node.binaryOpRight.funcCallArgs[0]).stringValue}\n');
  }
  throw NoSuchMethodException(
      node.binaryOpRight.funcCallExpression.variableName, 'StrBuffer');
}
