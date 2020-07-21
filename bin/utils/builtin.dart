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
  runtimeRegisterGlobalFunction(runtime, 'openFile', funcFileOpen);
  runtimeRegisterGlobalFunction(runtime, 'writeFile', funcFileWrite);
  runtimeRegisterGlobalFunction(runtime, 'input', funcInput);
  runtimeRegisterGlobalFunction(runtime, 'toBinary', funcToBinary);
  runtimeRegisterGlobalFunction(runtime, 'toOct', funcToOct);
  runtimeRegisterGlobalFunction(runtime, 'toDecimal', funcToDec);
  runtimeRegisterGlobalFunction(runtime, 'toHex', funcToHex);
  runtimeRegisterGlobalFunction(runtime, 'time', funcTime);
}

AST funcScrem(Runtime runtime, AST self, DynamicList args) {
  for (int i = 0; i < args.size; i++) {
    AST astArg = args.items[i];
    var str = astToString(astArg);

    if (str == null) {
      print('Screm must contain non-null arguments');
      exit(1);
    }

    print(str);
  }

  return INITIALIZED_NOOP;
}

AST funcInclude(Runtime runtime, AST self, DynamicList args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING]);

  AST astStr = args.items[0];
  var filename = astStr.stringValue;

  var lexer = initLexer(File(filename).readAsStringSync());
  var parser = initParser(lexer);
  var node = parse(parser);

  return node;
}

AST objFileFuncRead(Runtime runtime, AST self, DynamicList args) {
  File f = self.objectValue;
  var astString = initAST(ASTType.AST_STRING);

  astString.stringValue = f.readAsStringSync();
  return astString;
}

AST funcFileOpen(Runtime runtime, AST self, DynamicList args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING, ASTType.AST_STRING]);

  var filename = (args.items[0] as AST).stringValue;
  FileMode mode;
  switch ((args.items[1] as AST).stringValue) {
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
      print('No mode `${(args.items[1] as AST).stringValue}` found');
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

    astObj.funcDefinitions = initDynamicList(0);
    dynamicListAppend(astObj.funcDefinitions, fDefRead);
  });
  return astObj;
}

AST funcFileWrite(Runtime runtime, AST self, DynamicList args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING, ASTType.AST_OBJECT]);

  var retAST = initAST(ASTType.AST_INT);
  retAST.intVal = 1;

  var line = (args.items[0] as AST).stringValue;
  File f = (args.items[1] as AST).objectValue;

  f.writeAsStringSync(line);

  return retAST;
}

AST funcInput(Runtime runtime, AST self, DynamicList args) {
  var astString = initAST(ASTType.AST_STRING);
  astString.stringValue = stdin
      .readLineSync(encoding: Encoding.getByName('utf-8'))
      .trim();

  return astString;
}

AST funcToBinary(Runtime runtime, AST self, DynamicList args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING]);
  var str = (args.items[0] as AST).stringValue;
  var binarys = str.codeUnits.map((e) => e.toRadixString(2));

  var astList = initAST(ASTType.AST_LIST);
  astList.listChildren = initDynamicList(0);

  for (String binary in binarys) {
    dynamicListAppend(astList.listChildren, binary);
  }

  return astList;
}

AST funcToOct(Runtime runtime, AST self, DynamicList args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING]);
  var str = (args.items[0] as AST).stringValue;
  var octS = str.codeUnits.map((e) => e.toRadixString(8));

  var astList = initAST(ASTType.AST_LIST);
  astList.listChildren = initDynamicList(0);

  for (String oct in octS) {
    dynamicListAppend(astList.listChildren, oct);
  }

  return astList;
}

AST funcToHex(Runtime runtime, AST self, DynamicList args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING]);
  var str = (args.items[0] as AST).stringValue;
  var hexS = str.codeUnits.map((e) => e.toRadixString(16));

  var astList = initAST(ASTType.AST_LIST);
  astList.listChildren = initDynamicList(0);

  for (String hex in hexS) {
    dynamicListAppend(astList.listChildren, hex);
  }

  return astList;
}

AST funcToDec(Runtime runtime, AST self, DynamicList args) {
  runtimeExpectArgs(args, [ASTType.AST_STRING]);
  var str = (args.items[0] as AST).stringValue;

  var astList = initAST(ASTType.AST_LIST);
  astList.listChildren = initDynamicList(0);

  var decimals = str.codeUnits;
  for (int decimal in decimals) {
    dynamicListAppend(astList.listChildren, decimal);
  }

  return astList;
}

AST funcTime(Runtime runtime, AST self, DynamicList args) {
  var astObj = initAST(ASTType.AST_OBJECT);
  astObj.variableType = initAST(ASTType.AST_TYPE);
  astObj.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_OBJECT);

  var astVar = initAST(ASTType.AST_VARIABLE_DEFINITION);
  astVar.variableName = 'seconds';
  astVar.variableType = initAST(ASTType.AST_TYPE);
  astVar.variableType.typeValue = initDataTypeAs(DATATYPE.DATA_TYPE_INT);

  var astInt = initAST(ASTType.AST_INT);
  astInt.intVal = DateTime.now().second;
  astVar.variableValue = astInt;

  dynamicListAppend(astObj.objectChildren, astVar);

  return astObj;
}
