import 'dart:convert';
import 'dart:io';

import 'AST.dart';
import 'data_type.dart';
import 'dynamic_list.dart';
import 'lexer.dart';
import 'parser.dart';
import 'runtime.dart';

AST INITIALIZED_NOOP;

void initBuiltins(Runtime runtime) {
  runtimeRegisterGlobalVariable(runtime, 'ver', '0.0.1');

  runtimeRegisterGlobalFunction(runtime, 'include', funcInclude);
  runtimeRegisterGlobalFunction(runtime, 'screm', funcScrem);
  runtimeRegisterGlobalFunction(runtime, 'exit', funcExit);
  runtimeRegisterGlobalFunction(runtime, 'openFile', funcFileOpen);
  runtimeRegisterGlobalFunction(runtime, 'writeFile', funcFileWrite);
  runtimeRegisterGlobalFunction(runtime, 'input', funcInput);
  runtimeRegisterGlobalFunction(runtime, 'DateTime', funcDateTime);
  runtimeRegisterGlobalFunction(runtime, 'Date', funcDate);
  runtimeRegisterGlobalFunction(runtime, 'Time', funcTime);
}

AST funcScrem(Runtime runtime, AST self, List args) {
  for (int i = 0; i < args.length; i++) {
    AST astArg = args[i];
    var str = astToString(astArg);

    if (str == null) {
      print('Screm must contain non-null arguments');
      exit(1);
    }

    print(str);
  }

  return INITIALIZED_NOOP;
}

AST funcExit(Runtime runtime, AST self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_INT]);

  AST exitAST = args[0];

  exit(exitAST.intVal);
}

AST funcInclude(Runtime runtime, AST self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING]);

  AST astStr = args[0];
  var filename = astStr.stringValue;

  var lexer = initLexer(File(filename).readAsStringSync());
  var parser = initParser(lexer);
  var node = parse(parser);

  return node;
}

AST objFileFuncRead(Runtime runtime, AST self, List args) {
  File f = self.objectValue;
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
    astObj = initAST(ASTType.AST_OBJECT);
    astObj.variableType = initAST(ASTType.AST_TYPE);
    astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_OBJECT);
    astObj.objectValue = value;

    var fDefRead = initAST(ASTType.AST_FUNC_DEFINITION);
    fDefRead.funcName = 'read';
    fDefRead.fptr = objFileFuncRead;

    astObj.funcDefinitions = [];
    astObj.funcDefinitions.add( fDefRead);
  });
  return astObj;
}

AST funcFileWrite(Runtime runtime, AST self, List args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING, ASTType.AST_OBJECT]);

  var retAST = initAST(ASTType.AST_INT);
  retAST.intVal = 1;

  var line = (args[0] as AST).stringValue;
  File f = (args[1] as AST).objectValue;

  f.writeAsStringSync(line);

  return retAST;
}

AST funcInput(Runtime runtime, AST self, List args) {
  var astString = initAST(ASTType.AST_STRING);
  astString.stringValue =
      stdin.readLineSync(encoding: Encoding.getByName('utf-8')).trim();

  return astString;
}

AST funcDate(Runtime runtime, AST self, List args) {
  var astObj = initAST(ASTType.AST_OBJECT);
  astObj.variableType = initAST(ASTType.AST_TYPE);
  astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_OBJECT);

  // ADD YEAR TO DATE OBJECT
  var astVarYear = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarYear.variableName = 'year';
  astVarYear.variableType = initAST(ASTType.AST_TYPE);
  astVarYear.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntYear = initAST(ASTType.AST_INT);
  astIntYear.intVal = DateTime.now().year;
  astVarYear.variableValue = astIntYear;

  astObj.objectChildren.add( astVarYear);

  // ADD MONTH TO DATE OBJECT
  var astVarMonth = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarMonth.variableName = 'month';
  astVarMonth.variableType = initAST(ASTType.AST_TYPE);
  astVarMonth.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntMonth = initAST(ASTType.AST_INT);
  astIntMonth.intVal = DateTime.now().month;
  astVarMonth.variableValue = astIntMonth;

  astObj.objectChildren.add( astVarMonth);

  // ADD DAYS TO DATE OBJECT
  var astVarDay = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarDay.variableName = 'day';
  astVarDay.variableType = initAST(ASTType.AST_TYPE);
  astVarDay.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntDay = initAST(ASTType.AST_INT);
  astIntDay.intVal = DateTime.now().day;
  astVarDay.variableValue = astIntDay;

  astObj.objectChildren.add( astVarDay);

  // ADD DAYS TO DATE OBJECT
  var astVarWeekDay = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarWeekDay.variableName = 'weekday';
  astVarWeekDay.variableType = initAST(ASTType.AST_TYPE);
  astVarWeekDay.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntWeekDay = initAST(ASTType.AST_INT);
  astIntWeekDay.intVal = DateTime.now().weekday;
  astIntWeekDay.variableValue = astIntWeekDay;

  astObj.objectChildren.add( astVarWeekDay);

  return astObj;
}

AST funcTime(Runtime runtime, AST self, List args) {
  var astObj = initAST(ASTType.AST_OBJECT);
  astObj.variableType = initAST(ASTType.AST_TYPE);
  astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_OBJECT);

  // ADD HOURS TO TIME OBJECT
  var astVarHour = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarHour.variableName = 'hour';
  astVarHour.variableType = initAST(ASTType.AST_TYPE);
  astVarHour.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntHour = initAST(ASTType.AST_INT);
  astIntHour.intVal = DateTime.now().hour;
  astVarHour.variableValue = astIntHour;

  astObj.objectChildren.add( astVarHour);

  // ADD MINUTES TO TIME OBJECT
  var astVarMinute = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarMinute.variableName = 'minute';
  astVarMinute.variableType = initAST(ASTType.AST_TYPE);
  astVarMinute.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntMinute = initAST(ASTType.AST_INT);
  astIntMinute.intVal = DateTime.now().minute;
  astVarHour.variableValue = astIntMinute;

  astObj.objectChildren.add( astVarMinute);

  // ADD SECONDS TO TIME OBJECT
  var astVarSeconds = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarSeconds.variableName = 'second';
  astVarSeconds.variableType = initAST(ASTType.AST_TYPE);
  astVarSeconds.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntSeconds = initAST(ASTType.AST_INT);
  astIntSeconds.intVal = DateTime.now().second;
  astVarSeconds.variableValue = astIntSeconds;

  astObj.objectChildren.add( astVarSeconds);

  // ADD MILLISECONDS TO TIME OBJECT
  var astVarMilliSeconds = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarMilliSeconds.variableName = 'milliSecond';
  astVarMilliSeconds.variableType = initAST(ASTType.AST_TYPE);
  astVarMilliSeconds.variableType.typeValue =
      initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntMilliSeconds = initAST(ASTType.AST_INT);
  astIntMilliSeconds.intVal = DateTime.now().millisecond;
  astVarMilliSeconds.variableValue = astIntMilliSeconds;

  astObj.objectChildren.add( astVarMilliSeconds);

  return astObj;
}

AST funcDateTime(Runtime runtime, AST self, List args) {
  var astObj = initAST(ASTType.AST_OBJECT);
  astObj.variableType = initAST(ASTType.AST_TYPE);
  astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_OBJECT);

  // ADD YEAR TO DATETIME OBJECT
  var astVarYear = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarYear.variableName = 'year';
  astVarYear.variableType = initAST(ASTType.AST_TYPE);
  astVarYear.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntYear = initAST(ASTType.AST_INT);
  astIntYear.intVal = DateTime.now().year;
  astVarYear.variableValue = astIntYear;

  astObj.objectChildren.add( astVarYear);

  // ADD MONTH TO DATETIME OBJECT
  var astVarMonth = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarMonth.variableName = 'month';
  astVarMonth.variableType = initAST(ASTType.AST_TYPE);
  astVarMonth.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntMonth = initAST(ASTType.AST_INT);
  astIntMonth.intVal = DateTime.now().month;
  astVarMonth.variableValue = astIntMonth;

  astObj.objectChildren.add( astVarMonth);

  // ADD DAYS TO DATETIME OBJECT
  var astVarDay = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarDay.variableName = 'day';
  astVarDay.variableType = initAST(ASTType.AST_TYPE);
  astVarDay.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntDay = initAST(ASTType.AST_INT);
  astIntDay.intVal = DateTime.now().day;
  astVarDay.variableValue = astIntDay;

  astObj.objectChildren.add( astVarDay);

  // ADD WEEKDAYS TO DATETIME OBJECT
  var astVarWeekDay = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarWeekDay.variableName = 'weekday';
  astVarWeekDay.variableType = initAST(ASTType.AST_TYPE);
  astVarWeekDay.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntWeekDay = initAST(ASTType.AST_INT);
  astIntWeekDay.intVal = DateTime.now().weekday;
  astIntWeekDay.variableValue = astIntWeekDay;

  astObj.objectChildren.add( astVarWeekDay);

  // ADD HOURS TO DATETIME OBJECT
  var astVarHour = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarHour.variableName = 'hour';
  astVarHour.variableType = initAST(ASTType.AST_TYPE);
  astVarHour.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntHour = initAST(ASTType.AST_INT);
  astIntHour.intVal = DateTime.now().hour;
  astVarHour.variableValue = astIntHour;

  astObj.objectChildren.add( astVarHour);

  // ADD MINUTES TO DATETIME OBJECT
  var astVarMinute = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarMinute.variableName = 'minute';
  astVarMinute.variableType = initAST(ASTType.AST_TYPE);
  astVarMinute.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntMinute = initAST(ASTType.AST_INT);
  astIntMinute.intVal = DateTime.now().minute;
  astVarMinute.variableValue = astIntMinute;

  astObj.objectChildren.add( astVarMinute);

  // ADD SECONDS TO DATETIME OBJECT
  var astVarSeconds = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarSeconds.variableName = 'second';
  astVarSeconds.variableType = initAST(ASTType.AST_TYPE);
  astVarSeconds.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntSeconds = initAST(ASTType.AST_INT);
  astIntSeconds.intVal = DateTime.now().second;
  astVarSeconds.variableValue = astIntSeconds;

  astObj.objectChildren.add( astVarSeconds);

  // ADD MILLISECONDS TO DATETIME OBJECT
  var astVarMilliSeconds = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVarMilliSeconds.variableName = 'milliSecond';
  astVarMilliSeconds.variableType = initAST(ASTType.AST_TYPE);
  astVarMilliSeconds.variableType.typeValue =
      initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astIntMilliSeconds = initAST(ASTType.AST_INT);
  astIntMilliSeconds.intVal = DateTime.now().millisecond;
  astVarMilliSeconds.variableValue = astIntMilliSeconds;

  astObj.objectChildren.add( astVarMilliSeconds);

  return astObj;
}
