import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';

/// Visits properties for `class'`
ASTNode visitClassProperties(ASTNode node, ASTNode left) {
  switch (node.binaryOpRight.variableName) {
    case 'runtimeType':
      return StringNode()..stringValue = left.className;
    case 'variableDefinitions':
      final MapNode ast = MapNode()..map = {};

      left.classChildren.whereType<VarDefNode>().forEach((varDef) {
        ast.map[varDef.variableName] = varDef;
      });

      return ast;
  }
  return null;
}
