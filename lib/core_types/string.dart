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
        runtimeExpectArgs(binaryOpRight.functionCallArgs, [ASTType.AST_INT]);

        return IntNode()..intVal = left.stringValue
            .codeUnitAt(binaryOpRight.functionCallArgs[0].intVal);

    case 'compareTo':
        runtimeExpectArgs(
            binaryOpRight.functionCallArgs, [ASTType.AST_STRING]);


        return IntNode()..intVal = left.stringValue
              .compareTo(binaryOpRight.functionCallArgs[0].stringValue);

    case 'contains':
        runtimeExpectArgs(binaryOpRight.functionCallArgs,
            [ASTType.AST_STRING, ASTType.AST_INT]);

        return BoolNode()..boolVal = left.stringValue
            .contains(
              binaryOpRight.functionCallArgs[0].stringValue,
              binaryOpRight.functionCallArgs[1].intVal);

    case 'endsWith':
        runtimeExpectArgs(
            binaryOpRight.functionCallArgs, [ASTType.AST_STRING]);

        return BoolNode()..boolVal = left.stringValue
              .endsWith(binaryOpRight.functionCallArgs[0].stringValue);

    case 'indexOf':
        runtimeExpectArgs(binaryOpRight.functionCallArgs,
            [ASTType.AST_STRING, ASTType.AST_INT]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return IntNode()..intVal = left.stringValue
              .indexOf(args[0].stringValue, args[1].intVal);

    case 'lastIndexOf':
        runtimeExpectArgs(binaryOpRight.functionCallArgs,
            [ASTType.AST_STRING, ASTType.AST_INT]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return IntNode()
          ..intVal = left.stringValue
              .lastIndexOf(args[0].stringValue, args[1].intVal);

    case 'padLeft':
        runtimeExpectArgs(binaryOpRight.functionCallArgs,
            [ASTType.AST_INT, ASTType.AST_STRING]);
        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return left..stringValue = left.stringValue
            .padLeft(args[0].intVal, args[1].stringValue);

    case 'padRight':
        runtimeExpectArgs(binaryOpRight.functionCallArgs,
            [ASTType.AST_INT, ASTType.AST_STRING]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return left..stringValue = left.stringValue
            .padRight(args[0].intVal, args[1].stringValue);

    case 'replaceAll':
        runtimeExpectArgs(binaryOpRight.functionCallArgs,
            [ASTType.AST_STRING, ASTType.AST_STRING]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return left..stringValue = left.stringValue
            .replaceAll(args[0].stringValue, args[1].stringValue);

    case 'replaceFirst':
        runtimeExpectArgs(binaryOpRight.functionCallArgs,
            [ASTType.AST_STRING, ASTType.AST_STRING, ASTType.AST_INT]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return left..stringValue = left.stringValue.replaceFirst(
            args[0].stringValue, args[1].stringValue, args[2].intVal);

    case 'replaceRange':
        runtimeExpectArgs(binaryOpRight.functionCallArgs,
            [ASTType.AST_INT, ASTType.AST_INT, ASTType.AST_STRING]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return left..stringValue.replaceRange(args[0].intVal, args[1].intVal, args[2].stringValue);

    case 'split':
        runtimeExpectArgs(binaryOpRight.functionCallArgs, [ASTType.AST_STRING]);

        return ListNode()..listElements = left.stringValue
            .split(binaryOpRight.functionCallArgs[0].stringValue);

    case 'startsWith':
        runtimeExpectArgs(binaryOpRight.functionCallArgs,
            [ASTType.AST_STRING, ASTType.AST_INT]);

        final List<ASTNode> args = binaryOpRight.functionCallArgs;

        return BoolNode()..boolVal = left.stringValue
            .startsWith(args[0].stringValue, args[1].intVal);

    case 'substring':
        runtimeExpectArgs(binaryOpRight.functionCallArgs, [ASTType.AST_INT, ASTType.AST_INT]);

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
