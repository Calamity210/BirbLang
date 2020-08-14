import 'package:Birb/utils/AST.dart';

class UndefinedMethodException implements Exception {
  String message;
  UndefinedMethodException(this.message);

  @override
  String toString() => 'UndefinedMethodException: $message';
}

class UndefinedVariableException implements Exception {
  String message;
  UndefinedVariableException(this.message);

  @override
  String toString() => 'UndefinedVariableException: $message';
}

class SettingUndefinedVariableException implements Exception {
  String message;
  SettingUndefinedVariableException(this.message);

  @override
  String toString() => 'SettingUndefinedVariableException: $message';
}

class MultipleVariableDefinitionsException implements Exception {
  String message;
  MultipleVariableDefinitionsException(this.message);

  @override
  String toString() => 'MultipleVariableDefinitionsException: $message';
}

class ReassigningFinalVariableException implements Exception {
  String message;
  ReassigningFinalVariableException(this.message);

  @override
  String toString() => 'ReassigningFinalVariableException: $message';
}

class UnexpectedTypeException implements Exception {
  String message;
  UnexpectedTypeException(this.message);

  @override
  String toString() => 'InvalidTypeException: $message';
}

class MapEntryNotFoundException implements Exception {
  String message;
  MapEntryNotFoundException(this.message);

  @override
  String toString() => 'MapEntryNotFoundException: $message';
}

class RangeException implements Exception {
  String message;
  RangeException(this.message);

  @override
  String toString() => 'RangeException: $message';
}


class InvalidArgumentsException implements Exception {
  String message;
  InvalidArgumentsException(this.message);

  @override
  String toString() => 'InvalidArgumentsException: $message';
}

class UncaughtStatementException implements Exception {
  String message;
  UncaughtStatementException(this.message);

  @override
  String toString() => 'UncaughtStatementException: $message';
}

class NoLeftValueException implements Exception {
  String message;
  NoLeftValueException(this.message);

  @override
  String toString() => 'NoLeftValueException: $message';
}

class InvalidOperatorException implements Exception {
  String message;
  InvalidOperatorException(this.message);

  @override
  String toString() => 'InvalidOperatorException: $message';
}

class AssertionException implements Exception {
  String message;
  AssertionException(this.message);

  @override
  String toString() => 'AssertionException: $message';
}

class UnexpectedTokenException implements Exception {
  String message;
  UnexpectedTokenException(this.message);

  @override
  String toString() => 'UnexpectedTokenException: $message';
}

class SyntaxException implements Exception {
  String message;
  SyntaxException(this.message);

  @override
  String toString() => 'SyntaxException: $message';
}

class JsonValueTypeException implements Exception {
  AST value;
  dynamic key;

  JsonValueTypeException(this.key, this.value);

  @override
  String toString() => 
      'JsonValueTypeException: Unsupported value type ${value.type}'
      'associated with key $key';
}

class NoSuchPropertyException implements Exception {
  String propertyName;
  String typeName;

  NoSuchPropertyException(this.propertyName, this.typeName);

  @override
  String toString() => 'NoSuchPropertyException: No such property $propertyName for $typeName';
}
class NoSuchMethodException implements Exception {
  String methodName;
  String typeName;

  NoSuchMethodException(this.methodName, this.typeName);

  @override
  String toString() => 'NoSuchMethodException: No such method $methodName for $typeName';
}