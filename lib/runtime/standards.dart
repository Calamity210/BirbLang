import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:Birb/external/convert.dart';
import 'package:Birb/external/http.dart';
import 'package:Birb/external/io.dart';
import 'package:Birb/external/math.dart';
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
  if (path != null) {
    filePath = path.replaceAllMapped(RegExp(r'(.+(?:/|\\))+.+\.birb'), (m) => m.group(1));
  }
  registerGlobalVariable(
      runtime, 'birbVer', StringNode()..stringValue = '0.0.1');

  // Date class
  registerGlobalVariable(runtime, 'Date', dateClass(runtime));

  // Double class
  registerGlobalVariable(runtime, 'double', doubleClass(runtime));

  // Time class
  registerGlobalVariable(runtime, 'Time', timeClass(runtime));

  // functions
  registerGlobalFunction(runtime, 'screm', funcScrem);
  registerGlobalFunction(runtime, 'scremLn', funcScremLn);
  registerGlobalFunction(runtime, 'scremF', funcScremF);
  registerGlobalFunction(runtime, 'beep', funcBeep);
  registerGlobalFunction(runtime, 'beepLn', funcBeepLn);
  registerGlobalFunction(runtime, 'mock', funcMock);

  registerGlobalFutureFunction(runtime, 'grab', funcGrab);
  registerGlobalFutureFunction(runtime, 'variableFromString', funcVarFromString);
}

Future<ASTNode> funcGrab(Runtime runtime, ASTNode self, List<ASTNode> args) async {
  runtimeExpectArgs(args, [ASTType.AST_STRING]);

  ASTNode astStr = args[0];
  if (astStr.stringValue.startsWith('birb:')) {
    String fileName = astStr.stringValue.split(':')[1];

    Lexer lexer = initLexer(File('${Directory.current.path}/core/$fileName/$fileName.birb').readAsStringSync());
    Parser parser = initParser(lexer);
    ASTNode node = parse(parser);
    await visit(runtime, node);

    return AnyNode();
  } else if (astStr.stringValue.startsWith('dart:')) {
  String fileName = astStr.stringValue.replaceAll('dart:', '');

    switch (fileName) {
      case 'convert':
        registerConvert(runtime);
        break;
      case 'io':
        registerIO(runtime);
        break;
      case 'http':
        registerHTTP(runtime);
        break;
      case 'math':
        registerMath(runtime);
        break;
      default:
        throw UnexpectedTokenException('Error [Line ${self.lineNum}]:Dart file $fileName no found.');
    }

    return INITIALIZED_NOOP;
  } else if (astStr.stringValue.startsWith(RegExp('https?://'))) {
    if (!astStr.stringValue.endsWith('.birb'))
      throw UnexpectedTokenException('Cannot import non-birb files.');

    Response response = await get(astStr.stringValue);
    Lexer lexer = initLexer(response.body);
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
ASTNode funcScrem(Runtime runtime, ASTNode self, List<ASTNode> args) {
  for (int i = 0; i < args.length; i++) {
    ASTNode astArg = args[i];
    if (astArg is BinaryOpNode)
      visitBinaryOp(initRuntime(filePath), astArg).then((value) => astArg = value);

    if (astArg is ClassNode) {
      String classToString = '';

      astArg.classChildren.whereType<VarDefNode>().forEach((varDef) {
        classToString += '${(varDef).variableName}: ${astToString((varDef).variableValue)}\n';
      });

      stdout.write(classToString);
      return INITIALIZED_NOOP;
    }

    var str = astToString(astArg);

    if (str == null)
      throw UnexpectedTokenException('Screm must contain non-null arguments');

    stdout.write(str);
  }

  return INITIALIZED_NOOP;
}

/// Screm, but prints linefeed (newline at the end)
ASTNode funcScremLn(Runtime runtime, ASTNode self, List<ASTNode> args) {
  for (int i = 0; i < args.length; i++) {
    ASTNode astArg = args[i];
    if (astArg is BinaryOpNode)
      visitBinaryOp(initRuntime(filePath), astArg).then((value) => astArg = value);

    if (astArg is ClassNode) {
      String classToString = '';

      astArg.classChildren.whereType<VarDefNode>().forEach((varDef) {
        classToString += '${varDef.variableName}: ${astToString(varDef.variableValue)}\n';
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

ASTNode funcScremF(Runtime runtime, ASTNode self, List<ASTNode> args) {
  if (args[0] is! StringNode)
    throw UnexpectedTypeException('Error [Line ${self.lineNum}]: scremF expects the first parameter to be a String');

  StringNode strAST = args[0];

    String str = astToString(strAST);
    
    str = str.replaceAllMapped(RegExp(r'\{([0-9]+)\}'), (match) {
      int index = int.parse(match.group(1));
      return astToString(args[index + 1]);
    });

    str = str.replaceAll(r'\{', '\{').replaceAll(r'\}', r'}');

    if (str == null)
      throw UnexpectedTokenException('Error [Line ${self.lineNum}]: Screm must contain non-null arguments');

    stdout.write(str);

  return INITIALIZED_NOOP;
}

// STDERR
ASTNode funcBeep(Runtime runtime, ASTNode self, List<ASTNode> args) {
  for (int i = 0; i < args.length; i++) {
    ASTNode astArg = args[i];
    if (astArg is BinaryOpNode)
      visitBinaryOp(initRuntime(filePath), astArg).then((value) => astArg = value);

    if (astArg is ClassNode) {
      String classToString = '';

      astArg.classChildren.whereType<VarDefNode>().forEach((varDef) {
        classToString += '${(varDef).variableName}: ${astToString((varDef).variableValue)}\n';
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

// Beep, but prints a newline at the end
ASTNode funcBeepLn(Runtime runtime, ASTNode self, List<ASTNode> args) {
  for (int i = 0; i < args.length; i++) {
    ASTNode astArg = args[i];
    if (astArg is BinaryOpNode)
      visitBinaryOp(initRuntime(filePath), astArg).then((value) => astArg = value);

    if (astArg is ClassNode) {
      String classToString = '';

      astArg.classChildren.whereType<VarDefNode>().forEach((varDef) {
        classToString += '${(varDef).variableName}: ${astToString((varDef).variableValue)}\n';
      });

      stderr.write('$classToString\n');
      return INITIALIZED_NOOP;
    }

    var str = astToString(astArg);

    if (str == null)
      throw UnexpectedTokenException('Screm must contain non-null arguments');

    stderr.write('$str\n');
  }

  return INITIALIZED_NOOP;
}

/// STDIN
ASTNode funcMock(Runtime runtime, ASTNode self, List<ASTNode> args) {
  var astString = StringNode();
  astString.stringValue =
      stdin.readLineSync(encoding: Encoding.getByName('utf-8')).trim();

  return astString;
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

Future<ASTNode> funcVarFromString(Runtime runtime, ASTNode self, List<ASTNode> args) async {
    runtimeExpectArgs(args, [ASTType.AST_STRING]);

    return await getVarDefByName(runtime, getScope(runtime, args[0]), args[0].stringValue);
}
