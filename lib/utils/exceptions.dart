import 'package:Birb/utils/ast/ast_node.dart';

/// Thrown when trying to access a non-existent function
class UndefinedFunctionException implements Exception {
  final String message;
  const UndefinedFunctionException(this.message);

  @override
  String toString() => 'UndefinedFunctionException: $message';
}

/// Thrown when trying to access a non-existent variable
class UndefinedVariableException implements Exception {
  final String message;
  const UndefinedVariableException(this.message);

  @override
  String toString() => 'UndefinedVariableException: $message';
}

/// Thrown when attempting to assign a value to a non-existent variable
class AssigningUndefinedVariableException implements Exception {
  final String message;
  const AssigningUndefinedVariableException(this.message);

  @override
  String toString() => 'AssigningUndefinedVariableException: $message';
}

/// Thrown when attempting to redefine an existing variable.
/// Different from reassigning a value
class MultipleVariableDefinitionsException implements Exception {
  final String message;
  const MultipleVariableDefinitionsException(this.message);

  @override
  String toString() => 'MultipleVariableDefinitionsException: $message';
}

/// Thrown when reassigning a value to a variable declared as `final`
class ReassigningFinalVariableException implements Exception {
  final String message;
  const ReassigningFinalVariableException(this.message);

  @override
  String toString() => 'ReassigningFinalVariableException: $message';
}

/// Thrown when passing a wrong data type
class UnexpectedTypeException implements Exception {
  final String message;
  const UnexpectedTypeException(this.message);

  @override
  String toString() => 'InvalidTypeException: $message';
}

/// Thrown when trying to access a non-existing map entry
class MapEntryNotFoundException implements Exception {
  final String message;
  const MapEntryNotFoundException(this.message);

  @override
  String toString() => 'MapEntryNotFoundException: $message';
}

/// Thrown when passing an index not within range
class RangeException implements Exception {
  final String message;
  const RangeException(this.message);

  @override
  String toString() => 'RangeException: $message';
}

/// Thrown when passing invalid arguments
class InvalidArgumentsException implements Exception {
  final String message;
  const InvalidArgumentsException(this.message);

  @override
  String toString() => 'InvalidArgumentsException: $message';
}

/// Thrown when a case/clause is uncaught
class UncaughtStatementException implements Exception {
  final String message;
  const UncaughtStatementException(this.message);

  @override
  String toString() => 'UncaughtStatementException: $message';
}

/// Thrown when no left value is provided
class NoLeftValueException implements Exception {
  final String message;
  const NoLeftValueException(this.message);

  @override
  String toString() => 'NoLeftValueException: $message';
}

/// Thrown when attempting to use an invalid operator
class InvalidOperatorException implements Exception {
  final String message;
  const InvalidOperatorException(this.message);

  @override
  String toString() => 'InvalidOperatorException: $message';
}

/// Thrown when an `assert` fails
class AssertionException implements Exception {
  final String message;
  const AssertionException(this.message);

  @override
  String toString() => 'AssertionException: $message';
}

/// Thrown when an unexpected token is encountered by the lexer or parser
class UnexpectedTokenException implements Exception {
  final String message;
  const UnexpectedTokenException(this.message);

  @override
  String toString() => 'UnexpectedTokenException: $message';
}

/// Thrown when the syntax is invalid
class SyntaxException implements Exception {
  final String message;
  const SyntaxException(this.message);

  @override
  String toString() => 'SyntaxException: $message';
}

/// Thrown when an unsupported datatype is placed in a map
class JsonValueTypeException implements Exception {
  // Birb only supports String keys as of yet
  final String key;
  final ASTType type;

  const JsonValueTypeException(this.key, this.type);

  @override
  String toString() =>
      'JsonValueTypeException: Unsupported value type `$type`s'
      'associated with key `$key`';
}

/// Thrown to indicate that a property was not found for the specified datatype
class NoSuchPropertyException implements Exception {
  final String propertyName;
  final String typeName;

  const NoSuchPropertyException(this.propertyName, this.typeName);

  @override
  String toString() => 'NoSuchPropertyException: No such property `$propertyName` for `$typeName`';
}

/// Thrown to indicate that a method was not found for the specified datatype
class NoSuchMethodException implements Exception {
  final String methodName;
  final String typeName;

  const NoSuchMethodException(this.methodName, this.typeName);

  @override
  String toString() => 'NoSuchMethodException: No such method `$methodName` for `$typeName`';
}
