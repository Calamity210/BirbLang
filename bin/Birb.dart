import 'dart:convert';
import 'dart:io';

import 'utils/AST.dart';
import 'utils/lexer.dart';
import 'utils/parser.dart';
import 'utils/runtime.dart';

bool isInteractive = false;

void main(List<String> arguments) {
  Runtime runtime = initRuntime();
  Lexer lexer;
  Parser parser;
  AST node;
  if (arguments.isEmpty) {
    isInteractive = true;
    print('<<<<< Birb Shell Initiated >>>>>');

    int lineNum = 0;
    String input = '';
    while (isInteractive) {
      lineNum++;
      stdout.write('$lineNum: ');
      var str = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
      if (str == 'runBirb') {
        lexer = initLexer(input);
        parser = initParser(lexer);
        node = parse(parser);
        visit(runtime, node);
        isInteractive = false;
      }

      if (str == 'quit();') {
        isInteractive = false;
        break;
      }

      input += str + '\n';
    }

    print('<<<<< Birb Shell Terminated >>>>>');
    return;
  }

  lexer = initLexer(File(arguments[0]).readAsStringSync());
  parser = initParser(lexer);
  node = parse(parser);
  visit(runtime, node);
}
