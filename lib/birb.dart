import 'dart:convert';
import 'dart:io';

import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/lexer.dart';
import 'package:Birb/utils/parser.dart';
import 'package:Birb/utils/runtime.dart';

Future<void> main(List<String> arguments) async {
  /// If no file path is specified the birb shell will
  /// start up allowing developers to write programs directly from their terminal
  bool isInteractive = false;

  /// Runtime visitor
  Runtime runtime = initRuntime();

  Lexer lexer;

  Parser parser;

  /// Parsed program
  AST node;

  // No file path is specified, Initiate the birb shell
  if (arguments.isEmpty) {
    int lineNum = 0;
    isInteractive = true;

    print('<<<<< Birb Shell Initiated >>>>>');

    while (isInteractive) {
      lineNum++;
      stdout.write('$lineNum: ');
      var str = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));

      lexer = initLexer(str);
      parser = initParser(lexer);
      node = parse(parser);

      await visit(runtime, node);

      // Exit shell
      if (str == 'quit()') {
        isInteractive = false;
        break;
      }
    }

    print('<<<<< Birb Shell Terminated >>>>>');
    return;
  }

    lexer = initLexer(File(arguments[0]).readAsStringSync());
    parser = initParser(lexer);
    node = parse(parser);
    await visit(runtime, node);
}
