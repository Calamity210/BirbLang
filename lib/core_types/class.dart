import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/utils/ast/ast_types.dart';

/// Visits properties for `class'`
ASTNode visitClassProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'runtimeType':
      StringNode stringNode = StringNode()..stringValue = left.className;
      return stringNode;
    case 'variableDefinitions':
      MapNode ast = MapNode();

      left.classChildren.whereType<VarDefNode>().forEach((varDef) {
        ast.map[varDef.variableName] = varDef;
      });

      return ast;
  }
  return null;
}
