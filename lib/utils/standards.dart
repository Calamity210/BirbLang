import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import 'AST.dart';
import 'data_type.dart';
import 'lexer.dart';
import 'parser.dart';
import 'runtime.dart';

AST INITIALIZED_NOOP;

void initStandards(Runtime runtime) async {
  registerGlobalVariable(runtime, 'birbVer', '0.0.1');
  registerGlobalFunction(runtime, 'screm', funcScrem);
  registerGlobalFunction(runtime, 'exit', funcExit);
  registerGlobalFunction(runtime, 'openFile', funcFileOpen);
  registerGlobalFunction(runtime, 'writeFile', funcFileWrite);
  registerGlobalFunction(runtime, 'input', funcInput);
  registerGlobalFunction(runtime, 'Date', funcDate);
  registerGlobalFunction(runtime, 'Time', funcTime);

  registerGlobalFutureFunction(runtime, 'import', funcInclude);
  registerGlobalFutureFunction(runtime, 'GET', funcGet);
  registerGlobalFutureFunction(runtime, 'POST', funcPost);
}

Future<AST> funcInclude(Runtime runtime, AST self, List args) async {
  runtimeExpectArgs(args, [ASTType.AST_STRING]);

  AST astStr = args[0];
  var filename = astStr.stringValue;

  var lexer = initLexer(File(filename).readAsStringSync());
  var parser = initParser(lexer);
  var node = parse(parser);
  var runtime = initRuntime();
  var ast = await visit(runtime, node);

  return ast;
}

/// STDOUT
AST funcScrem(Runtime runtime, AST self, List args) {
  for (int i = 0; i < args.length; i++) {
    AST astArg = args[i];
    if (astArg.type == ASTType.AST_BINARYOP)
      visitBinaryOp(initRuntime(), astArg).then((value) => astArg = value);
    var str = astToString(astArg);

    if (str == null) {
      print('Screm must contain non-null arguments');
      exit(1);
    }

    print(str);
  }

  return INITIALIZED_NOOP;
}

/// STDIN
AST funcInput(Runtime runtime, AST self, List args) {
  var astString = initAST(ASTType.AST_STRING);
  astString.stringValue =
      stdin.readLineSync(encoding: Encoding.getByName('utf-8')).trim();

  return astString;
}

/**
 * IO
 */
AST funcExit(Runtime runtime, AST self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_INT]);

  AST exitAST = args[0];

  exit(exitAST.intVal);
  return null;
}

AST objFileFuncRead(Runtime runtime, AST self, List args) {
  File f = self.classValue;
  var astString = initAST(ASTType.AST_STRING);

  astString.stringValue = f.readAsStringSync();
  return astString;
}

AST funcFileOpen(Runtime runtime, AST self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING, ASTType.AST_STRING]);

  var filename = (args[0] as AST).stringValue;
  FileMode mode;
  switch ((args[1] as AST).stringValue) {
    case 'READ':
      mode = FileMode.read;
      break;
    case 'WRITE':
      mode = FileMode.write;
      break;
    case 'APPEND':
      mode = FileMode.append;
      break;
    case 'WRITEONLY':
      mode = FileMode.writeOnly;
      break;
    case 'WRITEONLYAPPEND':
      mode = FileMode.writeOnlyAppend;
      break;
    default:
      print('No mode `${(args[1] as AST).stringValue}` found');
      exit(1);
  }

  File f = File(filename);
  AST astObj;

  f.open(mode: mode).then((value) {
    astObj = initAST(ASTType.AST_CLASS);
    astObj.variableType = initAST(ASTType.AST_TYPE);
    astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_CLASS);
    astObj.classValue = value;

    var fDefRead = initAST(ASTType.AST_FUNC_DEFINITION);
    fDefRead.funcName = 'read';
    fDefRead.fptr = objFileFuncRead;

    astObj.funcDefinitions = [];
    astObj.funcDefinitions.add(fDefRead);
  });
  return astObj;
}

AST funcFileWrite(Runtime runtime, AST self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING, ASTType.AST_CLASS]);

  var retAST = initAST(ASTType.AST_INT);
  retAST.intVal = 1;

  var line = (args[0] as AST).stringValue;
  File f = (args[1] as AST).classValue;

  f.writeAsStringSync(line);

  return retAST;
}

/**
 * DATE AND TIME
 */
AST funcDate(Runtime runtime, AST self, List args) {
  var astObj = initAST(ASTType.AST_CLASS);
  astObj.variableType = initAST(ASTType.AST_TYPE);
  astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_CLASS);

  // ADD YEAR TO DATE OBJECT
  var astVarYear = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarYear.variableName = 'year';
  astVarYear.variableType = initAST(ASTType.AST_TYPE);
  astVarYear.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntYear = initAST(ASTType.AST_INT);
  astIntYear.intVal = DateTime.now().year;
  astVarYear.variableValue = astIntYear;

  astObj.classChildren.add(astVarYear);

  // ADD MONTH TO DATE OBJECT
  var astVarMonth = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarMonth.variableName = 'month';
  astVarMonth.variableType = initAST(ASTType.AST_TYPE);
  astVarMonth.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntMonth = initAST(ASTType.AST_INT);
  astIntMonth.intVal = DateTime.now().month;
  astVarMonth.variableValue = astIntMonth;

  astObj.classChildren.add(astVarMonth);

  // ADD DAYS TO DATE OBJECT
  var astVarDay = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarDay.variableName = 'day';
  astVarDay.variableType = initAST(ASTType.AST_TYPE);
  astVarDay.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntDay = initAST(ASTType.AST_INT);
  astIntDay.intVal = DateTime.now().day;
  astVarDay.variableValue = astIntDay;

  astObj.classChildren.add(astVarDay);

  // ADD DAYS TO DATE OBJECT
  var astVarWeekDay = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarWeekDay.variableName = 'weekday';
  astVarWeekDay.variableType = initAST(ASTType.AST_TYPE);
  astVarWeekDay.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntWeekDay = initAST(ASTType.AST_INT);
  astIntWeekDay.intVal = DateTime.now().weekday;
  astIntWeekDay.variableValue = astIntWeekDay;

  astObj.classChildren.add(astVarWeekDay);

  return astObj;
}

AST funcTime(Runtime runtime, AST self, List args) {
  var astObj = initAST(ASTType.AST_CLASS);
  astObj.variableType = initAST(ASTType.AST_TYPE);
  astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_CLASS);

  // ADD HOURS TO TIME OBJECT
  var astVarHour = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarHour.variableName = 'hour';
  astVarHour.variableType = initAST(ASTType.AST_TYPE);
  astVarHour.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntHour = initAST(ASTType.AST_INT);
  astIntHour.intVal = DateTime.now().hour;
  astVarHour.variableValue = astIntHour;

  astObj.classChildren.add(astVarHour);

  // ADD MINUTES TO TIME OBJECT
  var astVarMinute = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarMinute.variableName = 'minute';
  astVarMinute.variableType = initAST(ASTType.AST_TYPE);
  astVarMinute.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntMinute = initAST(ASTType.AST_INT);
  astIntMinute.intVal = DateTime.now().minute;
  astVarHour.variableValue = astIntMinute;

  astObj.classChildren.add(astVarMinute);

  // ADD SECONDS TO TIME OBJECT
  var astVarSeconds = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarSeconds.variableName = 'second';
  astVarSeconds.variableType = initAST(ASTType.AST_TYPE);
  astVarSeconds.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntSeconds = initAST(ASTType.AST_INT);
  astIntSeconds.intVal = DateTime.now().second;
  astVarSeconds.variableValue = astIntSeconds;

  astObj.classChildren.add(astVarSeconds);

  // ADD MILLISECONDS TO TIME OBJECT
  var astVarMilliSeconds = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarMilliSeconds.variableName = 'milliSecond';
  astVarMilliSeconds.variableType = initAST(ASTType.AST_TYPE);
  astVarMilliSeconds.variableType.typeValue =
      initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntMilliSeconds = initAST(ASTType.AST_INT);
  astIntMilliSeconds.intVal = DateTime.now().millisecond;
  astVarMilliSeconds.variableValue = astIntMilliSeconds;

  astObj.classChildren.add(astVarMilliSeconds);

  return astObj;
}

/**
 * HTTP
 */

Future<AST> funcGet(Runtime runtime, AST self, List args) async {
  runtimeExpectArgs(args, [ASTType.AST_STRING, ASTType.AST_MAP]);

  String url = (args[0] as AST).stringValue;
  Map headers = (args[1] as AST).map;

  Map<String, String> head;
  headers.map((key, value) => head[key] = value);

  Response response = await get(url);

  var astObj = initAST(ASTType.AST_CLASS);
  astObj.variableType = initAST(ASTType.AST_TYPE);
  astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_CLASS);

  // BODY
  var ast = initAST(ASTType.AST_VARIABLE_DEFINITION);
  ast.variableName = 'body';
  ast.variableType = initAST(ASTType.AST_TYPE);
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_STRING);

  var astVal = initAST(ASTType.AST_STRING);
  astVal.stringValue = response.body;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // BODY BYTES
  ast = initAST(ASTType.AST_VARIABLE_DEFINITION);
  ast.variableName = 'bodyBytes';
  ast.variableType = initAST(ASTType.AST_TYPE);
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_LIST);

  astVal = initAST(ASTType.AST_LIST);
  astVal.listChildren = response.bodyBytes;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // STATUS CODE
  ast = initAST(ASTType.AST_VARIABLE_DEFINITION);
  ast.variableName = 'statusCode';
  ast.variableType = initAST(ASTType.AST_TYPE);
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  astVal = initAST(ASTType.AST_INT);
  astVal.intVal = response.statusCode;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // CONTENT LENGTH
  ast = initAST(ASTType.AST_VARIABLE_DEFINITION);
  ast.variableName = 'contentLength';
  ast.variableType = initAST(ASTType.AST_TYPE);
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  astVal = initAST(ASTType.AST_INT);
  astVal.intVal = response.contentLength;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // REASON PHRASE
  ast = initAST(ASTType.AST_VARIABLE_DEFINITION);
  ast.variableName = 'reason';
  ast.variableType = initAST(ASTType.AST_TYPE);
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_STRING);

  astVal = initAST(ASTType.AST_STRING);
  astVal.stringValue = response.reasonPhrase;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // HEADERS
  ast = initAST(ASTType.AST_VARIABLE_DEFINITION);
  ast.variableName = 'headers';
  ast.variableType = initAST(ASTType.AST_TYPE);
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_MAP);

  astVal = initAST(ASTType.AST_MAP);
  astVal.map = response.headers;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  return astObj;
}

Future<AST> funcPost(Runtime runtime, AST self, List args) async {
  runtimeExpectArgs(
      args, [ASTType.AST_STRING, ASTType.AST_MAP, ASTType.AST_MAP]);

  String url = (args[0] as AST).stringValue;
  Map bodyEarly = (args[1] as AST).map;
  Map head = (args[2] as AST).map;

//  if (body.type == ASTType.AST_LIST)
//    bodyList = body.listChildren;
//  else
//    bodyMap = body.map;

  Map<String, String> body = {};
  bodyEarly.forEach((key, value) => body[key] = (value as AST).stringValue);

  Map<String, String> headers = {};
  head.forEach((key, value) => headers[key] = (value as AST).stringValue);

  Response response = await post(url, body: body, headers: headers);

  var astObj = initAST(ASTType.AST_CLASS);
  astObj.variableType = initAST(ASTType.AST_TYPE);
  astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_CLASS);

  // BODY
  var ast = initAST(ASTType.AST_VARIABLE_DEFINITION);
  ast.variableName = 'body';
  ast.variableType = initAST(ASTType.AST_TYPE);
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_STRING);

  var astVal = initAST(ASTType.AST_STRING);
  astVal.stringValue = response.body;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // BODY BYTES
  ast = initAST(ASTType.AST_VARIABLE_DEFINITION);
  ast.variableName = 'bodyBytes';
  ast.variableType = initAST(ASTType.AST_TYPE);
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_LIST);

  astVal = initAST(ASTType.AST_LIST);
  astVal.listChildren = response.bodyBytes;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // STATUS CODE
  ast = initAST(ASTType.AST_VARIABLE_DEFINITION);
  ast.variableName = 'statusCode';
  ast.variableType = initAST(ASTType.AST_TYPE);
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  astVal = initAST(ASTType.AST_INT);
  astVal.intVal = response.statusCode;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // CONTENT LENGTH
  ast = initAST(ASTType.AST_VARIABLE_DEFINITION);
  ast.variableName = 'contentLength';
  ast.variableType = initAST(ASTType.AST_TYPE);
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  astVal = initAST(ASTType.AST_INT);
  astVal.intVal = response.contentLength;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // REASON PHRASE
  ast = initAST(ASTType.AST_VARIABLE_DEFINITION);
  ast.variableName = 'reason';
  ast.variableType = initAST(ASTType.AST_TYPE);
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_STRING);

  astVal = initAST(ASTType.AST_STRING);
  astVal.stringValue = response.reasonPhrase;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  // HEADERS
  ast = initAST(ASTType.AST_VARIABLE_DEFINITION);
  ast.variableName = 'headers';
  ast.variableType = initAST(ASTType.AST_TYPE);
  ast.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_MAP);

  astVal = initAST(ASTType.AST_MAP);
  astVal.map = response.headers;
  ast.variableValue = astVal;

  astObj.classChildren.add(ast);

  return astObj;
}
