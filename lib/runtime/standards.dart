import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:Birb/utils/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';
import 'package:http/http.dart';

import 'package:Birb/utils/ast/ast_node.dart';
import 'package:Birb/parser/data_type.dart';
import 'package:Birb/lexer/lexer.dart';
import 'package:Birb/parser/parser.dart';
import 'package:Birb/runtime/runtime.dart';

String filePath = '';
ASTNode INITIALIZED_NOOP;

void initStandards(Runtime runtime, String path) async {
  filePath = path ?? '';
  registerGlobalVariable(
      runtime, 'birbVer', StringNode()..stringValue = '0.0.1');

  // Date class
  registerGlobalVariable(runtime, 'Date', dateClass(runtime));

  // Double class
  registerGlobalVariable(runtime, 'Double', doubleClass(runtime));

  // Time class
  registerGlobalVariable(runtime, 'Time', timeClass(runtime));

  // functions
  registerGlobalFunction(runtime, 'screm', funcScrem);
  registerGlobalFunction(runtime, 'beep', funcBeep);
  registerGlobalFunction(runtime, 'exit', funcExit);
  registerGlobalFunction(runtime, 'rand', funcRand);
  registerGlobalFunction(runtime, 'mock', funcMock);
  registerGlobalFunction(runtime, 'decodeJson', funcDecodeJson);
  registerGlobalFunction(runtime, 'encodeJson', funcEncodeJson);

  registerGlobalFutureFunction(runtime, 'grab', funcGrab);
  registerGlobalFutureFunction(runtime, 'GET', funcGet);
  registerGlobalFutureFunction(runtime, 'POST', funcPost);
}

Future<ASTNode> funcGrab(Runtime runtime, ASTNode self, List args) async {
  runtimeExpectArgs(args, [ASTType.AST_STRING]);

  ASTNode astStr = args[0];
  if (astStr.stringValue.startsWith('birb:')) {
    String fileName = astStr.stringValue.split(':')[1];
    String scriptParentPath = Platform.script.path.replaceFirst('birb.dart', '');
    if (scriptParentPath.startsWith('/'))
      scriptParentPath = scriptParentPath.replaceFirst('/', '');

    Lexer lexer = initLexer(File('$scriptParentPath../core/$fileName/$fileName.birb').readAsStringSync());
    Parser parser = initParser(lexer);
    ASTNode node = parse(parser);
    await visit(runtime, node);

    return AnyNode();
  }
  String filename = '$filePath${Platform.pathSeparator}${astStr.stringValue}';

  Lexer lexer = initLexer(File(filename).readAsStringSync());
  Parser parser = initParser(lexer);
  ASTNode node = parse(parser);
  await visit(runtime, node);

  return AnyNode();
}

/// STDOUT
ASTNode funcScrem(Runtime runtime, ASTNode self, List args) {
  for (int i = 0; i < args.length; i++) {
    ASTNode astArg = args[i];
    if (astArg is BinaryOpNode)
      visitBinaryOp(initRuntime(filePath), astArg).then((value) => astArg = value);

    if (astArg is ClassNode) {
      String classToString = '';

      astArg.classChildren.where((child) => (child as ASTNode) is VarDefNode).forEach((varDef) {
        classToString += '${(varDef as VarDefNode).variableName}: ${astToString((varDef as VarDefNode).variableValue)}\n';
      });

      print(classToString);
      return INITIALIZED_NOOP;
    }

    var str = astToString(astArg);

    if (str == null)
      throw UnexpectedTokenException('Screm must contain non-null arguments');

    print(str);
  }

  return INITIALIZED_NOOP;
}

// STDERR
ASTNode funcBeep(Runtime runtime, ASTNode self, List args) {
  for (int i = 0; i < args.length; i++) {
    ASTNode astArg = args[i];
    if (astArg is BinaryOpNode)
      visitBinaryOp(initRuntime(filePath), astArg).then((value) => astArg = value);

    if (astArg is ClassNode) {
      String classToString = '';

      astArg.classChildren.where((child) => (child as ASTNode) is VarDefNode).forEach((varDef) {
        classToString += '${(varDef as VarDefNode).variableName}: ${astToString((varDef as VarDefNode).variableValue)}\n';
      });

      stderr.write(classToString);
      return INITIALIZED_NOOP;
    }

    var str = astToString(astArg);

    if (str == null)
      throw UnexpectedTokenException('Screm must contain non-null arguments');

    stderr.write(str);
  }

  return INITIALIZED_NOOP;
}

/// STDIN
ASTNode funcMock(Runtime runtime, ASTNode self, List args) {
  var astString = StringNode();
  astString.stringValue =
      stdin.readLineSync(encoding: Encoding.getByName('utf-8')).trim();

  return astString;
}

/**
 * IO
 */
ASTNode funcExit(Runtime runtime, ASTNode self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_INT]);

  ASTNode exitAST = args[0];

  exit(exitAST.intVal);
  return null;
}

ASTNode funcRand(Runtime runtime, ASTNode self, List args) {
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
      int range = max.stringValue.codeUnitAt(i) - 65;
      int randVal = 65 + rand.nextInt(65);
      result += String.fromCharCode(randVal);
    }

    StringNode strNode = StringNode()..stringValue = result;
    return strNode;
  } else if (max is BoolNode) {
    BoolNode boolNode = BoolNode()..boolVal = Random().nextBool();
    return boolNode;
  }

  throw UnexpectedTypeException('The rand method only takes [String, double, int, and bool] arugment types');
}

/**
 * DATE AND TIME
 */
ASTNode dateClass(Runtime runtime) {
  var astObj = ClassNode();

  // ADD YEAR TO DATE OBJECT
  var astVarYear = VarDefNode();
  astVarYear.variableName = 'year';
  astVarYear.variableType = TypeNode();
  astVarYear.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntYear = IntNode();
  astIntYear.intVal = DateTime.now().year;
  astVarYear.variableValue = astIntYear;

  astObj.classChildren.add(astVarYear);

  // ADD MONTH TO DATE OBJECT
  var astVarMonth = VarDefNode();
  astVarMonth.variableName = 'month';
  astVarMonth.variableType = TypeNode();
  astVarMonth.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntMonth = IntNode();
  astIntMonth.intVal = DateTime.now().month;
  astVarMonth.variableValue = astIntMonth;

  astObj.classChildren.add(astVarMonth);

  // ADD DAYS TO DATE OBJECT
  var astVarDay = VarDefNode();
  astVarDay.variableName = 'day';
  astVarDay.variableType = TypeNode();
  astVarDay.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntDay = IntNode();
  astIntDay.intVal = DateTime.now().day;
  astVarDay.variableValue = astIntDay;

  astObj.classChildren.add(astVarDay);

  // ADD DAYS TO DATE OBJECT
  var astVarWeekDay = VarDefNode();
  astVarWeekDay.variableName = 'weekday';
  astVarWeekDay.variableType = TypeNode();
  astVarWeekDay.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntWeekDay = IntNode();
  astIntWeekDay.intVal = DateTime.now().weekday;
  astVarWeekDay.variableValue = astIntWeekDay;

  astObj.classChildren.add(astVarWeekDay);

  return astObj;
}

ASTNode timeClass(Runtime runtime) {
  var astObj = ClassNode();
  astObj.variableType = TypeNode();
  astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_CLASS);

  // ADD HOURS TO TIME OBJECT
  var astVarHour = VarDefNode();
  astVarHour.variableName = 'hour';
  astVarHour.variableType = TypeNode();
  astVarHour.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntHour = IntNode();
  astIntHour.intVal = DateTime.now().hour;
  astVarHour.variableValue = astIntHour;

  astObj.classChildren.add(astVarHour);

  // ADD MINUTES TO TIME OBJECT
  var astVarMinute = VarDefNode();
  astVarMinute.variableName = 'minute';
  astVarMinute.variableType = TypeNode();
  astVarMinute.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntMinute = IntNode();
  astIntMinute.intVal = DateTime.now().minute;
  astVarHour.variableValue = astIntMinute;

  astObj.classChildren.add(astVarMinute);

  // ADD SECONDS TO TIME OBJECT
  var astVarSeconds = VarDefNode();
  astVarSeconds.variableName = 'second';
  astVarSeconds.variableType = TypeNode();
  astVarSeconds.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntSeconds = IntNode();
  astIntSeconds.intVal = DateTime.now().second;
  astVarSeconds.variableValue = astIntSeconds;

  astObj.classChildren.add(astVarSeconds);

  // ADD MILLISECONDS TO TIME OBJECT
  var astVarMilliSeconds = VarDefNode();
  astVarMilliSeconds.variableName = 'milliSecond';
  astVarMilliSeconds.variableType = TypeNode();
  astVarMilliSeconds.variableType.typeValue =
      initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntMilliSeconds = IntNode();
  astIntMilliSeconds.intVal = DateTime.now().millisecond;
  astVarMilliSeconds.variableValue = astIntMilliSeconds;

  astObj.classChildren.add(astVarMilliSeconds);

  return astObj;
}

ASTNode doubleClass(Runtime runtime) {
  var astObj = ClassNode();

  // INFINITY
  var astVarInfinity = VarDefNode()
    ..variableName = 'infinity'
    ..variableType = TypeNode()
    ..variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_DOUBLE);

  var astInfinity = DoubleNode();
  astInfinity.doubleVal = 1 / 0;
  astVarInfinity.variableValue = astInfinity;

  astObj.classChildren.add(astVarInfinity);

  // -INFINITY
  var astVarNegInfinity = VarDefNode()
    ..variableName = 'negInfinity'
    ..variableType = TypeNode()
    ..variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_DOUBLE);

  var astNegInfinity = DoubleNode();
  astNegInfinity.doubleVal = -1 / 0;
  astVarNegInfinity.variableValue = astNegInfinity;

  astObj.classChildren.add(astVarNegInfinity);

  // NaN
  var astVarNaN = VarDefNode()
    ..variableName = 'nan'
    ..variableType = TypeNode()
    ..variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_DOUBLE);

  var astNaN = DoubleNode();
  astNaN.doubleVal = 0 / 0;

  astVarNaN.variableValue = astNaN;

  astObj.classChildren.add(astVarNaN);

  // MAXFINITE
  var astVarMaxFinite = VarDefNode()
    ..variableName = 'maxFinite'
    ..variableType = TypeNode()
    ..variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_DOUBLE);

  var astMaxFinite = DoubleNode();
  astMaxFinite.doubleVal = 1.7976931348623157e+308;

  astVarMaxFinite.variableValue = astMaxFinite;

  astObj.classChildren.add(astVarMaxFinite);

  // MINPOSITIVE
  var astVarMinPositive = VarDefNode()
    ..variableName = 'minPositive'
    ..variableType = TypeNode()
    ..variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_DOUBLE);

  var astMinPositive = DoubleNode();
  astMinPositive.doubleVal = 5e-324;

  astVarMinPositive.variableValue = astMinPositive;

  astObj.classChildren.add(astVarMinPositive);

  return astObj;
}

/**
 * HTTP
 */
Future<ASTNode> funcGet(Runtime runtime, ASTNode self, List args) async {
  if (args.length == 3)
    runtimeExpectArgs(args,
        [ASTType.AST_STRING, ASTType.AST_MAP, ASTType.AST_FUNC_DEFINITION]);
  else
    runtimeExpectArgs(args, [ASTType.AST_STRING, ASTType.AST_MAP]);

  String url = (args[0] as ASTNode).stringValue;
  Map headers = (args[1] as ASTNode).map;
  ASTNode funcDef;
  ASTNode funCall;

  if (args.length == 3) {
    funcDef = args[2];
    ASTNode funcCalExpr = VariableNode();
    funcCalExpr.variableName = funcDef.funcName;

    funCall = FuncCallNode();
    funCall.funcName = funcDef.funcName;
    funCall.funcCallExpression = funcCalExpr;
  }

  Map<String, String> head = {};
  headers.forEach((key, value) => head[key] = (value as ASTNode).stringValue);

  Response response = await get(url, headers: head);
  if (args.length == 3) await visitFuncCall(runtime, funCall);

  var astObj = ClassNode();
  astObj.variableType = TypeNode();
  astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_CLASS);

  // BODY
  var ast = VarDefNode();
  ast.variableName = 'body';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_STRING);

  var astVal = StringNode();
  astVal.stringValue = response.body;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // BODY BYTES
  ast = VarDefNode();
  ast.variableName = 'bodyBytes';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_LIST);

  var astListVal = ListNode();
  astListVal.listElements = response.bodyBytes;
  ast.variableValue = astListVal;

  astObj.classChildren.add(ast);

  // STATUS CODE
  ast = VarDefNode();
  ast.variableName = 'statusCode';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntVal = IntNode();
  astIntVal.intVal = response.statusCode;
  ast.variableValue = astIntVal;

  astObj.classChildren.add(ast);

  // CONTENT LENGTH
  ast = VarDefNode();
  ast.variableName = 'contentLength';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  astIntVal = IntNode();
  astIntVal.intVal = response.contentLength;
  ast.variableValue = astIntVal;

  astObj.classChildren.add(ast);

  // REASON PHRASE
  ast = VarDefNode();
  ast.variableName = 'reason';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_STRING);

  astVal = StringNode();
  astVal.stringValue = response.reasonPhrase;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // HEADERS
  ast = VarDefNode();
  ast.variableName = 'headers';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_MAP);

  var astMapVal = MapNode();
  astMapVal.map = response.headers;
  ast.variableValue = astMapVal;

  astObj.classChildren.add(ast);

  return astObj;
}

Future<ASTNode> funcPost(Runtime runtime, ASTNode self, List args) async {
  if (args.length == 4)
    runtimeExpectArgs(args, [
      ASTType.AST_STRING,
      ASTType.AST_MAP,
      ASTType.AST_MAP,
      ASTType.AST_FUNC_DEFINITION
    ]);
  else
    runtimeExpectArgs(
        args, [ASTType.AST_STRING, ASTType.AST_MAP, ASTType.AST_MAP]);

  String url = (args[0] as ASTNode).stringValue;
  Map bodyEarly = (args[1] as ASTNode).map;
  Map head = (args[2] as ASTNode).map;

  ASTNode funcDef;
  ASTNode funCall;

  if (args.length == 4) {
    funcDef = args[3];
    ASTNode funcCalExpr = VariableNode();
    funcCalExpr.variableName = funcDef.funcName;

    funCall = FuncCallNode();
    funCall.funcName = funcDef.funcName;
    funCall.funcCallExpression = funcCalExpr;
  }

  Map<String, String> body = {};
  bodyEarly.forEach((key, value) => body[key] = (value as ASTNode).stringValue);

  Map<String, String> headers = {};
  head.forEach((key, value) => headers[key] = (value as ASTNode).stringValue);

  Response response = await post(url, body: body, headers: headers);
  if (args.length == 4) await visitCompound(runtime, funCall);

  var astObj = ClassNode();
  astObj.variableType = TypeNode();
  astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_CLASS);

  // BODY
  var ast = VarDefNode();
  ast.variableName = 'body';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_STRING);

  var astVal = StringNode();
  astVal.stringValue = response.body;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // BODY BYTES
  ast = VarDefNode();
  ast.variableName = 'bodyBytes';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_LIST);

  var astListVal = ListNode();
  astListVal.listElements = response.bodyBytes;
  ast.variableValue = astListVal;

  astObj.classChildren.add(ast);

  // STATUS CODE
  ast = VarDefNode();
  ast.variableName = 'statusCode';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntVal = IntNode();
  astIntVal.intVal = response.statusCode;
  ast.variableValue = astIntVal;

  astObj.classChildren.add(ast);

  // CONTENT LENGTH
  ast = VarDefNode();
  ast.variableName = 'contentLength';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  astIntVal = IntNode();
  astVal.intVal = response.contentLength;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // REASON PHRASE
  ast = VarDefNode();
  ast.variableName = 'reason';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_STRING);

  astVal = StringNode();
  astVal.stringValue = response.reasonPhrase;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // HEADERS
  ast = VarDefNode();
  ast.variableName = 'headers';
  ast.variableType = TypeNode();
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_MAP);

  var astMapVal = MapNode();
  astMapVal.map = response.headers;
  ast.variableValue = astMapVal;

  astObj.classChildren.add(ast);

  return astObj;
}

ASTNode funcDecodeJson(Runtime runtime, ASTNode self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING]);

  String jsonString = (args[0] as ASTNode).stringValue;

  var decoded = jsonDecode(jsonString);
  ASTNode jsonAST;
  if (decoded is List)
    jsonAST = ListNode()..listElements = decoded;
  else
    jsonAST = MapNode()..map = jsonDecode(jsonString) as Map<String, dynamic>;

  return jsonAST;
}

ASTNode funcEncodeJson(Runtime runtime, ASTNode self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_MAP]);

  Map map = (args[0] as ASTNode).map;

  Map jsonMap = {};

  map.forEach((key, value) {
    ASTNode val = value;
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

  ASTNode jsonAST = StringNode()..stringValue = jsonEncode(jsonMap);

  return jsonAST;
}
