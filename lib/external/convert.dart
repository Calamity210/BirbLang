import 'dart:convert';

import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

void registerConvert(Runtime runtime) {
  registerGlobalFunction(runtime, 'decodeJson', funcDecodeJson);
  registerGlobalFunction(runtime, 'encodeJson', funcEncodeJson);
}

ASTNode funcDecodeJson(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [StringNode]);

  final String jsonString = (args[0]).stringValue;

  final dynamic decoded = jsonDecode(jsonString);

  ASTNode jsonAST;
  if (decoded is List)
    jsonAST = ListNode()..listElements = decoded;
  else
    jsonAST = MapNode()..map = jsonDecode(jsonString) as Map<String, dynamic>;

  return jsonAST;
}

ASTNode funcEncodeJson(Runtime runtime, ASTNode self, List<ASTNode> args) {
  expectArgs(args, [MapNode]);

  final Map map = (args[0]).map;

  final Map jsonMap = <String, dynamic>{};

  map.forEach((key, value) {
    final ASTNode val = value;
    switch (val.type) {
      case ASTType.AST_STRING:
        jsonMap[key] = val.stringValue;
        break;
      case ASTType.AST_INT:
        jsonMap[key] = val.intVal;
        break;
      case ASTType.AST_DOUBLE:
        jsonMap[key] = val.doubleVal;
        break;
      case ASTType.AST_LIST:
        jsonMap[key] = val.listElements;
        break;
      case ASTType.AST_MAP:
        jsonMap[key] = val.map;
        break;
      default:
        throw JsonValueTypeException(key, val.type);
    }
    return;
  });

  final ASTNode jsonAST = StringNode()..stringValue = jsonEncode(jsonMap);

  return jsonAST;
}
