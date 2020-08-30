import 'package:Birb/lexer/token.dart';
import 'package:Birb/parser/data_type.dart';
import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/scope.dart';

class ASTNode implements AST {
  @override
  AST parent;

  @override
  bool isClassChild;

  @override
  ASTType type;

  @override
  DataType typeValue;

  @override
  int lineNum;

  @override
  Scope scope;

  @override
  AST get assertExpression => throw Exception('Not part of $runtimeType => $type');
  @override
  set assertExpression(AST value) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get ast => throw Exception('Not part of $runtimeType => $type');
  @override
  set ast(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get binaryOpLeft => throw Exception('Not part of $runtimeType => $type');
  @override
  set binaryOpLeft(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get binaryOpRight => throw Exception('Not part of $runtimeType => $type');
  @override
  set binaryOpRight(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  Token get binaryOperator => throw Exception('Not part of $runtimeType => $type');
  @override
  set binaryOperator(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  bool get boolVal => throw Exception('Not part of $runtimeType => $type');
  @override
  set boolVal(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  List get classChildren => throw Exception('Not part of $runtimeType => $type');
  @override
  set classChildren(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  List get compChildren => throw Exception('Not part of $runtimeType => $type');
  @override
  set compChildren(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  List get compoundValue => throw Exception('Not part of $runtimeType => $type');
  @override
  set compoundValue(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  double get doubleVal => throw Exception('Not part of $runtimeType => $type');
  @override
  set doubleVal(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get elseBody => throw Exception('Not part of $runtimeType => $type');
  @override
  set elseBody(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  List get enumElements => throw Exception('Not part of $runtimeType => $type');
  @override
  set enumElements(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get forBody => throw Exception('Not part of $runtimeType => $type');
  @override
  set forBody(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get forChangeStatement => throw Exception('Not part of $runtimeType => $type');
  @override
  set forChangeStatement(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get forConditionStatement => throw Exception('Not part of $runtimeType => $type');
  @override
  set forConditionStatement(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get forInitStatement => throw Exception('Not part of $runtimeType => $type');
  @override
  set forInitStatement(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  List get funcCallArgs => throw Exception('Not part of $runtimeType => $type');
  @override
  set funcCallArgs(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get funcCallExpression => throw Exception('Not part of $runtimeType => $type');
  @override
  set funcCallExpression(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  List get funcDefArgs => throw Exception('Not part of $runtimeType => $type');
  @override
  set funcDefArgs(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get funcDefBody => throw Exception('Not part of $runtimeType => $type');
  @override
  set funcDefBody(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get funcDefType => throw Exception('Not part of $runtimeType => $type');
  @override
  set funcDefType(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  List get funcDefinitions => throw Exception('Not part of $runtimeType => $type');
  @override
  set funcDefinitions(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  String get funcName => throw Exception('Not part of $runtimeType => $type');
  @override
  set funcName(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AstFuncPointer get funcPointer => throw Exception('Not part of $runtimeType => $type');
  @override
  set funcPointer(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AstFutureFuncPointer get futureFuncPointer => throw Exception('Not part of $runtimeType => $type');
  @override
  set futureFuncPointer(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get ifBody => throw Exception('Not part of $runtimeType => $type');
  @override
  set ifBody(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get ifElse => throw Exception('Not part of $runtimeType => $type');
  @override
  set ifElse(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get ifExpression => throw Exception('Not part of $runtimeType => $type');
  @override
  set ifExpression(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  int get intVal => throw Exception('Not part of $runtimeType => $type');
  @override
  set intVal(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  bool get isFinal => throw Exception('Not part of $runtimeType => $type');
  @override
  set isFinal(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get iterateFunction => throw Exception('Not part of $runtimeType => $type');
  @override
  set iterateFunction(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get iterateIterable => throw Exception('Not part of $runtimeType => $type');
  @override
  set iterateIterable(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get listAccessPointer => throw Exception('Not part of $runtimeType => $type');
  @override
  set listAccessPointer(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  List get listElements => throw Exception('Not part of $runtimeType => $type');
  @override
  set listElements(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  Map<String, dynamic> get map => throw Exception('Not part of $runtimeType => $type');
  @override
  set map(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get returnValue => throw Exception('Not part of $runtimeType => $type');
  @override
  set returnValue(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get savedFuncCall => throw Exception('Not part of $runtimeType => $type');
  @override
  set savedFuncCall(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  StringBuffer get strBuffer => throw Exception('Not part of $runtimeType => $type');
  @override
  set strBuffer(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  String get stringValue => throw Exception('Not part of $runtimeType => $type');
  @override
  set stringValue(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  Map<AST, AST> get switchCases => throw Exception('Not part of $runtimeType => $type');
  @override
  set switchCases(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get switchDefault => throw Exception('Not part of $runtimeType => $type');
  @override
  set switchDefault(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get switchExpression => throw Exception('Not part of $runtimeType => $type');
  @override
  set switchExpression(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get ternaryBody => throw Exception('Not part of $runtimeType => $type');
  @override
  set ternaryBody(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get ternaryElseBody => throw Exception('Not part of $runtimeType => $type');
  @override
  set ternaryElseBody(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get ternaryExpression => throw Exception('Not part of $runtimeType => $type');
  @override
  set ternaryExpression(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get unaryOpRight => throw Exception('Not part of $runtimeType => $type');
  @override
  set unaryOpRight(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  Token get unaryOperator => throw Exception('Not part of $runtimeType => $type');
  @override
  set unaryOperator(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get variableAssignmentLeft => throw Exception('Not part of $runtimeType => $type');
  @override
  set variableAssignmentLeft(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  String get variableName => throw Exception('Not part of $runtimeType => $type');
  @override
  set variableName(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get variableType => throw Exception('Not part of $runtimeType => $type');
  @override
  set variableType(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get variableValue => throw Exception('Not part of $runtimeType => $type');
  @override
  set variableValue(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get whileBody => throw Exception('Not part of $runtimeType => $type');
  @override
  set whileBody(_) => throw Exception('Not part of $runtimeType => $type');

  @override
  AST get whileExpression => throw Exception('Not part of $runtimeType => $type');
  @override
  set whileExpression(_) => throw Exception('Not part of $runtimeType => $type');
}
