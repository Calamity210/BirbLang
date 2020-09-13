import 'package:Birb/utils/ast/ast_node.dart';

abstract class BirbException implements Exception {}

/// Thrown when trying to access a non-existent function
class UndefinedFunctionException implements BirbException {
  const UndefinedFunctionException(this.message);

  final String message;

  @override
  String toString() => 'UndefinedFunctionException: $message';
}

/// Thrown when trying to access a non-existent variable
class UndefinedVariableException implements BirbException {
  const UndefinedVariableException(this.message);

  final String message;

  @override
  String toString() => 'UndefinedVariableException: $message';
}

/// Thrown when attempting to assign a value to a non-existent variable
class AssigningUndefinedVariableException implements BirbException {
  const AssigningUndefinedVariableException(this.message);

  final String message;

  @override
  String toString() => 'AssigningUndefinedVariableException: $message';
}

/// Thrown when attempting to redefine an existing variable.
/// Different from reassigning a value
class MultipleVariableDefinitionsException implements BirbException {
  const MultipleVariableDefinitionsException(this.message);

  final String message;

  @override
  String toString() => 'MultipleVariableDefinitionsException: $message';
}

/// Thrown when reassigning a value to a variable declared as `final`
class ReassigningFinalVariableException implements BirbException {
  const ReassigningFinalVariableException(this.message);

  final String message;

  @override
  String toString() => 'ReassigningFinalVariableException: $message';
}

/// Thrown when passing a wrong data type
class UnexpectedTypeException implements BirbException {
  const UnexpectedTypeException(this.message);

  final String message;

  @override
  String toString() => 'InvalidTypeException: $message';
}

/// Thrown when trying to access a non-existing map entry
class MapEntryNotFoundException implements BirbException {
  const MapEntryNotFoundException(this.message);

  final String message;

  @override
  String toString() => 'MapEntryNotFoundException: $message';
}

/// Thrown when passing an index not within range
class RangeException implements BirbException {
  const RangeException(this.message);

  final String message;

  @override
  String toString() => 'RangeException: $message';
}

/// Thrown when passing invalid arguments
class InvalidArgumentsException implements BirbException {
  const InvalidArgumentsException(this.message);

  final String message;

  @override
  String toString() => 'InvalidArgumentsException: $message';
}

/// Thrown when a case/clause is uncaught
class UncaughtStatementException implements BirbException {
  const UncaughtStatementException(this.message);

  final String message;

  @override
  String toString() => 'UncaughtStatementException: $message';
}

/// Thrown when no left value is provided
class NoLeftValueException implements BirbException {
  const NoLeftValueException(this.message);

  final String message;

  @override
  String toString() => 'NoLeftValueException: $message';
}

/// Thrown when attempting to use an invalid operator
class InvalidOperatorException implements BirbException {
  const InvalidOperatorException(this.message);

  final String message;

  @override
  String toString() => 'InvalidOperatorException: $message';
}

/// Thrown when an `assert` fails
class AssertionException implements BirbException {
  const AssertionException(this.message);

  final String message;

  @override
  String toString() => 'AssertionException: $message';
}

/// Thrown when an unexpected token is encountered by the lexer or parser
class UnexpectedTokenException implements BirbException {
  const UnexpectedTokenException(this.message);

  final String message;

  @override
  String toString() => 'UnexpectedTokenException: $message';
}

/// Thrown when the syntax is invalid
class SyntaxException implements BirbException {
  const SyntaxException(this.message);

  final String message;

  @override
  String toString() => 'SyntaxException: $message';
}

/// Thrown when an unsupported datatype is placed in a map
class JsonValueTypeException implements BirbException {
  const JsonValueTypeException(this.key, this.type);

  // Birb only supports String keys as of yet
  final String key;
  final ASTType type;


  @override
  String toString() =>
      'JsonValueTypeException: Unsupported value type `$type`s'
      'associated with key `$key`';
}

/// Thrown to indicate that a property was not found for the specified datatype
class NoSuchPropertyException implements BirbException {
  const NoSuchPropertyException(this.propertyName, this.typeName);

  final String propertyName;
  final String typeName;


  @override
  String toString() => 'NoSuchPropertyException: No such property `$propertyName` for `$typeName`';
}

/// Thrown to indicate that a method was not found for the specified datatype
class NoSuchMethodException implements BirbException {
  const NoSuchMethodException(this.methodName, this.typeName);

  final String methodName;
  final String typeName;


  @override
  String toString() => 'NoSuchMethodException: No such method `$methodName` for `$typeName`';
}
