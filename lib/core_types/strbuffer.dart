import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `StrBuffer`
Future<ASTNode> visitStrBufferProperties(ASTNode node, ASTNode left) async {
  switch (node.binaryOpRight.variableName) {
    case 'isEmpty':
        return BoolNode()..boolVal = left.strBuffer.isEmpty;

    case 'isNotEmpty':
        return BoolNode()..boolVal = left.strBuffer.isNotEmpty;

    case 'length':
        return IntNode()..intVal = left.strBuffer.length;

    default:
      throw NoSuchPropertyException(node.binaryOpRight.variableName, 'StrBuffer');
  }
}

/// Visits methods for `StrBuffer`
ASTNode visitStrBufferMethods(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'toString':
      return StringNode()..stringValue = left.strBuffer.toString();

    case 'clear':
      return left..strBuffer.clear();

    case 'write':
      runtimeExpectArgs(node.binaryOpRight.functionCallArgs, [ASTType.AST_STRING]);

      return left..strBuffer.write((node.binaryOpRight.functionCallArgs[0]).stringValue);

    case 'writeAll':
      runtimeExpectArgs(node.binaryOpRight.functionCallArgs, [ASTType.AST_LIST]);

      node.binaryOpRight.functionCallArgs[0].listElements.forEach((dynamic e) {
        left.strBuffer.write((e as ASTNode).stringValue);
      });

      return left;

    case 'writeAsciiCode':
      runtimeExpectArgs(node.binaryOpRight.functionCallArgs, [ASTType.AST_INT]);

      return left..strBuffer.writeCharCode((node.binaryOpRight.functionCallArgs[0]).intVal);

    case 'writeLine':
      runtimeExpectArgs(node.binaryOpRight.functionCallArgs, [ASTType.AST_STRING]);

      return left..strBuffer.write(
  '${(node.binaryOpRight.functionCallArgs[0]).stringValue}\n');
  }

  throw NoSuchMethodException(
      node.binaryOpRight.funcCallExpression.variableName, 'StrBuffer');
}
