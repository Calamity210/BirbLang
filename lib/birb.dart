import 'dart:convert';
import 'dart:io';

import 'package:Birb/ast/ast_node.dart';
import 'package:Birb/utils/exceptions.dart';
import 'package:Birb/lexer/lexer.dart';
import 'package:Birb/parser/parser.dart';
import 'package:Birb/runtime/runtime.dart';

Future<void> main(List<String> arguments) async {
  /// If no file path is specified the birb shell will
  /// start up allowing developers to write programs directly from their terminal
  final isInteractive = arguments.isEmpty;

  /// Runtime visitor
  final Runtime runtime = isInteractive ? initRuntime('') : initRuntime(arguments[0]);

  Lexer lexer;

  Parser parser;

  /// Parsed program
  ASTNode node;

  // No file path is specified, Initiate the birb shell
  if (isInteractive) {
    print('<<<<< Birb Shell Initiated >>>>>');

    while (true) {
      stdout.write('> ');
      String str = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));

      if (RegExp('{').allMatches(str).length >
          RegExp('}').allMatches(str).length) {
        while (RegExp('{').allMatches(str).length >
            RegExp('}').allMatches(str).length) {
          stdout.write('>> ');
          str += stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
        }
      }

      try {
        if (RegExp('{').allMatches(str).length <
            RegExp('}').allMatches(str).length) {
          throw const UnexpectedTokenException('Unexpected token `}`');
        }

        // Exit shell
        if (str == 'quit()') {
          break;
        }

        // Initialize and run program
        lexer = initLexer(str);
        parser = initParser(lexer);
        node = parse(parser);
        await visit(runtime, node);
      } catch (e) {
        if (e is! BirbException)
          rethrow;
        stderr.write(e);
      }
    }

    print('<<<<< Birb Shell Terminated >>>>>');
    return;
  }

  // Initialize and run program
  final String program = File(arguments[0]).readAsStringSync().trim();

  try {
    if (RegExp('{').allMatches(program).length !=
        RegExp('}').allMatches(program).length) {
      final int lParenCount = RegExp('{').allMatches(program).length;
      final Iterable<RegExpMatch> rParenMatches = RegExp('}').allMatches(program);
      final int rParenCount = rParenMatches.length;

      if (lParenCount > rParenCount) {
        throw UnexpectedTokenException(
            '[Line ${program.split('\n').length}] Expected `}`, but got EOF');
      } else if (lParenCount < rParenCount) {
        int parenCount = 0;
        rParenMatches.forEach((e) {
          parenCount += 1;
          if (parenCount > lParenCount) {
            throw UnexpectedTokenException(
                '[Line ${program.substring(0, e.start).split('\n').length}]');
          }
        });
      }
    }

    lexer = initLexer(program);
    parser = initParser(lexer);
    node = parse(parser);
    await visit(runtime, node);
  } catch (e) {
    if (e is! BirbException)
      rethrow;
    stderr.write(e);
  }
}
