import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import 'package:Birb/core_types.dart';
import 'package:Birb/external.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';
import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/parser/data_type.dart';
import 'package:Birb/lexer/lexer.dart';
import 'package:Birb/parser/parser.dart';
import 'package:Birb/runtime/runtime.dart';

String filePath = '';
ASTNode INITIALIZED_NOOP;

Future<void> initStandards(Runtime runtime, String path) async {
  if (path != null) {
    filePath = path.replaceAllMapped(RegExp(r'(.+(?:/|\\))+.+\.birb'), (m) => m.group(1));
  }


  registerGlobalVariable(runtime, 'birbVer', StringNode()..stringValue = '0.0.1');

  registerGlobalVariable(runtime, 'Date', dateClass(runtime));
  registerGlobalVariable(runtime, 'double', doubleClass(runtime));
  registerGlobalVariable(runtime, 'List', listClass(runtime));
  registerGlobalVariable(runtime, 'Time', timeClass(runtime));

  // Functions
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

  final ASTNode astStr = args[0];
  if (astStr.stringValue.startsWith('birb:')) {
    final String fileName = astStr.stringValue.split(':')[1];
    final String ps = Platform.pathSeparator;

    final Lexer lexer = initLexer(File('${Directory.current.path}${ps}core$ps$fileName$ps$fileName.birb').readAsStringSync());
    final Parser parser = initParser(lexer);
    final ASTNode node = parse(parser);
    await visit(runtime, node);

    return AnyNode();
  } else if (astStr.stringValue.startsWith('dart:')) {
  final String fileName = astStr.stringValue.replaceAll('dart:', '');

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
      throw const UnexpectedTokenException('Cannot import non-birb files.');

    final Response response = await get(astStr.stringValue);
    final Lexer lexer = initLexer(response.body);
    final Parser parser = initParser(lexer);
    final ASTNode node = parse(parser);
    await visit(runtime, node);

    return AnyNode();
  }
  final String filename = '$filePath${Platform.pathSeparator}${astStr.stringValue}';

  final Lexer lexer = initLexer(File(filename).readAsStringSync());
  final Parser parser = initParser(lexer);
  final ASTNode node = parse(parser);
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
        classToString += '${varDef.variableName}: ${varDef.variableValue.toString()}\n';
      });

      stdout.write(classToString);
      return INITIALIZED_NOOP;
    }

    final str = astArg.toString();

    if (str == null)
      throw const UnexpectedTokenException('Screm must contain non-null arguments');

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
        classToString += '${varDef.variableName}: ${varDef.variableValue.toString()}\n';
      });

      print(classToString);
      return INITIALIZED_NOOP;
    }

    final str = astArg.toString();

    if (str == null)
      throw const UnexpectedTokenException('Screm must contain non-null arguments');

    print(str);
  }

  return INITIALIZED_NOOP;
}

ASTNode funcScremF(Runtime runtime, ASTNode self, List<ASTNode> args) {
  if (args[0] is! StringNode)
    throw UnexpectedTypeException('Error [Line ${self.lineNum}]: scremF expects the first parameter to be a String');

  final StringNode strAST = args[0];

    String str = strAST.toString();
    
    str = str.replaceAllMapped(RegExp(r'\{([0-9]+)\}'), (match) {
      final int index = int.parse(match.group(1));
      return args[index + 1].toString();
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
        classToString += '${varDef.variableName}: ${varDef.variableValue.toString()}\n';
      });

      stderr.write(classToString);
      return INITIALIZED_NOOP;
    }

    final str = astArg.toString();

    if (str == null)
      throw const UnexpectedTokenException('Screm must contain non-null arguments');

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
        classToString += '${varDef.variableName}: ${varDef.variableValue.toString()}\n';
      });

      stderr.write('$classToString\n');
      return INITIALIZED_NOOP;
    }

    final str = astArg.toString();

    if (str == null)
      throw const UnexpectedTokenException('Screm must contain non-null arguments');

    stderr.write('$str\n');
  }

  return INITIALIZED_NOOP;
}

/// STDIN
ASTNode funcMock(Runtime runtime, ASTNode self, List<ASTNode> args) {
  final astString = StringNode();
  astString.stringValue =
      stdin.readLineSync(encoding: Encoding.getByName('utf-8')).trim();

  return astString;
}

/// DATE AND TIME
ASTNode dateClass(Runtime runtime) {
  final astObj = ClassNode();

  // ADD YEAR TO DATE OBJECT
  final VarDefNode astVarYear = VarDefNode();
  astVarYear.variableName = 'year';
  astVarYear.variableType = TypeNode();
  astVarYear.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  final IntNode astIntYear = IntNode();
  astIntYear.intVal = DateTime.now().year;
  astVarYear.variableValue = astIntYear;

  astObj.classChildren.add(astVarYear);

  // ADD MONTH TO DATE OBJECT
  final VarDefNode astVarMonth = VarDefNode();
  astVarMonth.variableName = 'month';
  astVarMonth.variableType = TypeNode();
  astVarMonth.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  final IntNode astIntMonth = IntNode();
  astIntMonth.intVal = DateTime.now().month;
  astVarMonth.variableValue = astIntMonth;

  astObj.classChildren.add(astVarMonth);

  // ADD DAYS TO DATE OBJECT
  final VarDefNode astVarDay = VarDefNode();
  astVarDay.variableName = 'day';
  astVarDay.variableType = TypeNode();
  astVarDay.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  final IntNode astIntDay = IntNode();
  astIntDay.intVal = DateTime.now().day;
  astVarDay.variableValue = astIntDay;

  astObj.classChildren.add(astVarDay);

  // ADD DAYS TO DATE OBJECT
  final VarDefNode astVarWeekDay = VarDefNode();
  astVarWeekDay.variableName = 'weekday';
  astVarWeekDay.variableType = TypeNode();
  astVarWeekDay.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  final IntNode astIntWeekDay = IntNode();
  astIntWeekDay.intVal = DateTime.now().weekday;
  astVarWeekDay.variableValue = astIntWeekDay;

  astObj.classChildren.add(astVarWeekDay);

  return astObj;
}

ASTNode timeClass(Runtime runtime) {
  final ClassNode astObj = ClassNode();
  astObj.variableType = TypeNode();
  astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_CLASS);

  // ADD HOURS TO TIME OBJECT
  final VarDefNode astVarHour = VarDefNode();
  astVarHour.variableName = 'hour';
  astVarHour.variableType = TypeNode();
  astVarHour.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  final IntNode astIntHour = IntNode();
  astIntHour.intVal = DateTime.now().hour;
  astVarHour.variableValue = astIntHour;

  astObj.classChildren.add(astVarHour);

  // ADD MINUTES TO TIME OBJECT
  final VarDefNode astVarMinute = VarDefNode();
  astVarMinute.variableName = 'minute';
  astVarMinute.variableType = TypeNode();
  astVarMinute.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  final IntNode astIntMinute = IntNode();
  astIntMinute.intVal = DateTime.now().minute;
  astVarHour.variableValue = astIntMinute;

  astObj.classChildren.add(astVarMinute);

  // ADD SECONDS TO TIME OBJECT
  final VarDefNode astVarSeconds = VarDefNode();
  astVarSeconds.variableName = 'second';
  astVarSeconds.variableType = TypeNode();
  astVarSeconds.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  final IntNode astIntSeconds = IntNode();
  astIntSeconds.intVal = DateTime.now().second;
  astVarSeconds.variableValue = astIntSeconds;

  astObj.classChildren.add(astVarSeconds);

  // ADD MILLISECONDS TO TIME OBJECT
  final VarDefNode astVarMilliSeconds = VarDefNode();
  astVarMilliSeconds.variableName = 'milliSecond';
  astVarMilliSeconds.variableType = TypeNode();
  astVarMilliSeconds.variableType.typeValue =
      initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  final IntNode astIntMilliSeconds = IntNode();
  astIntMilliSeconds.intVal = DateTime.now().millisecond;
  astVarMilliSeconds.variableValue = astIntMilliSeconds;

  astObj.classChildren.add(astVarMilliSeconds);

  return astObj;
}

ASTNode doubleClass(Runtime runtime) {
  final ClassNode astObj = ClassNode();

  // INFINITY
  final VarDefNode astVarInfinity = VarDefNode()
    ..variableName = 'infinity'
    ..variableType = TypeNode()
    ..variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_DOUBLE);

  final DoubleNode astInfinity = DoubleNode();
  astInfinity.doubleVal = 1 / 0;
  astVarInfinity.variableValue = astInfinity;

  astObj.classChildren.add(astVarInfinity);

  // -INFINITY
  final VarDefNode astVarNegInfinity = VarDefNode()
    ..variableName = 'negInfinity'
    ..variableType = TypeNode()
    ..variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_DOUBLE);

  final DoubleNode astNegInfinity = DoubleNode();
  astNegInfinity.doubleVal = -1 / 0;
  astVarNegInfinity.variableValue = astNegInfinity;

  astObj.classChildren.add(astVarNegInfinity);

  // NaN
  final VarDefNode astVarNaN = VarDefNode()
    ..variableName = 'nan'
    ..variableType = TypeNode()
    ..variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_DOUBLE);

  final astNaN = DoubleNode();
  astNaN.doubleVal = 0 / 0;

  astVarNaN.variableValue = astNaN;

  astObj.classChildren.add(astVarNaN);

  // MAXFINITE
  final astVarMaxFinite = VarDefNode()
    ..variableName = 'maxFinite'
    ..variableType = TypeNode()
    ..variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_DOUBLE);

  final astMaxFinite = DoubleNode();
  astMaxFinite.doubleVal = 1.7976931348623157e+308;

  astVarMaxFinite.variableValue = astMaxFinite;

  astObj.classChildren.add(astVarMaxFinite);

  // MINPOSITIVE
  final astVarMinPositive = VarDefNode()
    ..variableName = 'minPositive'
    ..variableType = TypeNode()
    ..variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_DOUBLE);

  final astMinPositive = DoubleNode();
  astMinPositive.doubleVal = 5e-324;

  astVarMinPositive.variableValue = astMinPositive;

  astObj.classChildren.add(astVarMinPositive);

  return astObj;
}

ASTNode listClass(Runtime runtime) {
  final ClassNode astObj = ClassNode();

  astObj.classChildren.add(
      FuncDefNode()
        ..funcName = 'filled'
        ..funcPointer = listFilled
  );

  astObj.classChildren.add(
      FuncDefNode()
        ..funcName = 'empty'
        ..funcPointer = listEmpty
  );

  return astObj;
}

Future<ASTNode> funcVarFromString(Runtime runtime, ASTNode self, List<ASTNode> args) async {
    runtimeExpectArgs(args, [ASTType.AST_STRING]);

    return await getVarDefByName(runtime, getScope(runtime, args[0]), args[0].stringValue);
}
