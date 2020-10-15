import 'package:Birb/parser/data_type.dart';
import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:http/http.dart';

void registerHTTP(Runtime runtime) {
  runtime.registerGlobalFutureFunction('GET', funcGet);
  runtime.registerGlobalFutureFunction('POST', funcPost);
}

Future<ASTNode> funcGet(Runtime runtime, ASTNode self, List<ASTNode> args) async {
  if (args.length == 3)
    expectArgs(args,
        [StringNode, MapNode, FuncDefNode]);
  else
    expectArgs(args, [StringNode, MapNode]);

  final String url = (args[0]).stringValue;
  final Map headers = (args[1]).map;
  ASTNode funcDef;
  ASTNode funCall;

  if (args.length == 3) {
    funcDef = args[2];
    final ASTNode funcCalExpr = VariableNode();
    funcCalExpr.variableName = funcDef.funcName;

    funCall = FuncCallNode();
    funCall.funcName = funcDef.funcName;
    funCall.funcCallExpression = funcCalExpr;
  }

  final Map<String, String> head = {};
  headers.forEach((key, value) => head[key] = (value as ASTNode).stringValue);

  final Response response = await get(url, headers: head);
  if (args.length == 3)
    await runtime.visitFuncCall(funCall);

  final astObj = ClassNode();
  astObj.variableType = TypeNode();
  astObj.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_CLASS);

  // BODY
  var ast = VarDefNode();
  ast.variableName = 'body';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_STRING);

  var astVal = StringNode();
  astVal.stringValue = response.body;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // BODY BYTES
  ast = VarDefNode();
  ast.variableName = 'bodyBytes';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_LIST);

  final astListVal = ListNode();
  astListVal.listElements = response.bodyBytes;
  ast.variableValue = astListVal;

  astObj.classChildren.add(ast);

  // STATUS CODE
  ast = VarDefNode();
  ast.variableName = 'statusCode';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_INT);

  var astIntVal = IntNode();
  astIntVal.intVal = response.statusCode;
  ast.variableValue = astIntVal;

  astObj.classChildren.add(ast);

  // CONTENT LENGTH
  ast = VarDefNode();
  ast.variableName = 'contentLength';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_INT);

  astIntVal = IntNode();
  astIntVal.intVal = response.contentLength;
  ast.variableValue = astIntVal;

  astObj.classChildren.add(ast);

  // REASON PHRASE
  ast = VarDefNode();
  ast.variableName = 'reason';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_STRING);

  astVal = StringNode();
  astVal.stringValue = response.reasonPhrase;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // HEADERS
  ast = VarDefNode();
  ast.variableName = 'headers';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_MAP);

  final astMapVal = MapNode();
  astMapVal.map = response.headers;
  ast.variableValue = astMapVal;

  astObj.classChildren.add(ast);

  return astObj;
}

Future<ASTNode> funcPost(Runtime runtime, ASTNode self, List<ASTNode> args) async {
  if (args.length == 4)
    expectArgs(args, [StringNode, MapNode, MapNode, FuncDefNode]);
  else
    expectArgs(
        args, [StringNode, MapNode, MapNode]);

  final String url = (args[0]).stringValue;
  final Map bodyEarly = (args[1]).map;
  final Map head = (args[2]).map;

  ASTNode funcDef;
  ASTNode funCall;

  if (args.length == 4) {
    funcDef = args[3];
    final ASTNode funcCalExpr = VariableNode();
    funcCalExpr.variableName = funcDef.funcName;

    funCall = FuncCallNode();
    funCall.funcName = funcDef.funcName;
    funCall.funcCallExpression = funcCalExpr;
  }

  final Map<String, String> body = {};
  bodyEarly.forEach((key, value) => body[key] = (value as ASTNode).stringValue);

  final Map<String, String> headers = {};
  head.forEach((key, value) => headers[key] = (value as ASTNode).stringValue);

  final Response response = await post(url, body: body, headers: headers);
  if (args.length == 4)
    await runtime.visitCompound(funCall);

  final astObj = ClassNode();
  astObj.variableType = TypeNode();
  astObj.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_CLASS);

  // BODY
  var ast = VarDefNode();
  ast.variableName = 'body';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_STRING);

  var astVal = StringNode();
  astVal.stringValue = response.body;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // BODY BYTES
  ast = VarDefNode();
  ast.variableName = 'bodyBytes';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_LIST);

  final astListVal = ListNode();
  astListVal.listElements = response.bodyBytes;
  ast.variableValue = astListVal;

  astObj.classChildren.add(ast);

  // STATUS CODE
  ast = VarDefNode();
  ast.variableName = 'statusCode';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_INT);

  var astIntVal = IntNode();
  astIntVal.intVal = response.statusCode;
  ast.variableValue = astIntVal;

  astObj.classChildren.add(ast);

  // CONTENT LENGTH
  ast = VarDefNode();
  ast.variableName = 'contentLength';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_INT);

  astIntVal = IntNode();
  astVal.intVal = response.contentLength;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // REASON PHRASE
  ast = VarDefNode();
  ast.variableName = 'reason';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_STRING);

  astVal = StringNode();
  astVal.stringValue = response.reasonPhrase;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // HEADERS
  ast = VarDefNode();
  ast.variableName = 'headers';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = DataType.as(DATATYPE.DATA_TYPE_MAP);

  final astMapVal = MapNode();
  astMapVal.map = response.headers;
  ast.variableValue = astMapVal;

  astObj.classChildren.add(ast);

  return astObj;
}