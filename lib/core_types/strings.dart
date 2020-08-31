import 'dart:convert';
import 'dart:io';

import 'package:Birb/runtime/runtime.dart';
import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/exceptions.dart';

/// Visits properties for `String`
AST visitStringProperties(AST node, AST left) {
  switch (node.binaryOpRight.variableName) {
    case 'codeUnits':
      {
        /// Returns an unmodifiable list of the UTF-16 code units of this string.
        AST astList = initAST(ASTType.AST_LIST)
          ..listElements = left.stringValue.codeUnits;
        return astList;
      }

    case 'isEmpty':
      {
        /// Returns true if this string is empty.
        AST astBool = initAST(ASTType.AST_BOOL)
          ..boolValue = left.stringValue.isEmpty;
        return astBool;
      }

    case 'isNotEmpty':
      {
        /// Returns true if this string is not empty.
        AST astBool = initAST(ASTType.AST_BOOL)
          ..boolValue = left.stringValue.isNotEmpty;
        return astBool;
      }

    case 'mock':
      {
        print(left.stringValue);
        AST astString = initAST(ASTType.AST_STRING)
          ..stringValue =
          stdin.readLineSync(encoding: Encoding.getByName('utf-8')).trim();

        return astString;
      }

    case 'length':
      {
        /// The length of the string.
        ASR intAST = initAST(ASTType.AST_INT)..intVal = left.stringValue.length;

        return intAST;
      }
    case 'toBinary':
      {
        AST astList = initAST(ASTType.AST_LIST)
          ..listElements = left.stringValue.codeUnits
              .map((e) => e.toRadixString(2))
              .toList();

        return astList;
      }
    case 'toOct':
      {
        AST astList = initAST(ASTType.AST_LIST)
          ..listElements = left.stringValue.codeUnits
              .map((e) => e.toRadixString(8))
              .toList();

        return astList;
      }
    case 'toHex':
      {
        AST astList = initAST(ASTType.AST_LIST)
          ..listElements = left.stringValue.codeUnits
              .map((e) => e.toRadixString(16))
              .toList();

        return astList;
      }

    case 'toDec':
      {
        AST astList = initAST(ASTType.AST_LIST)
          ..listElements = left.stringValue.codeUnits;
        return astList;
      }

    default:
      throw NoSuchPropertyException(node.binaryOpRight.variableName, 'String');
  }
}

/// Visits methods for `String`
AST visitStringMethods(AST node, AST left) {
  switch (node.binaryOpRight.funcCallExpression.variableName) {
    case 'codeUnitAt':
      {
        /// Returns the 16-bit UTF-16 code unit at the given index
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs, [ASTType.AST_INT]);

        AST ast = initAST(ASTType.AST_INT)
          ..intVal = left.stringValue
              .codeUnitAt(node.binaryOpRight.funcCallArgs[0].intVal);

        return ast;
      }

    case 'compareTo':
      {
        /// Compares this string to other
        runtimeExpectArgs(
            node.binaryOpRight.funcCallArgs, [ASTType.AST_STRING]);

        AST ast = initAST(ASTType.AST_INT)
          ..intVal = left.stringValue
              .compareTo(node.binaryOpRight.funcCallArgs[0].stringValue);

        return ast;
      }

    case 'contains':
      {
        /// Returns true if this string contains a match of other
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_STRING, ASTType.AST_INT]);

        AST ast = initAST(ASTType.AST_BOOL)
          ..boolValue = left.stringValue.contains(
              node.binaryOpRight.funcCallArgs[0].stringValue,
              node.binaryOpRight.funcCallArgs[1].intVal);

        return ast;
      }

    case 'endsWith':
      {
        /// Returns true if this string ends with other
        runtimeExpectArgs(
            node.binaryOpRight.funcCallArgs, [ASTType.AST_STRING]);

        AST ast = initAST(ASTType.AST_BOOL)
          ..boolValue = left.stringValue
              .endsWith(node.binaryOpRight.funcCallArgs[0].stringValue);

        return ast;
      }

    case 'indexOf':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_STRING, ASTType.AST_INT]);

        List args = node.binaryOpRight.funcCallArgs;
        AST ast = initAST(ASTType.AST_INT)
          ..intVal =
          left.stringValue.indexOf(args[0].stringValue, args[1].intVal);

        return ast;
      }

    case 'lastIndexOf':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_STRING, ASTType.AST_INT]);

        List args = node.binaryOpRight.funcCallArgs;
        AST ast = initAST(ASTType.AST_INT)
          ..intVal =
          left.stringValue.lastIndexOf(args[0].stringValue, args[1].intVal);

        return ast;
      }

    case 'padLeft':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_STRING]);
        List args = node.binaryOpRight.funcCallArgs;

        left.stringValue =
            left.stringValue.padLeft(args[0].intVal, args[1].stringValue);

        return left;
      }
    case 'padRight':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_STRING]);
        List args = node.binaryOpRight.funcCallArgs;

        left.stringValue =
            left.stringValue.padRight(args[0].intVal, args[1].stringValue);

        return left;
      }

    case 'replaceAll':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_STRING, ASTType.AST_STRING]);

        List args = node.binaryOpRight.funcCallArgs;

        left.stringValue = left.stringValue
            .replaceAll(args[0].stringValue, args[1].stringValue);

        return left;
      }

    case 'replaceFirst':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_STRING, ASTType.AST_STRING, ASTType.AST_INT]);

        List args = node.binaryOpRight.funcCallArgs;

        left.stringValue = left.stringValue.replaceFirst(
            args[0].stringValue, args[1].stringValue, args[2].intVal);

        return left;
      }

    case 'replaceRange':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_INT, ASTType.AST_STRING]);

        List args = node.binaryOpRight.funcCallArgs;
        left.stringValue
            .replaceRange(args[0].intVal, args[1].intVal, args[2].stringValue);

        return left;
      }

    case 'split':
      {
        runtimeExpectArgs(
            node.binaryOpRight.funcCallArgs, [ASTType.AST_STRING]);

        AST ast = initAST(ASTType.AST_LIST);
        ast.listElements = left.stringValue
            .split(node.binaryOpRight.funcCallArgs[0].stringValue);

        return ast;
      }

    case 'startsWith':
      {
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_STRING, ASTType.AST_INT]);

        List args = node.binaryOpRight.funcCallArgs;

        AST ast = initAST(ASTType.AST_BOOL);
        ast.boolValue =
            left.stringValue.startsWith(args[0].stringValue, args[1].intVal);

        return ast;
      }

    case 'substring':
      {
        /// Returns the substring of this string that extends from startIndex, inclusive, to endIndex, exclusive.
        runtimeExpectArgs(node.binaryOpRight.funcCallArgs,
            [ASTType.AST_INT, ASTType.AST_INT]);

        List args = node.binaryOpRight.funcCallArgs;

        AST ast = initAST(ASTType.AST_STRING);
        ast.stringValue =
            left.stringValue.substring(args[0].intVal, args[1].intVal);

        return ast;
      }

    case 'toLowerCase':
      {
        /// Converts all characters in this string to lower case case. 
        left.stringValue = left.stringValue.toLowerCase();

        return left;
      }

    case 'toUpperCase':
      {
        /// Converts all characters in this string to upper case. 
        left.stringValue = left.stringValue.toUpperCase();

        return left;
      }

    case 'trim':
      {
        /// Returns the string without any leading and trailing whitespace. 
        left.stringValue = left.stringValue.trim();

        return left;
      }

    case 'trimLeft':
      {
        /// Returns the string without any leading whitespace. 
        left.stringValue = left.stringValue.trimLeft();
        return left;
      }

    case 'trimRight':
      {
        /// Returns the string without any trailing whitespace.
        left.stringValue = left.stringValue.trimRight();
        return left;
      }

    default:
      throw NoSuchMethodException(node.binaryOpRight.funcCallExpression.variableName, 'String');
  }
}
