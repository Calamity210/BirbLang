import 'dart:convert';
import 'dart:io';

import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/lexer.dart';
import 'package:Birb/utils/parser.dart';
import 'package:Birb/utils/runtime.dart';

void main(List<String> arguments) {
  /// If no file path is specified the birb shell will
  /// start up allowing developers to write programs directly from their terminal
  bool isInteractive = false;

  /// Runtime visitor
  Runtime runtime = initRuntime();

  Lexer lexer;

  Parser parser;

  AST node;

  // No file path is specified, Initiate the birb shell
  if (arguments.isEmpty) {
    int lineNum = 0;
    String input = '';
    isInteractive = true;

    print('<<<<< Birb Shell Initiated >>>>>');

    while (isInteractive) {
      lineNum++;
      stdout.write('$lineNum: ');
      var str = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));

      // Compile program
      if (str == 'runBirb()') {
        lexer = initLexer(input);
        parser = initParser(lexer);
        node = parse(parser);

        visit(runtime, node);
        isInteractive = false;
      }

      // Exit shell
      if (str == 'quit()') {
        isInteractive = false;
        break;
      }
      input += str + '\n';
    }

    print('<<<<< Birb Shell Terminated >>>>>');
    return;
  }

  // File path was given

  lexer = initLexer(File(arguments[0]).readAsStringSync());
  parser = initParser(lexer);
  node = parse(parser);
  visit(runtime, node);
}
