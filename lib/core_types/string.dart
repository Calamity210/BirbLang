import 'dart:convert';
import 'dart:io';

import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/ast/ast_types.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `String`
ASTNode visitStringProperties(ASTNode node, ASTNode left) {
  final binaryOpRight = node.binaryOpRight;

  switch (binaryOpRight.variableName) {
    case 'codeUnits':
        return ListNode()..listElements = left.stringValue.codeUnits;

    case 'isEmpty':
        return BoolNode()..boolVal = left.stringValue.isEmpty;

    case 'isNotEmpty':
        return BoolNode()..boolVal = left.stringValue.isNotEmpty;

    case 'length':
        return IntNode()..intVal = left.stringValue.length;

    case 'mock':
        print(left.stringValue);

        return StringNode()..stringValue
        = stdin.readLineSync(encoding: Encoding.getByName('utf-8')).trim();

    case 'toBinary':
        return ListNode()..listElements
        = left.stringValue.codeUnits.map((e) => e.toRadixString(2)).toList();

    case 'toOct':
        return ListNode()..listElements = left.stringValue.codeUnits
            .map((e) => e.toRadixString(8))
            .toList();
    case 'toHex':
        return ListNode()..listElements = left.stringValue.codeUnits
            .map((e) => e.toRadixString(16))
            .toList();

    case 'runtimeType':
        return StringNode()..stringValue = left.stringValue.runtimeType.toString();

    default:
      throw NoSuchPropertyException(binaryOpRight.variableName, 'String');
  }
}

/// Visits methods for `String`
ASTNode visitStringMethods(ASTNode node, ASTNode left) {
  final binaryOpRight = node.binaryOpRight;

  switch (binaryOpRight.funcCallExpression.variableName) {
    case 'codeUnitAt':
        expectArgs(binaryOpRight.functionCallArgs, [IntNode]);

        return IntNode()..intVal = left.stringValue
            .codeUnitAt(binaryOpRight.functionCallArgs[0].intVal);

    case 'compareTo':
        expectArgs(binaryOpRight.functionCallArgs, [StringNode]);

        return IntNode()..intVal = left.stringValue
              .compareTo(binaryOpRight.functionCallArgs[0].stringValue);

    case 'contains':
        expectArgs(binaryOpRight.functionCallArgs, [StringNode, IntNode]);

        return BoolNode()..boolVal = left.stringValue
            .contains(
              binaryOpRight.functionCallArgs[0].stringValue,
              binaryOpRight.functionCallArgs[1].intVal);

    case 'endsWith':
        expectArgs(
            binaryOpRight.functionCallArgs, [StringNode]);

        return BoolNode()..boolVal = left.stringValue
              .endsWith(binaryOpRight.functionCallArgs[0].stringValue);

    case 'indexOf':
        expectArgs(binaryOpRight.functionCallArgs,
            [StringNode, IntNode]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return IntNode()..intVal = left.stringValue
              .indexOf(args[0].stringValue, args[1].intVal);

    case 'lastIndexOf':
        expectArgs(binaryOpRight.functionCallArgs,
            [StringNode, IntNode]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return IntNode()
          ..intVal = left.stringValue
              .lastIndexOf(args[0].stringValue, args[1].intVal);

    case 'padLeft':
        expectArgs(binaryOpRight.functionCallArgs,
            [IntNode, StringNode]);
        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return left..stringValue = left.stringValue
            .padLeft(args[0].intVal, args[1].stringValue);

    case 'padRight':
        expectArgs(binaryOpRight.functionCallArgs,
            [IntNode, StringNode]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return left..stringValue = left.stringValue
            .padRight(args[0].intVal, args[1].stringValue);

    case 'replaceAll':
        expectArgs(binaryOpRight.functionCallArgs,
            [StringNode, StringNode]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return left..stringValue = left.stringValue
            .replaceAll(args[0].stringValue, args[1].stringValue);

    case 'replaceFirst':
        expectArgs(binaryOpRight.functionCallArgs,
            [StringNode, StringNode, IntNode]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return left..stringValue = left.stringValue.replaceFirst(
            args[0].stringValue, args[1].stringValue, args[2].intVal);

    case 'replaceRange':
        expectArgs(binaryOpRight.functionCallArgs,
            [IntNode, IntNode, StringNode]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return left..stringValue.replaceRange(args[0].intVal, args[1].intVal, args[2].stringValue);

    case 'split':
        expectArgs(binaryOpRight.functionCallArgs, [StringNode]);

        return ListNode()..listElements = left.stringValue
            .split(binaryOpRight.functionCallArgs[0].stringValue);

    case 'startsWith':
        expectArgs(binaryOpRight.functionCallArgs,
            [StringNode, IntNode]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return BoolNode()..boolVal = left.stringValue
            .startsWith(args[0].stringValue, args[1].intVal);

    case 'substring':
        expectArgs(binaryOpRight.functionCallArgs, [IntNode, IntNode]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return StringNode()..stringValue = left.stringValue.substring(args[0].intVal, args[1].intVal);

    case 'toLowerCase':
        return left..stringValue = left.stringValue.toLowerCase();

    case 'toUpperCase':
        return left..stringValue = left.stringValue.toUpperCase();

    case 'trim':
        return left..stringValue = left.stringValue.trim();

    case 'trimLeft':
        return left..stringValue = left.stringValue.trimLeft();

    case 'trimRight':
        return left..stringValue = left.stringValue.trimRight();

    default:
      throw NoSuchMethodException(binaryOpRight.funcCallExpression.variableName, 'String');
  }
}
